class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_event, only: [:show, :edit, :update, :destroy]
  before_action :check_owner, only: [:edit, :update, :destroy]

  def index
    if user_signed_in?
      # Gérer les filtres pour users loggués
      case params[:filter]
      when 'my'
        # Mes événements seulement - afficher toutes les occurrences de mes events
        @all_occurrences = EventOccurrence.joins(:event)
                                          .where(events: { user: current_user })
                                          .upcoming.active
                                          .includes(:event, :venue, event: :principal_teacher)
                                          .order(:start_date, :start_time)
      else
        # Tous les événements - afficher toutes les occurrences publiques
        @all_occurrences = EventOccurrence.upcoming.active
                                          .includes(:event, :venue, event: :principal_teacher)
                                          .order(:start_date, :start_time)
      end
    else
      # Pour les visiteurs : toutes les occurrences publiques
      @all_occurrences = EventOccurrence.upcoming.active
                                        .includes(:event, :venue, event: :principal_teacher)
                                        .order(:start_date, :start_time)
    end
    
    # Appliquer la recherche si présente
    if params[:search].present?
      @all_occurrences = @all_occurrences.search_by_keywords(params[:search])
    end
  end

  def show
    @upcoming_occurrences = @event.upcoming_occurrences(10)
    @past_occurrences = @event.event_occurrences
                              .past
                              .active
                              .includes(:venue)
                              .order(start_date: :desc, start_time: :desc)
                              .limit(5)
  end

  def new
    @event = current_user.events.build
    @event.price_normal = 15.0
    @event.price_reduced = 12.0
    @event.currency = 'EUR'

    # Pour le formulaire
    @venues = Venue.order(:name, :city, :country)
    @teachers = Teacher.includes(:user).order(:first_name, :last_name)
  end

  def create
    if params[:event][:is_recurring] == '1'
      create_recurring_event
    else
      create_single_event
    end
  end

  def edit
    @venues = current_user.venues.order(:name)
    @teachers = Teacher.includes(:user).order(:first_name, :last_name)
  end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: 'Événement modifié avec succès.', status: :see_other
    else
      @venues = current_user.venues.order(:name)
      @teachers = Teacher.includes(:user).order(:first_name, :last_name)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.update(status: 'cancelled')
    @event.event_occurrences.update_all(status: 'cancelled')
    redirect_to events_path, notice: 'Événement annulé avec succès.', status: :see_other
  end

  # === ACTIONS AJAX POUR LA RÉCURRENCE ===

  def preview_recurrence
    recurrence_params = params.require(:recurrence).permit(
      :frequency, :interval, :start_time, :end_time, :end_date
    )

    occurrence_params = params.require(:occurrence).permit(:start_date)
    start_date = parse_date(occurrence_params[:start_date])

    preview = RecurrenceService.preview_occurrences(start_date, recurrence_params)

    render json: {
      success: true,
      preview: preview
    }
  rescue => e
    render json: {
      success: false,
      error: e.message
    }
  end


  private

  def set_event
    @event = Event.find(params[:id])
  end

  def check_owner
    unless @event.user == current_user
      redirect_to events_path, alert: 'Accès non autorisé.'
    end
  end

  def event_params
    params.require(:event).permit(
      :title, :description, :price_normal, :price_reduced, :currency,
      :principal_teacher_id, :is_online, :online_url, :practice_id, :status, :source_url, :teacher_url_id
    )
  end

  def create_single_event
    @event = current_user.events.build(event_params)
    @event.is_recurring = false

    occurrence_params = params.require(:occurrence).permit(
      :venue_id, :start_date, :end_date, :start_time, :end_time
    )

    # Validation du venue_id
    if occurrence_params[:venue_id].blank?
      @event.errors.add(:base, "Vous devez sélectionner un lieu")
      @venues = Venue.order(:name, :city, :country)
      @teachers = Teacher.includes(:user).order(:first_name, :last_name)
      render :new, status: :unprocessable_entity
      return
    end

    if @event.save
      begin
        venue = Venue.find(occurrence_params[:venue_id])
        occurrence = @event.create_single_occurrence!(
          venue,
          parse_date(occurrence_params[:start_date]),
          occurrence_params[:start_time],
          occurrence_params[:end_time],
          occurrence_params[:end_date].present? ? parse_date(occurrence_params[:end_date]) : nil
        )

        redirect_to @event, notice: '✅ Événement créé avec succès !', status: :see_other
      rescue ActiveRecord::RecordNotFound
        @event.errors.add(:base, "Le lieu sélectionné n'existe pas")
        @venues = Venue.order(:name, :city, :country)
        @teachers = Teacher.includes(:user).order(:first_name, :last_name)
        render :new, status: :unprocessable_entity
      end
    else
      @venues = Venue.order(:name, :city, :country)
      @teachers = Teacher.includes(:user).order(:first_name, :last_names)
      render :new, status: :unprocessable_entity
    end
  end

  def create_recurring_event
    event_params_full = event_params

    occurrence_params = params.require(:occurrence).permit(
      :venue_id, :start_date, :start_time, :end_time
    )

    # Validation du venue_id
    if occurrence_params[:venue_id].blank?
      @event = current_user.events.build(event_params_full)
      @event.errors.add(:base, "Vous devez sélectionner un lieu")
      @venues = Venue.order(:name, :city, :country)
      @teachers = Teacher.includes(:user).order(:first_name, :last_name)
      render :new, status: :unprocessable_entity
      return
    end

    recurrence_params = params.require(:recurrence).permit(
      :frequency, :interval, :end_date, :start_time, :end_time,
      :max_occurrences
    )

    @event = RecurrenceService.create_recurring_event(
      current_user,
      event_params_full,
      occurrence_params,
      recurrence_params
    )

    if @event && @event.persisted?
      redirect_to @event, notice: "✅ Événement récurrent créé avec #{@event.occurrences_count} occurrences.", status: :see_other
    else
      errors = @event&.errors&.full_messages || []
      service = RecurrenceService.new(@event || Event.new)
      errors += service.errors

      flash.now[:alert] = "Erreur lors de la création: #{errors.join(', ')}" if errors.any?

      @event ||= current_user.events.build(event_params_full)
      @venues = Venue.order(:name, :city, :country)
      @teachers = Teacher.includes(:user).order(:first_name, :last_name)
      render :new, status: :unprocessable_entity
    end
  end
end

  # Parse une date qui peut être soit une String, soit déjà une Date
  def parse_date(date_value)
    return nil if date_value.blank?
    return date_value if date_value.is_a?(Date)
    Date.parse(date_value.to_s)
  end

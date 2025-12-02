class EventOccurrencesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_event_occurrence
  before_action :authorize_event_occurrence!
  
  def edit
    @event = @occurrence.event
    @venues = Venue.all
    @teachers = Teacher.all
  end
  
  def update
    @event = @occurrence.event
    scope = params.dig(:event_occurrence, :update_scope).presence || 'this_only'
    
    case scope
    when 'this_only'
      update_this_only
    when 'this_and_following'
      update_this_and_following
    when 'all'
      update_all_occurrences
    else
      redirect_to edit_event_occurrence_path(@occurrence), alert: "Veuillez choisir une option de modification."
    end
  end
  
  def destroy
    @event = @occurrence.event
    scope = params[:delete_scope].presence || 'this_only'
    
    case scope
    when 'this_only'
      destroy_this_only
    when 'this_and_following'
      destroy_this_and_following
    when 'all'
      destroy_all_occurrences
    else
      redirect_to @event, alert: "Veuillez choisir une option de suppression."
    end
  end
  
  private
  
  def set_event_occurrence
    @occurrence = EventOccurrence.find(params[:id])
  end
  
  def authorize_event_occurrence!
    unless current_user.admin? || @occurrence.event.user == current_user
      redirect_to root_path, alert: "Vous n'êtes pas autorisé à modifier cette occurrence."
    end
  end

  def update_this_only
    override_attributes = {
      override_title: occurrence_params[:title],
      override_description: occurrence_params[:description],
      override_price_normal: occurrence_params[:price_normal],
      override_price_reduced: occurrence_params[:price_reduced],
      override_currency: occurrence_params[:currency],
      override_source_url: normalize_url(occurrence_params[:source_url]),
      start_date: occurrence_params[:start_date],
      end_date: occurrence_params[:end_date],
      start_time: parse_time(occurrence_params[:start_time]),
      end_time: parse_time(occurrence_params[:end_time]),
      is_override: true
    }

    ActiveRecord::Base.transaction do
      @occurrence.update!(override_attributes)

      if occurrence_params[:venue_id].present? && @occurrence.venue_id != occurrence_params[:venue_id]
        @occurrence.update_column(:venue_id, occurrence_params[:venue_id])
      end

      if occurrence_params[:teacher_ids].present?
        teacher_ids = occurrence_params[:teacher_ids].reject(&:blank?)
        @occurrence.teachers = Teacher.where(id: teacher_ids)
      end
    end

    redirect_to @occurrence.event, notice: "✅ Cette occurrence a été modifiée avec succès.", status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    @venues = Venue.all
    @teachers = Teacher.all
    flash.now[:alert] = "Erreur lors de la modification : #{e.message}"
    render :edit, status: :unprocessable_entity
  end

  def update_this_and_following
    following_occurrences = @occurrence.event.event_occurrences
                                       .where('start_date >= ?', @occurrence.start_date)
    
    override_attributes = {
      override_title: occurrence_params[:title],
      override_description: occurrence_params[:description],
      override_price_normal: occurrence_params[:price_normal],
      override_price_reduced: occurrence_params[:price_reduced],
      override_currency: occurrence_params[:currency],
      override_source_url: normalize_url(occurrence_params[:source_url]),
      start_time: parse_time(occurrence_params[:start_time]),
      end_time: parse_time(occurrence_params[:end_time]),
      is_override: true
    }

    ActiveRecord::Base.transaction do
      following_occurrences.each do |occ|
        occ.update!(override_attributes)

        if occurrence_params[:venue_id].present? && occ.venue_id != occurrence_params[:venue_id]
          occ.update_column(:venue_id, occurrence_params[:venue_id])
        end

        if occurrence_params[:teacher_ids].present?
          teacher_ids = occurrence_params[:teacher_ids].reject(&:blank?)
          occ.teachers = Teacher.where(id: teacher_ids)
        end
      end
    end

    redirect_to @occurrence.event, notice: "✅ Cette occurrence et les suivantes ont été modifiées avec succès.", status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    @venues = Venue.all
    @teachers = Teacher.all
    flash.now[:alert] = "Erreur lors de la modification : #{e.message}"
    render :edit, status: :unprocessable_entity
  end

  def update_all_occurrences
    event_attributes = {
      title: occurrence_params[:title],
      description: occurrence_params[:description],
      price_normal: occurrence_params[:price_normal],
      price_reduced: occurrence_params[:price_reduced],
      currency: occurrence_params[:currency],
      source_url: normalize_url(occurrence_params[:source_url]),
      principal_teacher_id: occurrence_params[:teacher_ids]&.reject(&:blank?)&.first
    }

    ActiveRecord::Base.transaction do
      @occurrence.event.update!(event_attributes)

      @occurrence.event.event_occurrences.find_each do |occ|
        occ.update!(
          override_title: nil,
          override_description: nil,
          override_price_normal: nil,
          override_price_reduced: nil,
          override_currency: nil,
          override_source_url: nil,
          is_override: false,
          start_time: parse_time(occurrence_params[:start_time]),
          end_time: parse_time(occurrence_params[:end_time])
        )

        if occurrence_params[:venue_id].present? && occ.venue_id != occurrence_params[:venue_id]
          occ.update_column(:venue_id, occurrence_params[:venue_id])
        end

        if occurrence_params[:teacher_ids].present?
          teacher_ids = occurrence_params[:teacher_ids].reject(&:blank?)
          occ.teachers = Teacher.where(id: teacher_ids)
        end
      end
    end

    redirect_to @occurrence.event, notice: "✅ Tous les événements ont été modifiés avec succès.", status: :see_other
  rescue ActiveRecord::RecordInvalid => e
    @venues = Venue.all
    @teachers = Teacher.all
    flash.now[:alert] = "Erreur lors de la modification : #{e.message}"
    render :edit, status: :unprocessable_entity
  end
  
  # === MÉTHODES DE SUPPRESSION ===
  
  def destroy_this_only
    @occurrence.update(status: 'cancelled')
    redirect_to @event, notice: "✅ L'occurrence a été supprimée.", status: :see_other
  end
  
  def destroy_this_and_following
    following_occurrences = @occurrence.event.event_occurrences
                                       .where('start_date >= ?', @occurrence.start_date)
    
    count = following_occurrences.update_all(status: 'cancelled')
    redirect_to @event, notice: "✅ #{count} occurrence(s) supprimée(s).", status: :see_other
  end
  
  def destroy_all_occurrences
    # Supprimer toutes les occurrences ET marquer l'Event comme cancelled
    count = @occurrence.event.event_occurrences.update_all(status: 'cancelled')
    @occurrence.event.update(status: 'cancelled')
    
    redirect_to events_path, notice: "✅ L'événement et toutes ses occurrences (#{count}) ont été supprimés.", status: :see_other
  end
  
  # Parse une heure au format "HH:MM" vers un objet Time
  def parse_time(time_string)
    return nil if time_string.blank?
    
    # Si c'est déjà un objet Time, le retourner tel quel
    return time_string if time_string.is_a?(Time)
    
    # Parser "HH:MM" vers Time
    Time.zone.parse("2000-01-01 #{time_string}")
  end
  
  # Normalise une URL (ajoute https:// si besoin)
  def normalize_url(url)
    return nil if url.blank?
    url = url.strip
    return url if url.match?(/^https?:\/\//i)
    "https://#{url}"
  end
  
  def occurrence_params
    params.require(:event_occurrence).permit(
      :title,
      :description,
      :price_normal,
      :price_reduced,
      :currency,
      :source_url,
      :venue_id,
      :start_date,
      :end_date,
      :start_time,
      :end_time,
      :update_scope,
      teacher_ids: []
    )
  end
end

class RecurrenceService
  attr_reader :event, :errors

  def initialize(event)
    @event = event
    @errors = []
  end

  # === CRÉATION D'ÉVÉNEMENTS RÉCURRENTS ===
  
  # Crée un événement récurrent avec ses occurrences
  def self.create_recurring_event(user, event_params, occurrence_params, recurrence_params)
    service = new(Event.new)
    service.create_recurring_event(user, event_params, occurrence_params, recurrence_params)
  end
  
  def create_recurring_event(user, event_params, occurrence_params, recurrence_params)
    Event.transaction do
      # 1. Créer l'Event master
      @event = Event.new(event_params.merge(
        user: user,
        is_recurring: true,
        recurrence_rule: build_recurrence_rule(recurrence_params),
        recurrence_end_date: recurrence_params[:end_date]
      ))
      
      unless @event.save
        @errors = @event.errors.full_messages
        raise ActiveRecord::Rollback
      end
      
      # 2. Générer les occurrences
      venue = Venue.find(occurrence_params[:venue_id])
      start_date = Date.parse(occurrence_params[:start_date])
      
      occurrences_created = generate_occurrences_for_event(venue, start_date, recurrence_params)
      
      if occurrences_created == 0
        @errors << "Aucune occurrence n'a pu être créée"
        raise ActiveRecord::Rollback
      end
      
      @event
    end
  rescue => e
    @errors << e.message
    nil
  end
  
  # === GÉNÉRATION D'OCCURRENCES ===
  
  def generate_occurrences_for_event(venue, start_date, recurrence_params)
    return 0 unless event.persisted?
    
    current_date = start_date
    end_date = recurrence_params[:end_date].is_a?(String) ? Date.parse(recurrence_params[:end_date]) : recurrence_params[:end_date]
    recurrence_id = SecureRandom.uuid
    count = 0
    max_occurrences = recurrence_params[:max_occurrences] || 52 # Limite de sécurité
    
    while current_date <= end_date && count < max_occurrences
      # Créer l'occurrence (pour les récurrents: start_date = end_date)
      occurrence = event.event_occurrences.build(
        venue: venue,
        start_date: current_date,
        end_date: current_date,
        start_time: recurrence_params[:start_time] || '20:00',
        end_time: recurrence_params[:end_time] || '23:00',
        recurrence_id: recurrence_id
      )
      
      if occurrence.save
        count += 1
      else
        Rails.logger.warn "Impossible de créer l'occurrence pour #{current_date}: #{occurrence.errors.full_messages.join(', ')}"
      end
      
      # Calculer la prochaine date
      current_date = calculate_next_date(current_date, recurrence_params)
      
      # Sécurité pour éviter les boucles infinies
      break if current_date > end_date + 2.years
    end
    
    count
  end
  
  # === UTILITAIRES DE RÉCURRENCE ===
  
  # Construit la règle de récurrence JSON
  def build_recurrence_rule(params)
    {
      frequency: params[:frequency], # 'daily', 'weekly', 'monthly'
      interval: params[:interval].to_i, # chaque X jours/semaines/mois
      start_time: params[:start_time],
      end_time: params[:end_time],
      created_at: Time.current.iso8601
    }.compact.to_json
  end
  
  # Calcule la prochaine date selon les règles
  def calculate_next_date(current_date, params)
    frequency = params[:frequency]
    interval = params[:interval].to_i
    
    case frequency
    when 'daily'
      current_date + interval.days
    when 'weekly'
      current_date + interval.weeks
    when 'monthly'
      current_date + interval.months
    else
      current_date + 1.week # fallback
    end
  end
  
  # === PRÉVISUALISATION ===
  
  # Génère un aperçu des occurrences qui seraient créées
  def self.preview_occurrences(start_date, recurrence_params)
    service = new(Event.new)
    service.preview_occurrences(start_date, recurrence_params)
  end
  
  def preview_occurrences(start_date, recurrence_params)
    occurrences = []
    current_date = start_date.is_a?(String) ? Date.parse(start_date) : start_date
    end_date = recurrence_params[:end_date].is_a?(String) ? Date.parse(recurrence_params[:end_date]) : recurrence_params[:end_date]
    count = 0
    max_preview = 20 # Limite pour la prévisualisation
    
    while current_date <= end_date && count < max_preview
      occurrences << {
        date: current_date,
        formatted_date: current_date.strftime('%A %d %B %Y'),
        start_time: recurrence_params[:start_time],
        end_time: recurrence_params[:end_time]
      }
      
      current_date = calculate_next_date(current_date, recurrence_params)
      count += 1
    end
    
    {
      occurrences: occurrences,
      total_estimated: estimate_total_occurrences(start_date, end_date, recurrence_params),
      truncated: count >= max_preview
    }
  end
  
  private
  
  def estimate_total_occurrences(start_date, end_date, params)
    return 0 if start_date > end_date
    
    case params[:frequency]
    when 'daily'
      days_diff = (end_date - start_date).to_i + 1
      (days_diff / params[:interval].to_i).floor
    when 'weekly'
      weeks_diff = ((end_date - start_date) / 7).floor + 1
      (weeks_diff / params[:interval].to_i).floor
    when 'monthly'
      months_diff = ((end_date.year - start_date.year) * 12 + end_date.month - start_date.month)
      (months_diff / params[:interval].to_i).floor + 1
    else
      0
    end
  end
end

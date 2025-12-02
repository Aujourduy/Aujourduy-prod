class EventImportService
  attr_reader :errors, :imported_events, :skipped_events, :admin_user

  def initialize
    @admin_user = User.find_by(email: 'bonjour.duy@gmail.com')
    unless @admin_user
      raise "User admin 'bonjour.duy@gmail.com' introuvable"
    end

    @errors = []
    @imported_events = []
    @skipped_events = []
  end

  # Importer un ou plusieurs événements depuis un JSON
  def import_from_json(json_data)
    data = parse_json(json_data)
    return false unless data

    # Si c'est un tableau, importer chaque événement
    if data.is_a?(Array)
      data.each { |event_data| import_single_event(event_data) }
    else
      import_single_event(data)
    end

    @errors.empty?
  end

  private

  def parse_json(json_data)
    if json_data.is_a?(String)
      JSON.parse(json_data)
    elsif json_data.is_a?(Hash) || json_data.is_a?(Array)
      json_data
    else
      @errors << "Format JSON invalide"
      nil
    end
  rescue JSON::ParserError => e
    @errors << "Erreur de parsing JSON: #{e.message}"
    nil
  end

  def import_single_event(data)
    # Validation des données
    unless valid_event_data?(data)
      @skipped_events << { data: data, reason: "Données invalides" }
      return
    end

    ActiveRecord::Base.transaction do
      # 1. Trouver le teacher (pas de création)
      teacher = find_teacher(data['teacher'])
      unless teacher
        return
      end

      # 2. Trouver ou créer le venue (sauf si événement 100% en ligne)
      venue = nil
      if data['venue'].present?
        venue = find_or_create_venue(data['venue'])
        unless venue
          return
        end
      end

      # 3. Trouver la practice (pas de création)
      practice = find_practice(data['event']['practice'])
      unless practice
        return
      end

      # 4. Créer l'événement
      event = create_event(data, teacher, practice)
      unless event.persisted?
        @errors << "Événement non créé: #{event.errors.full_messages.join(', ')}"
        @skipped_events << { data: data, reason: event.errors.full_messages.join(', ') }
        raise ActiveRecord::Rollback
      end

      # 5. Créer l'occurrence
      occurrence = create_occurrence(event, venue, data['event'])
      unless occurrence.persisted?
        @errors << "Occurrence non créée: #{occurrence.errors.full_messages.join(', ')}"
        @skipped_events << { data: data, reason: occurrence.errors.full_messages.join(', ') }
        raise ActiveRecord::Rollback
      end

      @imported_events << event
    end
  rescue => e
    @errors << "Erreur lors de l'import: #{e.message}"
    @skipped_events << { data: data, reason: e.message }
  end

  def valid_event_data?(data)
    return false unless data.is_a?(Hash)
    return false unless data['teacher'].present?
    return false unless data['event'].present?

    event_data = data['event']
    # Champs minimum requis (horaires et prix sont optionnels car parfois il faut contacter le pro)
    required_fields = %w[title description practice source_url start_date]

    required_fields.all? { |field| event_data[field].present? }
  end

  def find_teacher(teacher_data)
    return nil unless teacher_data.present?

    # Chercher un teacher existant avec le même nom
    teacher = Teacher.find_by(
      first_name: teacher_data['first_name'],
      last_name: teacher_data['last_name']
    )

    # Si non trouvé, retourner nil avec message d'erreur
    unless teacher
      @errors << "❌ Teacher '#{teacher_data['first_name']} #{teacher_data['last_name']}' n'existe pas. Veuillez créer ce teacher avant d'importer."
      @skipped_events << { 
        data: teacher_data, 
        reason: "Teacher '#{teacher_data['first_name']} #{teacher_data['last_name']}' inexistant" 
      }
      return nil
    end

    teacher
  end

  def find_practice(practice_name)
    return nil unless practice_name.present?

    # Normaliser le nom
    normalized_name = practice_name.strip

    # Chercher une practice existante (insensible à la casse)
    practice = Practice.where('LOWER(name) = ?', normalized_name.downcase).first

    # Si non trouvée, retourner nil avec message d'erreur
    unless practice
      @errors << "❌ Practice '#{practice_name}' n'existe pas. Veuillez créer cette practice avant d'importer."
      @skipped_events << { 
        data: { practice: practice_name }, 
        reason: "Practice '#{practice_name}' inexistante" 
      }
      return nil
    end

    practice
  end

  def find_or_create_venue(venue_data)
    return nil unless venue_data.present?

    # Chercher un venue existant avec le même nom et ville
    venue = Venue.find_by(
      name: venue_data['name'],
      city: venue_data['city'],
      postal_code: venue_data['postal_code']
    )

    # Si non trouvé, créer un nouveau venue avec user admin
    unless venue
      venue = Venue.create(
        user: @admin_user,
        name: venue_data['name'],
        address_line1: venue_data['address_line1'],
        address_line2: venue_data['address_line2'],
        postal_code: venue_data['postal_code'],
        city: venue_data['city'],
        department_code: venue_data['department_code'],
        department_name: venue_data['department_name'],
        region: venue_data['region'],
        country: venue_data['country']
      )

      # Si la création échoue, ajouter l'erreur
      unless venue.persisted?
        error_msg = "❌ Échec création Venue '#{venue_data['name']}': #{venue.errors.full_messages.join(', ')}"
        @errors << error_msg
        @skipped_events << {
          data: venue_data,
          reason: error_msg
        }
        return nil
      end
    end

    venue
  end

  def create_event(data, teacher, practice)
    event_data = data['event']

    Event.create(
      user: @admin_user,
      principal_teacher: teacher,
      practice: practice,
      title: event_data['title'],
      description: event_data['description'],
      source_url: event_data['source_url'],
      is_online: event_data['is_online'] || false,
      online_url: event_data['online_url'],
      price_normal: event_data['price_normal']&.to_f || 0.0,
      price_reduced: event_data['price_reduced']&.to_f || 0.0,
      currency: event_data['currency'] || 'EUR',
      is_recurring: false,
      status: 'active'
    )
  end

  def create_occurrence(event, venue, event_data)
    start_date = Date.parse(event_data['start_date'])
    end_date = event_data['end_date'].present? ? Date.parse(event_data['end_date']) : start_date

    # Horaires par défaut si non fournis (toute la journée)
    start_time = event_data['start_time'].present? ?
                   Time.zone.parse("2000-01-01 #{event_data['start_time']}") :
                   Time.zone.parse("2000-01-01 00:00")
    end_time = event_data['end_time'].present? ?
                 Time.zone.parse("2000-01-01 #{event_data['end_time']}") :
                 Time.zone.parse("2000-01-01 23:59")

    occurrence = event.event_occurrences.build(
      venue: venue,
      start_date: start_date,
      end_date: end_date,
      start_time: start_time,
      end_time: end_time,
      recurrence_id: SecureRandom.uuid,
      status: 'active'
    )

    # Pas de contrôle de date passée pour les imports (déjà validés)
    occurrence.skip_past_date_validation = true

    occurrence.save
    occurrence
  end
end

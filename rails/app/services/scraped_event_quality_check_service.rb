class ScrapedEventQualityCheckService
  attr_reader :scraped_event, :quality_flags

  def initialize(scraped_event)
    @scraped_event = scraped_event
    @quality_flags = {}
  end

  def check!
    return false unless scraped_event.json_data.present?

    check_teacher_exists
    check_practice_exists
    check_venue_coherence
    check_date_validity
    check_price_coherence
    check_potential_duplicate
    check_required_fields

    # Mettre à jour les quality_flags
    scraped_event.update!(quality_flags: @quality_flags)

    # Retourner true si pas d'erreurs critiques
    !has_critical_errors?
  end

  def has_critical_errors?
    critical_flags = %w[teacher_not_found practice_not_found date_in_past missing_required_fields]
    (@quality_flags.keys & critical_flags).any?
  end

  def warnings_count
    @quality_flags.count { |_, v| v[:severity] == 'warning' }
  end

  def errors_count
    @quality_flags.count { |_, v| v[:severity] == 'error' }
  end

  private

  def json_data
    @scraped_event.json_data
  end

  def teacher_data
    json_data['teacher']
  end

  def event_data
    json_data['event']
  end

  def venue_data
    json_data['venue']
  end

  def check_teacher_exists
    return unless teacher_data.present?

    teacher = Teacher.find_by(
      first_name: teacher_data['first_name'],
      last_name: teacher_data['last_name']
    )

    unless teacher
      add_flag(
        'teacher_not_found',
        "Teacher '#{teacher_data['first_name']} #{teacher_data['last_name']}' n'existe pas",
        'error'
      )
    end
  end

  def check_practice_exists
    return unless event_data.present? && event_data['practice'].present?

    practice_name = event_data['practice'].strip
    practice = Practice.where('LOWER(name) = ?', practice_name.downcase).first

    unless practice
      add_flag(
        'practice_not_found',
        "Practice '#{practice_name}' n'existe pas",
        'error'
      )
    end
  end

  def check_venue_coherence
    return unless event_data.present?

    is_online = event_data['is_online']
    has_venue = venue_data.present?
    has_online_url = event_data['online_url'].present?

    # Événement en ligne sans URL
    if is_online && !has_online_url
      add_flag(
        'missing_online_url',
        "Événement en ligne sans online_url",
        'error'
      )
    end

    # Événement physique sans venue
    if !is_online && !has_venue
      add_flag(
        'missing_venue',
        "Événement en personne sans venue",
        'error'
      )
    end

    # Événement avec venue qui a des champs manquants
    if has_venue
      required_venue_fields = %w[name address_line1 postal_code city country]
      missing_fields = required_venue_fields.select { |field| venue_data[field].blank? }

      if missing_fields.any?
        add_flag(
          'incomplete_venue',
          "Venue incomplet : champs manquants #{missing_fields.join(', ')}",
          'warning'
        )
      end
    end
  end

  def check_date_validity
    return unless event_data.present? && event_data['start_date'].present?

    begin
      start_date = Date.parse(event_data['start_date'])

      # Date dans le passé
      if start_date < Date.today
        add_flag(
          'date_in_past',
          "Date de début dans le passé : #{start_date}",
          'error'
        )
      end

      # Date très lointaine (plus d'un an)
      if start_date > Date.today + 1.year
        add_flag(
          'date_too_far',
          "Date de début très lointaine : #{start_date}",
          'warning'
        )
      end

      # Vérifier end_date si présent
      if event_data['end_date'].present?
        end_date = Date.parse(event_data['end_date'])

        if end_date < start_date
          add_flag(
            'invalid_date_range',
            "end_date (#{end_date}) avant start_date (#{start_date})",
            'error'
          )
        end
      end
    rescue ArgumentError => e
      add_flag(
        'invalid_date_format',
        "Format de date invalide : #{e.message}",
        'error'
      )
    end
  end

  def check_price_coherence
    return unless event_data.present?

    price_normal = event_data['price_normal'].to_f
    price_reduced = event_data['price_reduced'].to_f

    # Vérifier seulement si des prix sont présents
    if event_data['price_normal'].present? || event_data['price_reduced'].present?
      # Prix négatif
      if price_normal < 0 || price_reduced < 0
        add_flag(
          'negative_price',
          "Prix négatif détecté",
          'error'
        )
      end

      # Prix anormalement élevé (> 500€)
      if price_normal > 500 || price_reduced > 500
        add_flag(
          'price_anomaly',
          "Prix très élevé : normal=#{price_normal}, réduit=#{price_reduced}",
          'warning'
        )
      end

      # Prix réduit > prix normal (seulement si les deux sont présents et > 0)
      if price_normal > 0 && price_reduced > 0 && price_reduced > price_normal
        add_flag(
          'price_incoherence',
          "Prix réduit (#{price_reduced}) supérieur au prix normal (#{price_normal})",
          'warning'
        )
      end
    end

    # Devise manquante ou invalide (warning seulement, car EUR par défaut)
    valid_currencies = %w[EUR USD CAD CHF GBP]
    currency = event_data['currency']

    if currency.present? && !valid_currencies.include?(currency)
      add_flag(
        'invalid_currency',
        "Devise invalide : #{currency}",
        'warning'
      )
    end
  end

  def check_potential_duplicate
    return unless event_data.present? && event_data['start_date'].present?

    # Chercher des événements similaires
    start_date = Date.parse(event_data['start_date']) rescue nil
    return unless start_date

    # Recherche par source_url exacte
    if Event.exists?(source_url: event_data['source_url'])
      add_flag(
        'potential_duplicate_url',
        "Un événement existe déjà avec cette source_url",
        'warning'
      )
    end

    # Recherche par titre et date similaires
    similar_events = Event.joins(:event_occurrences)
                          .where('LOWER(events.title) = ?', event_data['title'].downcase)
                          .where('event_occurrences.start_date = ?', start_date)
                          .limit(1)

    if similar_events.any?
      add_flag(
        'potential_duplicate_title_date',
        "Un événement similaire existe avec même titre et date",
        'warning'
      )
    end
  end

  def check_required_fields
    return unless event_data.present?

    # Prix et horaires sont désormais optionnels (parfois il faut contacter le pro)
    required_fields = {
      'title' => 'Titre',
      'description' => 'Description',
      'practice' => 'Practice',
      'source_url' => 'URL source',
      'start_date' => 'Date de début'
    }

    missing_fields = required_fields.select { |field, _| event_data[field].blank? }

    if missing_fields.any?
      missing_labels = missing_fields.values.join(', ')
      add_flag(
        'missing_required_fields',
        "Champs requis manquants : #{missing_labels}",
        'error'
      )
    end
  end

  def add_flag(key, message, severity = 'warning')
    @quality_flags[key] = {
      message: message,
      severity: severity,
      checked_at: Time.current.iso8601
    }
  end
end

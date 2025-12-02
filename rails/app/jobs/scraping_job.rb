# Job principal de scraping d'un teacher_url
# Orchestration : HTML scraping → Qwen extraction → Save to DB → Quality check
class ScrapingJob < ApplicationJob
  queue_as :scraping

  # Retry en cas d'erreur réseau temporaire
  retry_on Ferrum::TimeoutError, wait: 5.minutes, attempts: 3
  retry_on Net::ReadTimeout, wait: 5.minutes, attempts: 3

  # Ne pas retry en cas d'erreur API key ou parsing
  discard_on ArgumentError

  # @param teacher_url_id [String] ID du TeacherUrl à scraper
  def perform(teacher_url_id)
    teacher_url = TeacherUrl.find(teacher_url_id)

    Rails.logger.info("Début scraping pour #{teacher_url.url} (Teacher: #{teacher_url.teacher.name})")

    # Étape 1 : Scraper le HTML
    html_content = scrape_html(teacher_url.url)
    return if html_content.nil? # Erreur déjà loggée par le service

    # Étape 2 : Extraire les événements via Qwen
    events_data = extract_events(html_content, teacher_url.url)
    return if events_data.nil? || events_data.empty?

    # Étape 3 : Créer les ScrapedEvents
    created_count = save_scraped_events(events_data, teacher_url)

    # Étape 4 : Mettre à jour last_scraped_at
    teacher_url.update!(
      last_scraped_at: Time.current,
      scraping_config: teacher_url.scraping_config.merge(
        "last_scrape_events_count" => created_count
      )
    )

    Rails.logger.info("Scraping terminé pour #{teacher_url.url}: #{created_count} événement(s) créé(s)")
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("TeacherUrl #{teacher_url_id} introuvable: #{e.message}")
  rescue StandardError => e
    Rails.logger.error("Erreur scraping job pour #{teacher_url_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise # Re-raise pour que ActiveJob puisse gérer le retry
  end

  private

  # Scrape le HTML avec Ferrum
  def scrape_html(url)
    service = HtmlScraperService.new(url)
    html = service.scrape!

    if html.nil?
      Rails.logger.error("Échec scraping HTML: #{service.error}")
      # TODO: Envoyer notification admin
      return nil
    end

    html
  end

  # Extrait les événements avec Qwen
  def extract_events(html_content, source_url)
    service = QwenApiService.new(html_content, source_url)
    events = service.extract!

    if events.nil?
      Rails.logger.error("Échec extraction Qwen: #{service.error}")
      # TODO: Envoyer notification admin
      return nil
    end

    if events.empty?
      Rails.logger.warn("Aucun événement trouvé sur #{source_url}")
      # Pas une erreur, peut-être que le site n'a pas d'événements actuellement
    end

    events
  end

  # Sauvegarde les événements en DB avec gestion des récurrences
  # @return [Integer] Nombre d'événements créés (y compris toutes les occurrences)
  def save_scraped_events(events_data, teacher_url)
    created_count = 0
    recurrent_count = 0
    ponctual_count = 0

    events_data.each do |event_data|
      begin
        event_info = event_data.dig('event') || {}
        is_recurring = event_info['is_recurring'] == true

        if is_recurring
          # ÉVÉNEMENT RÉCURRENT → calculer toutes les dates
          count = create_recurring_events(event_data, teacher_url)
          created_count += count
          recurrent_count += 1 if count > 0
        else
          # ÉVÉNEMENT PONCTUEL → créer normalement
          create_scraped_event(event_data, teacher_url)
          created_count += 1
          ponctual_count += 1
        end

      rescue StandardError => e
        Rails.logger.error("Erreur création ScrapedEvent: #{e.message}")
        Rails.logger.error("Data: #{event_data.inspect}")
        Rails.logger.error(e.backtrace.join("\n"))
        # Continuer avec les autres événements
        next
      end
    end

    Rails.logger.info("#{created_count} ScrapedEvent(s) créé(s) : #{recurrent_count} récurrent(s), #{ponctual_count} ponctuel(s)")
    created_count
  end

  # Crée plusieurs ScrapedEvents pour un événement récurrent
  # @return [Integer] Nombre d'occurrences créées
  def create_recurring_events(event_data, teacher_url)
    event_info = event_data.dig('event') || {}
    recurrence_rule = event_info['recurrence_rule']

    unless recurrence_rule
      Rails.logger.warn("Événement marqué récurrent mais sans recurrence_rule")
      return 0
    end

    # Calculer toutes les dates
    calculator = RecurrenceCalculatorService.new(recurrence_rule, event_info['start_date'])
    dates = calculator.calculate!

    if calculator.error
      Rails.logger.error("Erreur calcul récurrence: #{calculator.error}")
      return 0
    end

    if dates.empty?
      Rails.logger.warn("Aucune date calculée pour événement récurrent")
      return 0
    end

    # Créer un ScrapedEvent par date
    dates.each do |date|
      # Dupliquer l'événement et remplacer la date
      event_copy = event_data.deep_dup
      event_copy['event']['start_date'] = date.to_s
      event_copy['event']['end_date'] = date.to_s # Événement d'un seul jour
      event_copy['event']['is_recurring'] = false # Marquer comme non-récurrent (c'est une occurrence)

      create_scraped_event(event_copy, teacher_url)
    end

    dates.length
  end

  # Crée un ScrapedEvent depuis les données Qwen
  def create_scraped_event(event_data, teacher_url)
    scraped_event = ScrapedEvent.create!(
      teacher_url: teacher_url,
      source_url: event_data.dig("scraping_metadata", "source_url") || teacher_url.url,
      html_content: nil, # On ne sauvegarde pas le HTML pour économiser l'espace
      json_data: event_data, # Tout le JSON (format V2)
      status: :pending, # Validation humaine nécessaire par défaut
      quality_flags: {}, # Sera rempli par quality check
      scraped_at: Time.current
    )

    # Vérification qualité automatique
    quality_service = ScrapedEventQualityCheckService.new(scraped_event)
    quality_service.check!

    scraped_event
  end
end

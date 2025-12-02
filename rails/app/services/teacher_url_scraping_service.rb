# Service pour scraper une ou plusieurs URLs de teachers
class TeacherUrlScrapingService
  attr_reader :teacher_url, :results, :errors

  def initialize(teacher_url)
    @teacher_url = teacher_url
    @results = { scraped_count: 0, created_count: 0, errors: [] }
    @errors = []
  end

  # Scrape l'URL et crée les ScrapedEvents
  def scrape!
    start_time = Time.current
    @teacher_url.update(start_scraping_at: start_time, end_scraping_at: nil)

    begin
      # 1. Fetch HTML
      html_content = fetch_html(@teacher_url.url)

      if html_content.blank?
        error_msg = @errors.last || "HTML vide ou échec du fetch"
        @errors << error_msg unless @errors.include?(error_msg)

        # Déterminer le statut d'erreur selon le message
        status = detect_error_status(error_msg)
        duration = (Time.current - start_time).to_i
        error_details = @errors.join(' | ')
        update_teacher_url_scraped_at(duration, status, error_details)
        return false
      end

      # 2. Extraire les événements via Qwen/OpenRouter/Ollama
      # Passer le teacher owner et le type de site pour le contexte
      site_type = @teacher_url.scraping_config&.dig("site_type") || "mono_teacher"
      qwen_service = QwenApiService.new(html_content, @teacher_url.url, @teacher_url.teacher, site_type)
      events_data = qwen_service.extract!

      if events_data.nil?
        @errors << (qwen_service.error || "Échec extraction Qwen")
        duration = (Time.current - start_time).to_i
        error_details = @errors.join(' | ')
        update_teacher_url_scraped_at(duration, 'EXTRACTION_ERROR', error_details)
        return false
      end

      if events_data.empty?
        @results[:message] = "Aucun événement trouvé sur cette page"
        duration = (Time.current - start_time).to_i
        update_teacher_url_scraped_at(duration, 'NO_EVENTS')
        return true
      end

      # 3. Créer les ScrapedEvents (avec expansion des récurrences)
      events_data.each do |event_json|
        if event_json.dig('event', 'is_recurring')
          # Événement récurrent : calculer toutes les occurrences
          expand_and_create_recurrent_event(event_json, html_content, start_time)
        else
          # Événement ponctuel : créer directement
          create_scraped_event(event_json, html_content, start_time)
        end
      end

      duration = (Time.current - start_time).to_i

      # Vérifier la qualité des dates pour déterminer le statut
      status = check_dates_quality

      # Passer les détails d'erreur si LOW_DATES
      error_details = (status == 'LOW_DATES' && @errors.any?) ? @errors.join(' | ') : nil
      update_teacher_url_scraped_at(duration, status, error_details)
      @results[:scraped_count] = events_data.length
      @results[:message] = "#{@results[:created_count]} événement(s) créé(s) sur #{events_data.length} trouvé(s)"

      true
    rescue StandardError => e
      @errors << "Erreur lors du scraping: #{e.message}"
      Rails.logger.error("TeacherUrlScrapingService error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      duration = (Time.current - start_time).to_i
      error_details = "#{e.message} | #{e.backtrace.first(3).join(' | ')}"
      update_teacher_url_scraped_at(duration, 'EXCEPTION', error_details)
      false
    end
  end

  # Scrape plusieurs teacher_urls
  def self.scrape_multiple(teacher_urls)
    results = {
      success: [],
      failed: [],
      total_events: 0
    }

    teacher_urls.each do |teacher_url|
      service = new(teacher_url)
      if service.scrape!
        results[:success] << {
          teacher_url: teacher_url,
          events_count: service.results[:created_count],
          message: service.results[:message]
        }
        results[:total_events] += service.results[:created_count]
      else
        results[:failed] << {
          teacher_url: teacher_url,
          errors: service.errors
        }
      end
    end

    results
  end

  private

  def fetch_html(url)
    require 'net/http'
    require 'uri'

    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.read_timeout = 30

    request = Net::HTTP::Get.new(uri.request_uri)
    request['User-Agent'] = 'Mozilla/5.0 (compatible; AjourduyScraper/1.0)'

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      @errors << "Erreur HTTP #{response.code}"
      return nil
    end

    response.body
  rescue StandardError => e
    @errors << "Erreur fetch HTML: #{e.message}"
    nil
  end

  def expand_and_create_recurrent_event(event_json, html_content, scraped_at)
    recurrence_rule = event_json.dig('event', 'recurrence_rule')
    event_start_date = event_json.dig('event', 'start_date')

    unless recurrence_rule.present?
      @errors << "Événement récurrent sans recurrence_rule"
      return
    end

    # Calculer toutes les occurrences
    calculator = RecurrenceCalculatorService.new(recurrence_rule, event_start_date)
    dates = calculator.calculate!

    if dates.empty?
      @errors << "Aucune date calculée pour événement récurrent: #{calculator.error}"
      return
    end

    Rails.logger.info("Événement récurrent: #{dates.length} occurrences calculées")

    # Créer un ScrapedEvent par occurrence
    dates.each do |date|
      occurrence_json = event_json.deep_dup
      occurrence_json['event']['start_date'] = date.to_s
      occurrence_json['event']['is_recurring'] = false # Chaque occurrence est individuelle
      occurrence_json['event'].delete('recurrence_rule') # Pas besoin de la règle

      create_scraped_event(occurrence_json, html_content, scraped_at)
    end
  end

  def create_scraped_event(event_json, html_content, scraped_at)
    scraped_event = ScrapedEvent.create!(
      source_url: @teacher_url.url,
      teacher_url: @teacher_url,
      scraped_at: scraped_at,
      html_content: html_content,
      json_data: event_json,
      status: 'pending'
    )

    # Vérifier la qualité automatiquement
    quality_service = ScrapedEventQualityCheckService.new(scraped_event)
    quality_service.check!

    @results[:created_count] += 1
    scraped_event
  rescue StandardError => e
    @errors << "Erreur création ScrapedEvent: #{e.message}"
    Rails.logger.error("Échec création ScrapedEvent: #{e.message}")
    nil
  end

  def update_teacher_url_scraped_at(duration_seconds = nil, status = nil, error_details = nil)
    end_time = Time.current
    updates = {
      last_scraped_at: end_time,
      end_scraping_at: end_time
    }
    updates[:last_scraping_duration] = duration_seconds if duration_seconds
    updates[:last_scraping_status] = status if status
    updates[:last_scraping_error_details] = error_details if error_details
    @teacher_url.update(updates)
  end

  # Détecte le statut d'erreur selon le message
  def detect_error_status(error_msg)
    case error_msg
    # SSL/TLS errors
    when /SSL_connect/, /ssl/i, /tlsv1/i, /certificate/i, /handshake/i
      'SSL_ERROR'

    # DNS errors
    when /getaddrinfo/i, /Name or service not known/i, /DNS/i, /nodename nor servname/i
      'DNS_ERROR'

    # Bad URL / 404 / Not Found
    when /Bad Request/i, /404/, /Not Found/i, /Invalid URI/i, /bad uri/i
      'BAD_URL'

    # Connection errors (timeout, refused, reset)
    when /timeout/i, /timed out/i, /execution expired/i
      'TIMEOUT_ERROR'
    when /connection refused/i, /ECONNREFUSED/i
      'CONNECTION_REFUSED'
    when /connection reset/i, /ECONNRESET/i
      'CONNECTION_RESET'

    # HTTP redirects and errors
    when /301/, /302/, /303/, /307/, /308/, /Moved Permanently/i, /redirect/i
      'HTTP_REDIRECT'
    when /401/, /Unauthorized/i
      'HTTP_UNAUTHORIZED'
    when /403/, /Forbidden/i
      'HTTP_FORBIDDEN'
    when /500/, /502/, /503/, /504/, /Internal Server Error/i, /Bad Gateway/i, /Service Unavailable/i
      'HTTP_SERVER_ERROR'
    when /Erreur HTTP/i
      'HTTP_ERROR'

    # Other network errors
    when /Network is unreachable/i, /No route to host/i
      'NETWORK_ERROR'

    # Unknown errors
    else
      'UNKNOWN_ERROR'
    end
  end

  # Vérifie la qualité des dates pour déterminer le statut
  def check_dates_quality
    # Récupérer tous les événements scrapés pour ce teacher_url lors de cette session
    events = ScrapedEvent.where(teacher_url: @teacher_url)
                         .where('scraped_at >= ?', @teacher_url.start_scraping_at)

    return 'OK' if events.empty? # Cas NO_EVENTS déjà géré avant

    total = events.count
    # Vérifier la présence de start_date dans le JSON (json_data -> 'event' ->> 'start_date')
    with_dates = events.where("json_data -> 'event' ->> 'start_date' IS NOT NULL").count
    percentage = (with_dates.to_f / total * 100).round(1)

    if percentage < 95.0
      'LOW_DATES'
    else
      'OK'
    end
  end
end

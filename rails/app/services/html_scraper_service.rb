# Service de scraping HTML utilisant l'API Playwright (container séparé)
# Récupère le contenu HTML d'une URL après rendu JavaScript
class HtmlScraperService
  attr_reader :url, :html_content, :error

  # URL de l'API Playwright (container Docker)
  PLAYWRIGHT_API_URL = "http://playwright:3000/render".freeze
  TIMEOUT = 120 # secondes

  # @param url [String] L'URL à scraper
  # @param options [Hash] Options personnalisées (réservé pour usage futur)
  def initialize(url, options = {})
    @url = url
    @options = options
    @html_content = nil
    @error = nil
  end

  # Exécute le scraping et retourne le HTML
  # @return [String, nil] Le contenu HTML ou nil en cas d'erreur
  def scrape!
    validate_url!

    begin
      uri = URI(PLAYWRIGHT_API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = TIMEOUT
      http.open_timeout = 10

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request.body = { url: @url }.to_json

      Rails.logger.info("Appel API Playwright pour #{@url}")

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        @error = "Erreur API Playwright: #{response.code} - #{response.body[0..500]}"
        Rails.logger.error(@error)
        return nil
      end

      @html_content = response.body

      Rails.logger.info("Scraping réussi pour #{@url} (#{@html_content.length} caractères)")
      @html_content
    rescue Timeout::Error => e
      @error = "Timeout lors du scraping de #{@url}: #{e.message}"
      Rails.logger.error(@error)
      nil
    rescue StandardError => e
      @error = "Erreur lors du scraping de #{@url}: #{e.class.name} - #{e.message}"
      Rails.logger.error(@error)
      Rails.logger.error(e.backtrace.join("\n"))
      nil
    end
  end

  # Version classe pour usage simple
  # @param url [String] L'URL à scraper
  # @return [String, nil] Le contenu HTML ou nil
  def self.scrape(url)
    new(url).scrape!
  end

  # Note: Les screenshots sont automatiquement générés par Playwright
  # et sauvegardés dans playwright/outputs/last_screenshot.png

  private

  def validate_url!
    raise ArgumentError, "URL ne peut pas être vide" if @url.blank?

    uri = URI.parse(@url)
    raise ArgumentError, "URL invalide: doit commencer par http:// ou https://" unless uri.is_a?(URI::HTTP)
  rescue URI::InvalidURIError => e
    raise ArgumentError, "Format d'URL invalide: #{e.message}"
  end
end

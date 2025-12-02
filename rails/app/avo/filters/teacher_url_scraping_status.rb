class Avo::Filters::TeacherUrlScrapingStatus < Avo::Filters::SelectFilter
  self.name = "Statut scraping"

  def apply(request, query, value)
    case value
    when "ok"
      query.where(last_scraping_status: "OK")
    when "errors"
      query.where(last_scraping_status: [
        "BAD_URL", "SSL_ERROR", "HTTP_ERROR", "HTTP_REDIRECT", "HTTP_UNAUTHORIZED",
        "HTTP_FORBIDDEN", "HTTP_SERVER_ERROR", "DNS_ERROR", "TIMEOUT_ERROR",
        "CONNECTION_REFUSED", "CONNECTION_RESET", "NETWORK_ERROR",
        "EXTRACTION_ERROR", "EXCEPTION", "LOW_DATES", "UNKNOWN_ERROR"
      ])
    when "no_events"
      query.where(last_scraping_status: "NO_EVENTS")
    when "not_tested"
      query.where(last_scraping_status: nil)
    else
      query
    end
  end

  def options
    {
      "✅ OK (100% dates)" => "ok",
      "❌ Erreurs (URL/SSL/HTTP/DNS/timeout/réseau/extraction/inconnu)" => "errors",
      "⚠️ Aucun événement" => "no_events",
      "❓ Non testé" => "not_tested"
    }
  end
end

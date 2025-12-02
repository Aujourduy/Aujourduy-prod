# Job pour scraper une TeacherUrl de manière asynchrone
# Utilisé par l'action Avo "Scraper maintenant" pour éviter timeout Cloudflare
class TeacherUrlScrapingJob < ApplicationJob
  queue_as :scraping

  # Retry en cas d'erreur réseau temporaire
  retry_on Net::ReadTimeout, wait: 5.minutes, attempts: 3
  retry_on Net::OpenTimeout, wait: 5.minutes, attempts: 3

  # Ne pas retry en cas d'erreur API
  discard_on ArgumentError

  # @param teacher_url_id [String] ID du TeacherUrl à scraper
  def perform(teacher_url_id)
    teacher_url = TeacherUrl.find(teacher_url_id)

    Rails.logger.info("🚀 Début scraping job pour #{teacher_url.url} (Teacher: #{teacher_url.teacher&.full_name})")

    # Utiliser le service existant qui est bien testé
    service = TeacherUrlScrapingService.new(teacher_url)
    success = service.scrape!

    if success
      Rails.logger.info("✅ Scraping réussi pour #{teacher_url.url}: #{service.results[:created_count]} événement(s)")
    else
      Rails.logger.error("❌ Scraping échoué pour #{teacher_url.url}: #{service.errors.join(', ')}")
      # On ne raise pas pour ne pas retry automatiquement, les erreurs sont déjà loggées
    end

  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error("TeacherUrl #{teacher_url_id} introuvable: #{e.message}")
  rescue StandardError => e
    Rails.logger.error("Erreur scraping job pour #{teacher_url_id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise # Re-raise pour que ActiveJob puisse gérer le retry
  end
end

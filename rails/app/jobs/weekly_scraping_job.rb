# Job récurrent hebdomadaire : scrape tous les teachers avec frequency: "weekly"
# Programmé via Solid Queue recurring jobs (config/recurring.yml)
class WeeklyScrapingJob < ApplicationJob
  queue_as :scraping

  # Exécuté chaque lundi à 2h du matin (configuré dans recurring.yml)
  def perform
    Rails.logger.info("Début WeeklyScrapingJob")

    # Récupérer tous les teacher_urls avec frequency "weekly"
    teacher_urls = TeacherUrl.joins(:teacher)
                             .where("scraping_config->>'frequency' = ?", "weekly")
                             .where(teachers: { active: true })

    Rails.logger.info("#{teacher_urls.count} teacher_urls à scraper (weekly)")

    # Lancer un ScrapingJob pour chaque URL
    # spread: 1 heure = étaler les jobs sur 1h pour ne pas surcharger
    teacher_urls.find_each.with_index do |teacher_url, index|
      delay = (index * 2).minutes # 2 minutes entre chaque job

      ScrapingJob.set(wait: delay).perform_later(teacher_url.id)

      Rails.logger.info("ScrapingJob programmé pour #{teacher_url.url} dans #{delay.to_i / 60} minutes")
    end

    Rails.logger.info("WeeklyScrapingJob terminé : #{teacher_urls.count} jobs programmés")
  end
end

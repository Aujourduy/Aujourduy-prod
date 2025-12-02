# Job récurrent annuel : scrape tous les teachers avec frequency: "yearly"
# Programmé via Solid Queue recurring jobs (config/recurring.yml)
class YearlyScrapingJob < ApplicationJob
  queue_as :scraping

  # Exécuté chaque 1er janvier à 3h du matin (configuré dans recurring.yml)
  def perform
    Rails.logger.info("Début YearlyScrapingJob")

    # Récupérer tous les teacher_urls avec frequency "yearly"
    teacher_urls = TeacherUrl.joins(:teacher)
                             .where("scraping_config->>'frequency' = ?", "yearly")
                             .where(teachers: { active: true })

    Rails.logger.info("#{teacher_urls.count} teacher_urls à scraper (yearly)")

    # Lancer un ScrapingJob pour chaque URL
    # spread: 2 heures pour ne pas surcharger
    teacher_urls.find_each.with_index do |teacher_url, index|
      delay = (index * 5).minutes # 5 minutes entre chaque job

      ScrapingJob.set(wait: delay).perform_later(teacher_url.id)

      Rails.logger.info("ScrapingJob programmé pour #{teacher_url.url} dans #{delay.to_i / 60} minutes")
    end

    Rails.logger.info("YearlyScrapingJob terminé : #{teacher_urls.count} jobs programmés")
  end
end

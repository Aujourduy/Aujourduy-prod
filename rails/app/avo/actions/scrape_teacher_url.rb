class Avo::Actions::ScrapeTeacherUrl < Avo::BaseAction
  self.name = "Scraper maintenant"
  self.message = "Lancer le scraping pour les URLs sélectionnées ?"
  self.may_download_file = false
  self.visible = -> { true }
  self.confirm_button_label = "Scraper"

  def handle(records:, fields:, current_user:, resource:, **args)
    # Enqueue les jobs en arrière-plan pour éviter timeout Cloudflare (100s)
    records.each do |teacher_url|
      TeacherUrlScrapingJob.perform_later(teacher_url.id)
    end

    # Message selon nombre d'URLs
    if records.count == 1
      teacher_url = records.first
      succeed "✅ Scraping lancé en arrière-plan pour #{teacher_url.name || teacher_url.url}.\n\n💡 Rafraîchissez cette page dans 1-2 minutes pour voir les événements scrapés."
    else
      succeed "✅ Scraping lancé en arrière-plan pour #{records.count} URL(s).\n\n💡 Rafraîchissez cette page dans 2-3 minutes pour voir les événements scrapés."
    end
  end
end

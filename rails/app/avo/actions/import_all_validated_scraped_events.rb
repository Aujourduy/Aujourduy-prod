class Avo::Actions::ImportAllValidatedScrapedEvents < Avo::BaseAction
  self.name = "Importer TOUS les événements validés"
  self.message = "Importer tous les événements validés (statut = validated) vers la production ?"
  self.may_download_file = false
  self.visible = -> { view == :index }
  self.standalone = true
  self.confirm_button_label = "Importer tout"

  def handle(records:, fields:, current_user:, resource:, **args)
    results = ScrapedEventImportService.import_all_validated!(current_user)

    success_count = results[:success].count
    failed_count = results[:failed].count
    skipped_count = results[:skipped].count

    if failed_count > 0
      errors = results[:failed].map { |f| "#{f[:scraped_event].event_title}: #{f[:errors].join(', ')}" }
      error "⚠️ #{success_count} importé(s), #{failed_count} échoué(s). Erreurs: #{errors.join(' | ')}"
    else
      succeed "✅ #{success_count} événement(s) importé(s) avec succès."
    end
  end
end

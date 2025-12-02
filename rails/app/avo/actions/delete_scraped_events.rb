class Avo::Actions::DeleteScrapedEvents < Avo::BaseAction
  self.name = "Supprimer les événements scrapés"
  self.message = "Voulez-vous vraiment supprimer les événements scrapés sélectionnés ? Cette action est irréversible."
  self.may_download_file = false
  self.visible = -> { true }
  self.confirm_button_label = "Supprimer"

  def handle(records:, fields:, current_user:, resource:, **args)
    deleted_count = 0
    failed_count = 0
    errors_list = []

    records.each do |scraped_event|
      begin
        scraped_event.destroy!
        deleted_count += 1
      rescue => e
        failed_count += 1
        errors_list << "#{scraped_event.event_title}: #{e.message}"
      end
    end

    # Message détaillé selon les résultats
    if records.count == 1
      # Cas d'un seul événement
      if deleted_count == 1
        succeed "✅ Événement scrapé supprimé avec succès !"
      elsif failed_count == 1
        raise AvoActionError.new(
          title: "Échec de la suppression",
          details: errors_list.first,
          hint: nil
        )
      end
    else
      # Cas de plusieurs événements
      if failed_count > 0
        summary = []
        summary << "✅ #{deleted_count} supprimé(s)" if deleted_count > 0
        summary << "❌ #{failed_count} échoué(s)" if failed_count > 0

        raise AvoActionError.new(
          title: "Échec de la suppression en masse",
          details: "#{summary.join(', ')}\n\nDétails:\n#{errors_list.join("\n\n")}",
          hint: nil
        )
      else
        succeed "✅ #{deleted_count} événement(s) scrapé(s) supprimé(s) avec succès."
      end
    end
  end
end

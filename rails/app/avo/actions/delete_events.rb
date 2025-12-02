class Avo::Actions::DeleteEvents < Avo::BaseAction
  self.name = "Supprimer les événements"
  self.message = "Voulez-vous vraiment supprimer les événements sélectionnés ? Cette action est irréversible et supprimera aussi toutes les occurrences associées."
  self.may_download_file = false
  self.visible = -> { true }
  self.confirm_button_label = "Supprimer"

  def handle(records:, fields:, current_user:, resource:, **args)
    deleted_count = 0
    failed_count = 0
    errors_list = []

    records.each do |event|
      begin
        event.destroy!
        deleted_count += 1
      rescue => e
        failed_count += 1
        errors_list << "#{event.title}: #{e.message}"
      end
    end

    # Message détaillé selon les résultats
    if records.count == 1
      # Cas d'un seul événement
      if deleted_count == 1
        succeed "✅ Événement supprimé avec succès !"
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
        succeed "✅ #{deleted_count} événement(s) supprimé(s) avec succès."
      end
    end
  end
end

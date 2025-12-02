class Avo::Actions::ImportScrapedEvent < Avo::BaseAction
  self.name = "Importer vers production"
  self.message = "Importer les événements validés vers la base de production ?"
  self.may_download_file = false
  self.visible = -> { true }
  self.confirm_button_label = "Importer"

  def handle(records:, fields:, current_user:, resource:, **args)
    success_count = 0
    failed_count = 0
    skipped_count = 0
    errors_list = []
    skipped_reasons = []

    records.each do |scraped_event|
      if scraped_event.status != 'validated'
        skipped_count += 1
        skipped_reasons << "#{scraped_event.event_title}: statut '#{scraped_event.status}' (doit être 'validated')"
        next
      end

      service = ScrapedEventImportService.new(scraped_event, current_user)
      if service.import!
        success_count += 1
      else
        failed_count += 1
        errors_list << "#{scraped_event.event_title}: #{service.errors.join(', ')}"
      end
    end

    # Message détaillé selon les résultats
    if records.count == 1
      # Cas d'un seul événement
      if success_count == 1
        succeed "✅ Événement importé avec succès vers la production !"
      elsif skipped_count == 1
        raise AvoActionError.new(
          title: "Import impossible",
          details: skipped_reasons.first,
          hint: "💡 Utilisez d'abord l'action 'Valider' pour marquer l'événement comme validé"
        )
      elsif failed_count == 1
        raise AvoActionError.new(
          title: "Échec de l'import",
          details: errors_list.first,
          hint: nil
        )
      end
    else
      # Cas de plusieurs événements
      if failed_count > 0 || (skipped_count > 0 && success_count == 0)
        details = []
        details += skipped_reasons if skipped_reasons.any?
        details += errors_list if errors_list.any?

        summary = []
        summary << "✅ #{success_count} importé(s)" if success_count > 0
        summary << "❌ #{failed_count} échoué(s)" if failed_count > 0
        summary << "⏭️ #{skipped_count} ignoré(s)" if skipped_count > 0

        raise AvoActionError.new(
          title: "Échec de l'import en masse",
          details: "#{summary.join(', ')}\n\nDétails:\n#{details.join("\n\n")}",
          hint: nil
        )
      else
        message_parts = []
        message_parts << "✅ #{success_count} importé(s)" if success_count > 0
        message_parts << "⏭️ #{skipped_count} ignoré(s)" if skipped_count > 0
        succeed message_parts.join(", ")
      end
    end
  end
end

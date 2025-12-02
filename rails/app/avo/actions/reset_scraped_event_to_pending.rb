class Avo::Actions::ResetScrapedEventToPending < Avo::BaseAction
  self.name = "Revenir en attente"
  self.message = "Réinitialiser au statut 'pending' ?"
  self.may_download_file = false
  self.visible = -> { true }
  self.confirm_button_label = "Réinitialiser"

  def handle(records:, fields:, current_user:, resource:, **args)
    reset_count = 0
    deleted_events = 0

    records.each do |scraped_event|
      # Supprimer l'événement importé s'il existe
      if scraped_event.imported_event.present?
        scraped_event.imported_event.destroy
        deleted_events += 1
      end

      # Réinitialiser au statut pending
      scraped_event.update!(
        status: 'pending',
        imported_event_id: nil,
        imported_at: nil,
        import_error: nil,
        validated_by_user_id: nil,
        validated_at: nil,
        validation_notes: nil
      )

      reset_count += 1
    end

    if deleted_events > 0
      succeed "✅ #{reset_count} événement(s) réinitialisé(s). #{deleted_events} événement(s) importé(s) supprimé(s)."
    else
      succeed "✅ #{reset_count} événement(s) réinitialisé(s)."
    end
  end
end

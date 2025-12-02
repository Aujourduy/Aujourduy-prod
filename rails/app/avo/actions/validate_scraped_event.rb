class Avo::Actions::ValidateScrapedEvent < Avo::BaseAction
  self.name = "Valider"
  self.message = "Marquer comme validé et prêt à importer ?"
  self.may_download_file = false
  self.visible = -> { true }

  def fields
    field :validation_notes, as: :textarea, placeholder: "Notes de validation (optionnel)"
    field :force_validation, as: :boolean, default: false, help: "Pour forcer la validation"
  end

  def handle(records:, fields:, current_user:, resource:, **args)
    validated = 0
    skipped = 0
    notes = fields[:validation_notes]
    force = fields[:force_validation]
    errors_list = []

    records.each do |scraped_event|
      # Vérifier si déjà validé
      if scraped_event.status != 'pending'
        skipped += 1
        next
      end

      # Re-vérifier la qualité avant de bloquer (pour utiliser les règles à jour)
      quality_service = ScrapedEventQualityCheckService.new(scraped_event)
      quality_service.check!
      scraped_event.reload

      # Vérifier s'il y a des erreurs critiques
      has_errors = scraped_event.quality_flags.present? &&
                   scraped_event.quality_flags.any? { |_k, v| v['severity'] == 'error' }

      if has_errors && !force
        error_messages = scraped_event.quality_flags
          .select { |_k, v| v['severity'] == 'error' }
          .map { |_k, v| v['message'] }
          .join(', ')

        errors_list << "#{scraped_event.event_title}: #{error_messages}"
        skipped += 1
      else
        scraped_event.validate!(current_user, notes)
        validated += 1
      end
    end

    # Message selon les résultats
    if records.count == 1
      if validated == 1
        succeed "✅ Événement validé avec succès !"
      elsif errors_list.any?
        raise AvoActionError.new(
          title: "Validation bloquée",
          details: errors_list.first,
          hint: "💡 Pour valider quand même, recommencez la validation en cochant la case 'Force validation' ci-dessous dans ce formulaire et cliquez à nouveau sur le bouton Valider"
        )
      else
        raise AvoActionError.new(
          title: "Validation impossible",
          details: "Statut actuel : #{records.first.status}\n\nSeuls les événements en statut 'pending' peuvent être validés.",
          hint: nil
        )
      end
    else
      if errors_list.any? && validated == 0
        raise AvoActionError.new(
          title: "Validation bloquée pour #{skipped} événement(s)",
          details: errors_list.join("\n\n"),
          hint: "💡 Pour valider quand même, ecommencez la validation en cochant la case 'Force validation' ci-dessous dans ce formulaire et cliquez à nouveau sur le bouton Valider"
        )
      elsif validated > 0
        succeed "✅ #{validated} événement(s) validé(s). #{skipped} ignoré(s)."
      else
        raise AvoActionError.new(
          title: "Aucun événement validé",
          details: "#{skipped} événement(s) ignoré(s)",
          hint: nil
        )
      end
    end
  end
end

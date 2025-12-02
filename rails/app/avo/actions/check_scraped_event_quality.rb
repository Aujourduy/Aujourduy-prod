class Avo::Actions::CheckScrapedEventQuality < Avo::BaseAction
  self.name = "Vérifier la qualité"
  self.message = "Exécuter les vérifications de qualité automatiques ?"
  self.may_download_file = false
  self.visible = -> { true }

  def handle(records:, fields:, current_user:, resource:, **args)
    checked = 0
    errors_count = 0
    warnings_count = 0
    all_warnings = []
    all_errors = []

    records.each do |scraped_event|
      service = ScrapedEventQualityCheckService.new(scraped_event)
      if service.check!
        checked += 1
        errors_count += service.errors_count
        warnings_count += service.warnings_count

        # Collecter les détails des erreurs et avertissements
        if scraped_event.quality_flags.present?
          event_title = scraped_event.event_title || "Sans titre"

          scraped_event.quality_flags.each do |key, flag|
            if flag['severity'] == 'error'
              all_errors << "#{event_title}: #{flag['message']}"
            elsif flag['severity'] == 'warning'
              all_warnings << "#{event_title}: #{flag['message']}"
            end
          end
        end
      end
    end

    # Construire le message détaillé
    details_parts = [
      "#{checked} événement(s) vérifié(s)",
      "#{errors_count} erreur(s) trouvée(s)",
      "#{warnings_count} avertissement(s) trouvé(s)"
    ]

    if all_errors.any?
      details_parts << "\n\n❌ ERREURS :"
      details_parts << all_errors.map { |e| "  • #{e}" }.join("\n")
    end

    if all_warnings.any?
      details_parts << "\n\n⚠️ AVERTISSEMENTS :"
      details_parts << all_warnings.map { |w| "  • #{w}" }.join("\n")
    end

    # Utiliser une erreur avec titre de succès pour forcer le dismiss manuel
    raise AvoActionError.new(
      title: "✅ Vérification terminée",
      details: details_parts.join("\n"),
      hint: nil
    )
  end
end

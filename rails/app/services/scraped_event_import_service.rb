class ScrapedEventImportService
  attr_reader :scraped_event, :import_service, :errors, :user

  def initialize(scraped_event, user = nil)
    @scraped_event = scraped_event
    @import_service = EventImportService.new
    @errors = []
    @user = user
  end

  # Importer un seul scraped_event validé
  def import!
    unless scraped_event.status == 'validated'
      @errors << "Le scraped_event doit être validé avant import (statut actuel: #{scraped_event.status})"
      return false
    end

    unless scraped_event.json_data.present?
      @errors << "json_data manquant"
      return false
    end

    # Tenter l'import via EventImportService
    success = @import_service.import_from_json(scraped_event.json_data)

    if success && @import_service.imported_events.any?
      # Récupérer l'événement importé
      imported_event = @import_service.imported_events.first

      # Marquer le scraped_event comme importé avec le user
      scraped_event.mark_as_imported!(imported_event, nil, @user)

      true
    else
      # Récupérer les erreurs de l'import service
      error_parts = []

      if @import_service.errors.any?
        error_parts << @import_service.errors.join(', ')
      end

      if @import_service.skipped_events.any?
        skipped_details = @import_service.skipped_events.map do |s|
          "Skipped: #{s[:reason]}"
        end
        error_parts << skipped_details.join(', ')
      end

      error_message = error_parts.any? ? error_parts.join(' | ') : "Import échoué sans détails"
      @errors << error_message

      # Marquer l'échec d'import
      scraped_event.mark_as_imported!(nil, error_message)

      false
    end
  rescue => e
    error_message = "Erreur lors de l'import : #{e.message}"
    @errors << error_message
    scraped_event.mark_as_imported!(nil, error_message)
    false
  end

  # Importer plusieurs scraped_events en batch
  def self.import_batch!(scraped_events, user = nil)
    results = {
      success: [],
      failed: [],
      skipped: []
    }

    scraped_events.each do |scraped_event|
      service = new(scraped_event, user)

      if scraped_event.status != 'validated'
        results[:skipped] << {
          scraped_event: scraped_event,
          reason: "Statut invalide : #{scraped_event.status}"
        }
        next
      end

      if service.import!
        results[:success] << scraped_event
      else
        results[:failed] << {
          scraped_event: scraped_event,
          errors: service.errors
        }
      end
    end

    results
  end

  # Importer tous les scraped_events validés en attente
  def self.import_all_validated!(user = nil)
    validated_events = ScrapedEvent.validated.where(imported_event_id: nil)
    import_batch!(validated_events, user)
  end
end

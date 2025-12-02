# Gestionnaire d'erreur personnalisé pour les actions Avo
Rails.application.config.to_prepare do
  # Étendre le controller Avo pour capturer AvoActionError
  Avo::ActionsController.class_eval do
    rescue_from AvoActionError do |exception|
      # Rediriger vers une page d'erreur dédiée avec les paramètres
      redirect_to Rails.application.routes.url_helpers.avo_error_path(
        title: exception.title,
        details: exception.details,
        hint: exception.hint,
        back_url: request.referer || Rails.application.routes.url_helpers.avo.resources_scraped_events_path
      )
    end
  end
end

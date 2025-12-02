require_relative "boot"
require "rails/all"
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0
    
    # Configuration de la langue par défaut
    config.i18n.default_locale = :fr
    config.i18n.available_locales = [:fr, :en]
    
    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # Configuration pour Tailwind CSS avec Propshaft
    config.assets.paths << Rails.root.join("app/assets/builds")
    
    # S'assurer que le dossier tailwind n'est pas exclu
    config.assets.excluded_paths = config.assets.excluded_paths.reject do |path|
      path.to_s.include?("tailwind")
    end
    
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end
    config.active_storage.service = :cloudinary
    # 👉 Configuration Postmark
    config.action_mailer.delivery_method = :postmark
    config.action_mailer.postmark_settings = {
      api_token: ENV["POSTMARK_API_TOKEN"],
      message_stream: "outbound"
    }
    config.action_mailer.default_url_options = {
      host: ENV.fetch("RAILS_HOST", "localhost:3000"),
      protocol: "https"
    }
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
    # 👉 Configuration des URLs par défaut pour Devise (reset password, etc.)
    Rails.application.routes.default_url_options[:host] = ENV.fetch("RAILS_HOST", "localhost:3000")

    # version dynamique de build (timestamp ISO court)
    config.x.build_version = Time.now.utc.strftime('%Y%m%d%H%M%S')

  end
end

# Ajouter le dossier builds aux assets paths
Rails.application.config.assets.paths << Rails.root.join("app/assets/builds")

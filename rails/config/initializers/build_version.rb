# Version de build utilisée par le manifest et le service worker.
# Priorité :
# 1. BUILD_VERSION si défini (CI/CD)
# 2. Git commit SHA (dev et prod)
# 3. Timestamp UTC (fallback si pas de git)

Rails.configuration.x.build_version = 
  if ENV['BUILD_VERSION'].present?
    ENV['BUILD_VERSION']
  else
    begin
      # Récupérer le SHA du dernier commit (court, 7 caractères)
      git_sha = `git rev-parse --short HEAD 2>/dev/null`.strip
      git_sha.present? ? git_sha : Time.now.utc.strftime('%Y%m%d%H%M%S')
    rescue
      Time.now.utc.strftime('%Y%m%d%H%M%S')
    end
  end

Rails.logger.info "[PWA] Build version: #{Rails.configuration.x.build_version}"

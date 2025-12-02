class Avo::Resources::TeacherUrl < Avo::BaseResource
  self.includes = [:teacher]

  self.index_query = -> {
    # Tri par défaut : nom du teacher (A → Z)
    query.joins(:teacher).order("teachers.first_name ASC, teachers.last_name ASC")
  }

  def filters
    filter Avo::Filters::TeacherUrlScrapingStatus
    filter Avo::Filters::TeacherUrlSort
    filter Avo::Filters::TeacherUrlTeacherName
  end

  def actions
    action Avo::Actions::ScrapeTeacherUrl
  end

  def fields
    field :id, as: :id
    field :teacher, as: :belongs_to, display: :full_name
    field :teacher_name, as: :text, readonly: true do
      record.teacher&.full_name
    end
    field :url, as: :text
    field :name, as: :text
    field :site_type, as: :select,
      options: {
        "Site personnel (mono-teacher)" => "mono_teacher",
        "Site collectif (multi-teacher)" => "multi_teacher"
      },
      default: "mono_teacher",
      help: "mono_teacher = owner par défaut, multi_teacher = teacher vide si non trouvé"
    field :last_scraped_at, as: :date_time
    field :start_scraping_at, as: :date_time, readonly: true, help: "Début du dernier scraping"
    field :end_scraping_at, as: :date_time, readonly: true, help: "Fin du dernier scraping"
    field :last_scraping_duration, as: :number, readonly: true, help: "Durée en secondes" do
      if record.last_scraping_duration
        "#{record.last_scraping_duration}s"
      else
        "-"
      end
    end
    field :last_scraping_status, as: :text, readonly: true, help: "Résultat du dernier scraping" do
      case record.last_scraping_status
      when 'OK'
        '✅ OK'
      when 'BAD_URL'
        '❌ BAD_URL'
      when 'SSL_ERROR'
        '❌ SSL_ERROR'
      when 'HTTP_ERROR'
        '❌ HTTP_ERROR'
      when 'HTTP_REDIRECT'
        '❌ HTTP_REDIRECT'
      when 'HTTP_UNAUTHORIZED'
        '❌ HTTP_UNAUTHORIZED'
      when 'HTTP_FORBIDDEN'
        '❌ HTTP_FORBIDDEN'
      when 'HTTP_SERVER_ERROR'
        '❌ HTTP_SERVER_ERROR'
      when 'DNS_ERROR'
        '❌ DNS_ERROR'
      when 'TIMEOUT_ERROR'
        '❌ TIMEOUT_ERROR'
      when 'CONNECTION_REFUSED'
        '❌ CONNECTION_REFUSED'
      when 'CONNECTION_RESET'
        '❌ CONNECTION_RESET'
      when 'NETWORK_ERROR'
        '❌ NETWORK_ERROR'
      when 'EXTRACTION_ERROR'
        '❌ EXTRACTION_ERROR'
      when 'EXCEPTION'
        '❌ EXCEPTION'
      when 'LOW_DATES'
        '❌ LOW_DATES'
      when 'NO_EVENTS'
        '⚠️ NO_EVENTS'
      when 'UNKNOWN_ERROR'
        '❓ UNKNOWN_ERROR'
      when nil
        '-'
      else
        record.last_scraping_status
      end
    end
    field :last_scraping_error_details, as: :textarea, readonly: true, help: "Détails de la dernière erreur" do
      record.last_scraping_error_details || '-'
    end
    field :interval_days, as: :number, help: "Intervalle en jours entre chaque scraping automatique"
    field :is_active, as: :boolean
    field :scraping_config, as: :code, help: "Configuration avancée (JSONB)", hide_on: [:edit, :new]
    field :events, as: :has_many
  end
end
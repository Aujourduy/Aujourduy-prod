class Avo::Resources::ScrapedEvent < Avo::BaseResource
  self.includes = [:teacher_url]

  self.index_query = -> {
    # Tri par défaut : date d'événement décroissant (plus récent d'abord)
    # Les événements sans date sont placés à la fin
    # Utilise order() et non reorder() pour que les filtres puissent l'override
    query.order(Arel.sql("json_data -> 'event' ->> 'start_date' DESC NULLS LAST"))
  }

  def filters
    filter Avo::Filters::ScrapedEventSort
    filter Avo::Filters::ScrapedEventTeacherName
    filter Avo::Filters::ScrapedEventTitle
    filter Avo::Filters::ScrapedEventPractice
    filter Avo::Filters::ScrapedEventStatus
    filter Avo::Filters::ScrapedEventQualityIssues
  end

  def actions
    action Avo::Actions::CheckScrapedEventQuality
    action Avo::Actions::ValidateScrapedEvent
    action Avo::Actions::RejectScrapedEvent
    action Avo::Actions::ImportScrapedEvent
    action Avo::Actions::ImportAllValidatedScrapedEvents
    action Avo::Actions::ResetScrapedEventToPending
    action Avo::Actions::DeleteScrapedEvents
  end

  def fields
    field :id, as: :id, hide_on: :index

    # Statut et qualité (toujours visible)
    field :status, as: :badge, filterable: true

    field :quality_status, as: :text

    # Infos extraites du JSON (affichées en colonnes sur l'index)
    field :event_title, as: :text, name: "Titre"
    field :event_dates, as: :text, name: "Dates"
    field :event_times, as: :text, name: "Horaires", hide_on: :index
    field :event_practice, as: :text, name: "Practice"
    field :teacher_name, as: :text, name: "Professeur"
    field :event_price, as: :text, name: "Prix", hide_on: :index

    # Infos venue (affichées en colonnes sur l'index)
    field :venue_name, as: :text, name: "📍 Lieu"
    field :venue_address, as: :text, name: "Adresse", hide_on: :index
    field :venue_city, as: :text, name: "Ville"
    field :venue_department, as: :text, name: "Département"
    field :venue_region, as: :text, name: "Région"
    field :venue_country, as: :text, name: "Pays", hide_on: :index

    field :teacher_url, as: :belongs_to, hide_on: :index

    # Champs techniques (cachés sur index, visibles sur show)
    field :source_url, as: :text, hide_on: :index
    field :scraped_at, as: :date_time, hide_on: :index
    field :created_at, as: :date_time, hide_on: :index

    # Description complète (show only)
    field :event_description, as: :textarea, name: "Description", hide_on: :index

    # Lieu complet (show only)
    field :venue_details, as: :textarea, name: "Lieu complet", hide_on: :index

    # === CHAMPS ÉDITABLES (edit only) ===

    # Événement
    field :edit_event_title, as: :text, name: "✏️ Titre", only_on: :edit
    field :edit_event_description, as: :textarea, name: "Description", only_on: :edit
    field :edit_event_practice, as: :text, name: "Practice", only_on: :edit
    field :edit_event_start_date, as: :text, name: "Date début", only_on: :edit, help: "Format: YYYY-MM-DD"
    field :edit_event_end_date, as: :text, name: "Date fin", only_on: :edit, help: "Format: YYYY-MM-DD"
    field :edit_event_start_time, as: :text, name: "Heure début", only_on: :edit, help: "Format: HH:MM"
    field :edit_event_end_time, as: :text, name: "Heure fin", only_on: :edit, help: "Format: HH:MM"
    field :edit_event_price_normal, as: :number, name: "Prix normal", only_on: :edit
    field :edit_event_price_reduced, as: :number, name: "Prix réduit", only_on: :edit
    field :edit_event_currency, as: :select, name: "Devise", only_on: :edit,
          enum: { 'EUR' => 'EUR', 'USD' => 'USD', 'CAD' => 'CAD', 'CHF' => 'CHF' }
    field :edit_event_source_url, as: :text, name: "URL source", only_on: :edit

    # Teacher
    field :edit_teacher_first_name, as: :text, name: "👤 Teacher - Prénom", only_on: :edit
    field :edit_teacher_last_name, as: :text, name: "Teacher - Nom", only_on: :edit

    # Venue
    field :edit_venue_name, as: :text, name: "📍 Lieu - Nom", only_on: :edit
    field :edit_venue_address_line1, as: :text, name: "Lieu - Adresse 1", only_on: :edit
    field :edit_venue_address_line2, as: :text, name: "Lieu - Adresse 2", only_on: :edit
    field :edit_venue_postal_code, as: :text, name: "Lieu - Code postal", only_on: :edit
    field :edit_venue_city, as: :text, name: "Lieu - Ville", only_on: :edit
    field :edit_venue_department_code, as: :text, name: "Lieu - Code département", only_on: :edit
    field :edit_venue_department_name, as: :text, name: "Lieu - Nom département", only_on: :edit
    field :edit_venue_region, as: :text, name: "Lieu - Région", only_on: :edit
    field :edit_venue_country, as: :text, name: "Lieu - Pays", only_on: :edit

    # Données brutes (show only)
    field :json_data, as: :code, language: :json, hide_on: [:index, :edit, :new]
    field :html_content, as: :textarea, hide_on: [:index, :edit, :new]
    field :quality_flags, as: :code, language: :json, hide_on: [:index, :edit, :new]

    # Validation
    field :validation_notes, as: :textarea, hide_on: :index
    field :validated_by_user, as: :belongs_to, hide_on: :index
    field :validated_at, as: :date_time, hide_on: :index

    # Import
    field :imported_event, as: :belongs_to, hide_on: :index
    field :imported_by_user, as: :belongs_to, hide_on: :index
    field :imported_at, as: :date_time, hide_on: :index
    field :import_error, as: :textarea, hide_on: :index
  end
end

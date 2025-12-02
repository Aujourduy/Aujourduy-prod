class EventOccurrence < ApplicationRecord
  include SearchableEventOccurrences

  belongs_to :event
  belongs_to :venue, optional: true
  has_and_belongs_to_many :teachers, join_table: 'event_occurrence_teachers'

  # Attribut pour skipper la validation de date passée (lors de l'import avec force_validation)
  attr_accessor :skip_past_date_validation

  # Validations
  validates :start_date, presence: true
  validates :start_time, :end_time, presence: false
  validates :status, inclusion: { in: %w[active cancelled modified] }
  validates :override_source_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "doit être une URL valide" }, allow_blank: true
  validate :end_time_after_start_time
  validate :start_date_not_in_past, on: :create, unless: :skip_past_date_validation
  validate :end_date_after_start_date
  validate :override_prices_valid, if: :has_price_override?
  validate :venue_or_online_required
  
  # Callback pour définir end_date par défaut
  before_validation :set_default_end_date, on: :create

  # Callback pour normaliser les titres
  before_save :normalize_override_title

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :upcoming, -> { where('start_date >= ?', Date.current) }
  scope :past, -> { where('end_date < ?', Date.current) }
  scope :in_date_range, ->(start_date, end_date) { where('start_date <= ? AND end_date >= ?', end_date, start_date) }
  scope :this_week, -> { where('start_date <= ? AND end_date >= ?', Date.current.end_of_week, Date.current.beginning_of_week) }
  scope :this_month, -> { where('start_date <= ? AND end_date >= ?', Date.current.end_of_month, Date.current.beginning_of_month) }
  scope :by_recurrence, ->(recurrence_id) { where(recurrence_id: recurrence_id) }
  
  # Enum pour faciliter les requêtes
  enum :status, { active: 'active', cancelled: 'cancelled', modified: 'modified' }
  
  # === GESTION DES OVERRIDES (SURCHARGES) ===
  
  # Titre effectif (override ou depuis l'Event master)
  def effective_title
    override_title.presence || event.title
  end
  
  # Description effective
  def effective_description
    override_description.presence || event.description
  end
  
  # Prix normal effectif
  def effective_price_normal
    override_price_normal.presence || event.price_normal
  end
  
  # Prix réduit effectif
  def effective_price_reduced
    override_price_reduced.presence || event.price_reduced
  end
  
  # Devise effective
  def effective_currency
    override_currency.presence || event.currency
  end
  
  # URL de source effective
  def effective_source_url
    override_source_url.presence || event.source_url
  end
  
  # Vérifie si l'occurrence a des overrides de prix
  def has_price_override?
    override_price_normal.present? || override_price_reduced.present? || override_currency.present?
  end
  
  # Vérifie si l'occurrence a des overrides
  def has_any_override?
    is_override? || has_price_override? || override_title.present? || override_description.present? || override_source_url.present?
  end
  
  # === GESTION DES TEACHERS ===
  
  # Teachers effectifs (remplaçants + principal de l'Event si pas de remplaçants)
  def effective_teachers
    if teachers.any?
      teachers
    elsif event.principal_teacher
      Teacher.where(id: event.principal_teacher_id)
    else
      Teacher.none
    end
  end
  
  # Nom des teachers pour affichage
  def teachers_names
    effective_teachers.pluck(:first_name, :last_name).map { |f, l| "#{f} #{l}" }.join(', ')
  end
  
  # Teacher principal effectif
  def principal_teacher
    teachers.first || event.principal_teacher
  end
  
  # === MÉTHODES DE MODIFICATION ===
  
  # Modifie seulement cette occurrence
  def update_this_occurrence(attributes)
    # Marquer comme override mais GARDER status: 'active'
    if attributes.keys.intersect?(%w[override_title override_description override_price_normal override_price_reduced override_currency override_source_url])
      attributes[:is_override] = true
    end
    
    update(attributes)
  end
  
  # Annule seulement cette occurrence
  def cancel_this_occurrence
    update(status: 'cancelled')
  end
  
  # === MÉTHODES D'AFFICHAGE ===
  
  # Prix formatés avec devise
  def formatted_price_normal
    format_price(effective_price_normal, effective_currency)
  end
  
  def formatted_price_reduced
    format_price(effective_price_reduced, effective_currency)
  end
  
  # Date formatée (affiche la période si multi-jours)
  def formatted_date
    if multi_day?
      "#{start_date.strftime('%d %B')} au #{end_date.strftime('%d %B %Y')}"
    else
      start_date.strftime('%A %d %B %Y')
    end
  end
  
  def formatted_time_range
    return "Horaires à confirmer" unless start_time && end_time
    "#{start_time.strftime('%H:%M')} - #{end_time.strftime('%H:%M')}"
  end

  def formatted_datetime
    if start_time && end_time
      "#{formatted_date} de #{formatted_time_range}"
    else
      "#{formatted_date} (horaires à confirmer)"
    end
  end
  
  # Statut pour affichage
  def status_badge_class
    case status
    when 'active' then is_override? ? 'badge badge-warning' : 'badge badge-success'
    when 'cancelled' then 'badge badge-error'
    when 'modified' then 'badge badge-warning'
    else 'badge badge-neutral'
    end
  end
  
  # Vérifie si l'événement dure plusieurs jours
  def multi_day?
    end_date.present? && end_date > start_date
  end
  
  # Nombre de jours de l'événement
  def duration_days
    return 1 unless end_date.present?
    (end_date - start_date).to_i + 1
  end
  
  # Vérifie si l'occurrence est dans le futur
  def upcoming?
    start_date >= Date.current
  end
  
  # Vérifie si l'occurrence est aujourd'hui
  def today?
    Date.current.between?(start_date, end_date || start_date)
  end
  
  # Vérifie si l'occurrence est en cours
  def ongoing?
    end_date.present? && Date.current.between?(start_date, end_date)
  end
  
  private
  
  def set_default_end_date
    self.end_date ||= start_date if start_date.present?
  end

  def normalize_override_title
    self.override_title = override_title.titleize if override_title.present?
  end

  def end_time_after_start_time
    return unless start_time && end_time
    # Cette validation ne s'applique que pour les événements d'un seul jour
    return if multi_day?
    
    if end_time <= start_time
      errors.add(:end_time, 'doit être après l\'heure de début')
    end
  end
  
  def start_date_not_in_past
    return unless start_date
    
    if start_date < Date.current
      errors.add(:start_date, 'ne peut pas être dans le passé')
    end
  end
  
  def end_date_after_start_date
    return unless start_date && end_date
    
    if end_date < start_date
      errors.add(:end_date, 'doit être après ou égale à la date de début')
    end
  end
  
  def override_prices_valid
    # Les prix sont optionnels, mais si présents doivent être cohérents
    if override_price_normal.present? && override_price_reduced.present?
      if override_price_normal > 0 && override_price_reduced > 0
        if override_price_reduced >= override_price_normal
          errors.add(:override_price_reduced, 'doit être inférieur au prix normal')
        end
      end
    end

    if override_currency.present? && !%w[EUR USD CAD CHF].include?(override_currency)
      errors.add(:override_currency, 'devise non supportée')
    end
  end
  
  def format_price(price, currency)
    return 'NC' unless price && price > 0

    symbol = case currency
             when 'EUR' then '€'
             when 'USD' then '$'
             when 'CAD' then 'CA$'
             when 'CHF' then 'CHF'
             else currency
             end

    "#{price.to_i} #{symbol}"
  end

  def venue_or_online_required
    return if venue.present?
    return if event&.is_online?
    
    errors.add(:base, "Un lieu est requis pour les événements en personne")
  end
end

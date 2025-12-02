class Event < ApplicationRecord
  belongs_to :user
  belongs_to :principal_teacher, class_name: 'Teacher', optional: true
  belongs_to :practice
  belongs_to :teacher_url, optional: true
  
  has_many :event_occurrences, dependent: :destroy
  has_many :venues, through: :event_occurrences
  
  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :price_normal, :price_reduced, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :currency, inclusion: { in: %w[EUR USD CAD CHF] }, allow_blank: true
  validates :status, inclusion: { in: %w[active cancelled draft] }
  validates :practice, presence: true
  validates :source_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "doit être une URL valide" }
  validates :online_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "doit être une URL valide" }, if: :is_online?
  
  # Validations conditionnelles pour la récurrence
  validates :recurrence_rule, presence: true, if: :is_recurring?
  validates :recurrence_end_date, presence: true, if: :is_recurring?
  validate :recurrence_end_date_after_start, if: :is_recurring?
  validate :valid_recurrence_rule, if: :is_recurring?

  # Validation prix réduit < prix normal (si les deux existent)
  validate :price_reduced_less_than_normal

  # Callbacks
  before_save :normalize_title

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :recurring, -> { where(is_recurring: true) }
  scope :single, -> { where(is_recurring: false) }
  scope :scraped, -> { where.not(teacher_url_id: nil) }
  scope :manual, -> { where(teacher_url_id: nil) }
  scope :online, -> { where(is_online: true) }
  
  # Enum pour faciliter les requêtes
  enum :status, { active: 'active', cancelled: 'cancelled', draft: 'draft' }
  
  # === GESTION DE LA RÉCURRENCE ===
  
  # Parse la règle de récurrence JSON
  def recurrence_settings
    return {} unless recurrence_rule.present?
    JSON.parse(recurrence_rule).with_indifferent_access
  rescue JSON::ParserError
    {}
  end
  
  # Met à jour la règle de récurrence
  def recurrence_settings=(settings)
    self.recurrence_rule = settings.to_json
  end
  
  # Créer une occurrence unique (événement non récurrent)
  def create_single_occurrence!(venue, start_date, start_time, end_time, end_date = nil)
    event_occurrences.create!(
      venue: venue,
      start_date: start_date,
      end_date: end_date || start_date,
      start_time: start_time,
      end_time: end_time,
      recurrence_id: SecureRandom.uuid
    )
  end
  
  # === MÉTHODES D'AFFICHAGE ===
  
  # Prix formaté avec devise
  def formatted_price_normal
    format_price(price_normal)
  end
  
  def formatted_price_reduced
    format_price(price_reduced)
  end
  
  # Nom du teacher principal
  def principal_teacher_name
    principal_teacher&.full_name || 'Non défini'
  end
  
  # Nom de la pratique
  def practice_name
    practice&.name || 'Non défini'
  end
  
  # Est-ce un événement scrapé ?
  def scraped?
    teacher_url_id.present?
  end
  
  # Source de l'événement (manuel ou scrapé)
  def source_type
    scraped? ? "Scrapé depuis #{teacher_url.display_name}" : "Créé manuellement"
  end
  
  # Prochaines occurrences actives
  def upcoming_occurrences(limit = 5)
    event_occurrences
      .active
      .where('start_date >= ?', Date.current)
      .includes(:venue)
      .order(:start_date, :start_time)
      .limit(limit)
  end
  
  # Nombre total d'occurrences
  def occurrences_count
    event_occurrences.count
  end
  
  # Est-ce que l'événement a des occurrences futures ?
  def has_upcoming_occurrences?
    event_occurrences.where('start_date >= ?', Date.current).exists?
  end
  
  private
  
  def recurrence_end_date_after_start
    return unless recurrence_end_date.present?
    
    first_occurrence = event_occurrences.order(:start_date).first
    if first_occurrence && recurrence_end_date < first_occurrence.start_date
      errors.add(:recurrence_end_date, 'doit être après la date de la première occurrence')
    end
  end
  
  def valid_recurrence_rule
    return unless recurrence_rule.present?

    settings = recurrence_settings
    required_keys = %w[frequency interval]

    missing_keys = required_keys - settings.keys
    if missing_keys.any?
      errors.add(:recurrence_rule, "manque les clés: #{missing_keys.join(', ')}")
    end

    unless %w[daily weekly monthly].include?(settings['frequency'])
      errors.add(:recurrence_rule, "fréquence doit être 'daily', 'weekly' ou 'monthly'")
    end

    interval = settings['interval'].to_i
    if interval < 1 || interval > 52
      errors.add(:recurrence_rule, "intervalle doit être entre 1 et 52")
    end
  end

  def price_reduced_less_than_normal
    return unless price_normal.present? && price_reduced.present?
    return if price_normal == 0 && price_reduced == 0 # Les deux sont NC

    if price_reduced >= price_normal
      errors.add(:price_reduced, "doit être inférieur au prix normal")
    end
  end

  def format_price(price)
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

  def normalize_title
    self.title = title.titleize if title.present?
  end
end

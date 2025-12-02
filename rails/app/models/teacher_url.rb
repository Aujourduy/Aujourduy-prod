class TeacherUrl < ApplicationRecord
  belongs_to :teacher
  has_many :events, dependent: :nullify

  # Exposer les champs depuis le JSONB scraping_config
  store_accessor :scraping_config, :interval_days, :site_type

  # S'assurer que scraping_config est toujours un Hash et non une String
  before_save :ensure_scraping_config_is_hash

  def ensure_scraping_config_is_hash
    if scraping_config.is_a?(String)
      begin
        parsed = JSON.parse(scraping_config.gsub('=>', ':'))
        self.scraping_config = parsed
      rescue JSON::ParserError
        self.scraping_config = {}
      end
    elsif scraping_config.nil?
      self.scraping_config = {}
    end
  end

  # Validations
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "doit être une URL valide" }
  validates :url, uniqueness: { scope: :teacher_id, message: "existe déjà pour ce professeur" }
  validates :name, length: { maximum: 255 }
  
  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :recently_scraped, -> { where('last_scraped_at > ?', 1.day.ago) }
  scope :needs_scraping, -> { where('last_scraped_at IS NULL OR last_scraped_at < ?', 1.day.ago) }
  
  # Méthodes utiles
  def display_name
    name.presence || url
  end

  def mark_as_scraped!
    update!(last_scraped_at: Time.current)
  end

  def days_since_scraping
    return nil unless last_scraped_at
    ((Time.current - last_scraped_at) / 1.day).to_i
  end
end

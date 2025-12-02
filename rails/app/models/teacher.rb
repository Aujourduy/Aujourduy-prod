class Teacher < ApplicationRecord
  include SearchableTeachers
  belongs_to :user
  has_and_belongs_to_many :event_occurrences, join_table: 'event_occurrence_teachers', dependent: :destroy
  # Association avec Practice
  has_and_belongs_to_many :practices, join_table: 'teacher_practices', dependent: :destroy
  # Association avec TeacherUrls (URLs de scraping)
  has_many :teacher_urls, dependent: :destroy
  accepts_nested_attributes_for :teacher_urls, allow_destroy: true, reject_if: :all_blank
  
  # Association pour les events où ce teacher est principal
  has_many :principal_events, class_name: 'Event', foreign_key: 'principal_teacher_id', dependent: :nullify
  
  # Validations
  validates :user, presence: true
  validates :first_name, :last_name, presence: true
  validates :contact_email, uniqueness: { case_sensitive: false, message: "est déjà utilisé par un autre professeur" }, allow_blank: true
  validates :reference_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "doit être une URL valide" }, allow_blank: true
  # ⚠️ Supprimé : validation d'unicité sur (first_name, last_name)
  validate :must_have_at_least_one_practice, on: :update
  # Callbacks
  before_save :normalize_names
  before_validation :normalize_names_for_validation
  # === Méthode pour gérer les photos via Cloudinary ===
  def photo_url(size = :medium, options = {})
    return photo_cloudinary_url(size, options) if photo_cloudinary_id.present?
    return attributes['photo_url'] if attributes['photo_url'].present? # Fallback sur l'ancien champ
    nil
  end
  
  # Méthode pour afficher le nom complet
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  # Méthode pour afficher le nom avec email ou ID (pour éviter les doublons dans Avo)
  def display_name
    if contact_email.present?
      "#{full_name} (#{contact_email})"
    else
      "#{full_name} (##{id})"
    end
  end
  
  # Liste des noms de pratiques
  def practice_names
    practices.pluck(:name).join(', ')
  end
  
  # URLs actives pour le scraping
  def active_scraping_urls
    teacher_urls.active
  end
  
  # URLs qui ont besoin d'être scrapées
  def urls_needing_scraping
    teacher_urls.active.needs_scraping
  end

  # Récupérer les occurrences futures où ce teacher apparaît
  # (soit comme principal_teacher, soit comme teacher d'une occurrence)
  def upcoming_event_occurrences
    EventOccurrence
      .joins(:event)
      .left_joins(:teachers)
      .where('event_occurrences.start_date >= ?', Date.today)
      .where('events.principal_teacher_id = ? OR teachers.id = ?', id, id)
      .distinct
      .order('event_occurrences.start_date ASC, event_occurrences.start_time ASC')
  end

  private
  
  def normalize_names
    self.first_name = normalize_name(first_name) if first_name.present?
    self.last_name = normalize_name(last_name) if last_name.present?
  end
  
  def normalize_names_for_validation
    normalize_names
  end
  
  def normalize_name(name)
    # Capitaliser chaque mot tout en préservant les tirets et apostrophes
    # On remplace chaque mot (séquence de lettres) par sa version capitalisée
    name.strip.gsub(/\b[a-zà-ÿ]+/i) { |word| word.capitalize }
  end
  
  def photo_cloudinary_url(size = :medium, options = {})
    require "cloudinary"
    sizes = {
      mini:   { width: 32,  height: 32 },   # ex: liste
      medium: { width: 96,  height: 96 },   # ex: carte professeur
      large:  { width: 200, height: 200 }   # ex: page détaillée
    }
    base_options = {
      crop: :fill,
      gravity: :face,
      secure: true
    }
    Cloudinary::Utils.cloudinary_url(
      photo_cloudinary_id,
      base_options.merge(sizes[size] || sizes[:medium]).merge(options)
    )
  end
  
  def must_have_at_least_one_practice
    if practices.empty? && practice_ids.empty?
      errors.add(:practices, "doit avoir au moins une pratique")
    end
  end
end
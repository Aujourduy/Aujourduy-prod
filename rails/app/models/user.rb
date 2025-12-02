class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]
  
  has_many :teachers, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :venues, dependent: :destroy
  has_many :practices, dependent: :destroy
  
  validates :phone, presence: true, uniqueness: true, phone: true, allow_blank: true
  validate :cities_must_exist
  validate :countries_must_exist
  validate :teachers_must_exist
  validate :practices_must_exist
  validates :filter_mode, inclusion: { in: %w[union intersection] }, allow_nil: true
  validates :password, presence: true, on: :create, if: :password_required?
  
  after_create :create_default_teacher
  before_save :normalize_favorites
  before_save :normalize_names
  before_validation :clean_favorites
  
  def phone_verified?
    phone_validated_at.present?
  end
  
  def normalized_phone
    parsed = Phonelib.parse(phone)
    parsed.e164.presence || phone
  end
  
  def increment_verification_attempts!
    increment!(:phone_verification_attempts)
  end
  
  def reset_verification_attempts!
    update!(phone_verification_attempts: 0)
  end
  
  def mark_phone_as_verified!
    update!(phone_validated_at: Time.current, phone_verification_attempts: 0)
  end
  
  def can_request_new_code?
    phone_verification_last_sent_at.nil? || phone_verification_last_sent_at < 1.minute.ago
  end
  
  def mark_code_sent!
    update!(phone_verification_last_sent_at: Time.current)
  end
  
  def avatar_url(size = :medium, options = {})
    return google_avatar_url if google_avatar_url.present? && avatar_cloudinary_id.blank?
    return nil unless avatar_cloudinary_id.present?
    require "cloudinary"
    sizes = {
      mini: { width: 32, height: 32 },
      medium: { width: 96, height: 96 },
      large: { width: 200, height: 200 }
    }
    base_options = { crop: :fill, gravity: :face, secure: true }
    Cloudinary::Utils.cloudinary_url(
      avatar_cloudinary_id,
      base_options.merge(sizes[size] || sizes[:medium]).merge(options)
    )
  end
  
  def self.from_google(auth)
    where(google_uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      user.google_uid = auth.uid
      user.google_avatar_url = auth.info.image
      user.password = Devise.friendly_token[0, 20]
    end
  end
  
  def admin?
    is_admin
  end
  
  def favorite_occurrences
    return EventOccurrence.none unless has_favorites?
    if filter_mode == "intersection"
      apply_intersection_filter
    else
      apply_union_filter
    end
  end
  
  def toggle_filter_mode!
    new_mode = filter_mode == "union" ? "intersection" : "union"
    update!(filter_mode: new_mode)
  end
  
  def has_favorites?
    favorite_cities.any? || favorite_countries.any? || favorite_teacher_ids.any? || favorite_practice_ids.any? || search_keywords.present?
  end
  
  def self.available_cities
    Venue.distinct.pluck(:city).compact.sort
  end
  
  def self.available_countries
    Venue.distinct.pluck(:country).compact.sort
  end
  
  private
  
  def password_required?
    google_uid.blank? && encrypted_password.blank?
  end
  
  def normalize_names
    self.first_name = first_name.strip.titleize if first_name.present?
    self.last_name = last_name.strip.titleize if last_name.present?
  end
  
  def create_default_teacher
    return if teachers.exists?
    teachers.create!(
      first_name: first_name.presence || "Nom",
      last_name: last_name.presence || "Prénom",
      contact_email: email,
      photo_url: google_avatar_url || avatar_url(:medium)
    )
  end
  
  def cities_must_exist
    return if favorite_cities.blank?
    invalid = favorite_cities - self.class.available_cities
    errors.add(:favorite_cities, "contient des villes invalides: #{invalid.join(', ')}") if invalid.any?
  end
  
  def countries_must_exist
    return if favorite_countries.blank?
    invalid = favorite_countries - self.class.available_countries
    errors.add(:favorite_countries, "contient des pays invalides: #{invalid.join(', ')}") if invalid.any?
  end
  
  def teachers_must_exist
    return if favorite_teacher_ids.blank?
    existing_ids = Teacher.where(id: favorite_teacher_ids).pluck(:id)
    invalid = favorite_teacher_ids - existing_ids
    errors.add(:favorite_teacher_ids, "contient des professeurs invalides: #{invalid.join(', ')}") if invalid.any?
  end
  
  def practices_must_exist
    return if favorite_practice_ids.blank?
    existing_ids = Practice.where(id: favorite_practice_ids).pluck(:id)
    invalid = favorite_practice_ids - existing_ids
    errors.add(:favorite_practice_ids, "contient des pratiques invalides: #{invalid.join(', ')}") if invalid.any?
  end
  
  def normalize_favorites
    self.favorite_cities ||= []
    self.favorite_countries ||= []
    self.favorite_teacher_ids ||= []
    self.favorite_practice_ids ||= []
    self.search_keywords = search_keywords&.strip
    self.filter_mode ||= "union"
  end

  def clean_favorites
    self.favorite_cities = favorite_cities.reject(&:blank?) if favorite_cities
    self.favorite_countries = favorite_countries.reject(&:blank?) if favorite_countries
    self.favorite_teacher_ids = favorite_teacher_ids.reject(&:blank?) if favorite_teacher_ids
    self.favorite_practice_ids = favorite_practice_ids.reject(&:blank?) if favorite_practice_ids
  end
  
  def apply_union_filter
    query = EventOccurrence.left_joins(:venue, :teachers, event: :practice).distinct
    conditions = []
    conditions << "venues.city IN (:cities)" if favorite_cities.any?
    conditions << "venues.country IN (:countries)" if favorite_countries.any?
    conditions << "teachers.id IN (:teacher_ids)" if favorite_teacher_ids.any?
    conditions << "practices.id IN (:practice_ids)" if favorite_practice_ids.any?
    
    if conditions.any?
      query = query.where(
        conditions.join(" OR "),
        cities: favorite_cities,
        countries: favorite_countries,
        teacher_ids: favorite_teacher_ids,
        practice_ids: favorite_practice_ids
      )
    end
    
    apply_keywords_filter(query)
  end
  
  def apply_intersection_filter
    query = EventOccurrence.left_joins(:venue, :teachers, event: :practice).distinct
    query = query.where(venues: { city: favorite_cities }) if favorite_cities.any?
    query = query.where(venues: { country: favorite_countries }) if favorite_countries.any?
    query = query.where(teachers: { id: favorite_teacher_ids }) if favorite_teacher_ids.any?
    query = query.where(practices: { id: favorite_practice_ids }) if favorite_practice_ids.any?
    apply_keywords_filter(query)
  end
  
  def apply_keywords_filter(query)
    return query if search_keywords.blank?
    keywords = search_keywords.split(/\s+/).map(&:strip).reject(&:blank?)
    keywords.each do |keyword|
      sanitized = ActiveRecord::Base.sanitize_sql_like(keyword)
      query = query.where("events.title ILIKE :kw OR events.description ILIKE :kw", kw: "%#{sanitized}%")
    end
    query
  end
end

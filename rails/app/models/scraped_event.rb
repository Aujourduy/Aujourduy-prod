class ScrapedEvent < ApplicationRecord
  # Relations
  belongs_to :teacher_url, optional: true
  belongs_to :validated_by_user, class_name: 'User', foreign_key: 'validated_by_user_id', optional: true
  belongs_to :imported_by_user, class_name: 'User', foreign_key: 'imported_by_user_id', optional: true
  belongs_to :imported_event, class_name: 'Event', foreign_key: 'imported_event_id', optional: true

  # Validations
  validates :source_url, presence: true
  validates :scraped_at, presence: true
  validates :json_data, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending validated rejected imported] }

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :validated, -> { where(status: 'validated') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :imported, -> { where(status: 'imported') }
  scope :recent, -> { order(scraped_at: :desc) }
  scope :by_teacher_url, ->(teacher_url_id) { where(teacher_url_id: teacher_url_id) }

  # Callbacks
  before_validation :set_scraped_at, on: :create
  before_save :normalize_title_in_json

  # Méthodes d'instance
  def validate!(user, notes = nil)
    update!(
      status: 'validated',
      validated_by_user: user,
      validated_at: Time.current,
      validation_notes: notes
    )
  end

  def reject!(user, notes)
    update!(
      status: 'rejected',
      validated_by_user: user,
      validated_at: Time.current,
      validation_notes: notes
    )
  end

  def mark_as_imported!(event, error = nil, user = nil)
    if error
      update!(
        status: 'pending',
        import_error: error
      )
    else
      update!(
        status: 'imported',
        imported_event: event,
        imported_at: Time.current,
        imported_by_user: user,
        import_error: nil
      )
    end
  end

  def teacher_name
    return '-' unless json_data.is_a?(Hash) && json_data['teacher'].present?
    first = json_data.dig('teacher', 'first_name')
    last = json_data.dig('teacher', 'last_name')
    [first, last].compact.join(' ').presence || '-'
  end

  def event_title
    return '-' unless json_data.is_a?(Hash)
    json_data.dig('event', 'title') || '-'
  end

  def event_date
    return nil unless json_data.is_a?(Hash)
    json_data.dig('event', 'start_date')
  end

  def event_dates
    return '-' unless json_data.is_a?(Hash)
    start_date = json_data.dig('event', 'start_date')
    end_date = json_data.dig('event', 'end_date')

    if start_date
      end_date && end_date != start_date ? "#{start_date} → #{end_date}" : start_date
    else
      '-'
    end
  end

  def event_times
    return '-' unless json_data.is_a?(Hash)
    start_time = json_data.dig('event', 'start_time')
    end_time = json_data.dig('event', 'end_time')

    if start_time && end_time
      "#{start_time} - #{end_time}"
    elsif start_time
      start_time
    else
      '-'
    end
  end

  def event_practice
    return '-' unless json_data.is_a?(Hash)
    json_data.dig('event', 'practice') || '-'
  end

  def event_city
    return '-' unless json_data.is_a?(Hash)
    json_data.dig('venue', 'city') || '-'
  end

  def venue_name
    return '-' unless json_data.is_a?(Hash)
    json_data.dig('venue', 'name') || '-'
  end

  def venue_address
    return '-' unless json_data.is_a?(Hash)
    json_data.dig('venue', 'address_line1') || '-'
  end

  def venue_city
    return '-' unless json_data.is_a?(Hash)
    json_data.dig('venue', 'city') || '-'
  end

  def venue_department
    return '-' unless json_data.is_a?(Hash)
    code = json_data.dig('venue', 'department_code')
    name = json_data.dig('venue', 'department_name')

    if code.present? && name.present?
      "#{code} - #{name}"
    elsif name.present?
      name
    elsif code.present?
      code
    else
      '-'
    end
  end

  def venue_region
    return '-' unless json_data.is_a?(Hash)
    json_data.dig('venue', 'region') || '-'
  end

  def venue_country
    return '-' unless json_data.is_a?(Hash)
    json_data.dig('venue', 'country') || '-'
  end

  def event_price
    return '-' unless json_data.is_a?(Hash)
    price_normal = json_data.dig('event', 'price_normal')
    price_reduced = json_data.dig('event', 'price_reduced')
    currency = json_data.dig('event', 'currency') || 'EUR'

    if price_normal && price_normal > 0
      reduced_str = price_reduced && price_reduced > 0 ? " (réduit: #{price_reduced})" : ""
      "#{price_normal} #{currency}#{reduced_str}"
    else
      '-'
    end
  end

  def event_description
    return '-' unless json_data.is_a?(Hash)
    json_data.dig('event', 'description') || '-'
  end

  def venue_details
    return '-' unless json_data.is_a?(Hash)
    venue = json_data.dig('venue') || {}
    [
      venue['name'],
      venue['address_line1'],
      [venue['postal_code'], venue['city']].compact.join(' '),
      venue['country']
    ].compact.join("\n")
  end

  def quality_status
    flags = quality_flags || {}
    errors = flags['errors'] || []
    warnings = flags['warnings'] || []

    if errors.any?
      "❌ #{errors.length} erreur(s)"
    elsif warnings.any?
      "⚠️ #{warnings.length} avertissement(s)"
    else
      "✅ Parfait"
    end
  end

  def has_quality_issues?
    quality_flags.present? && quality_flags.any?
  end

  def quality_issues_list
    return [] unless has_quality_issues?
    quality_flags.keys
  end

  # === Virtual attributes pour éditer le JSON ===

  # Event
  def edit_event_title
    return nil unless json_data.is_a?(Hash)
    json_data.dig('event', 'title')
  end

  def edit_event_title=(value)
    return unless json_data.is_a?(Hash)
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['event'] ||= {}
    self.json_data['event']['title'] = value if value.present?
  end

  def edit_event_description
    return nil unless json_data.is_a?(Hash)
    json_data.dig('event', 'description')
  end

  def edit_event_description=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['event'] ||= {}
    self.json_data['event']['description'] = value
  end

  def edit_event_practice
    return nil unless json_data.is_a?(Hash)
    json_data.dig('event', 'practice')
  end

  def edit_event_practice=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['event'] ||= {}
    self.json_data['event']['practice'] = value
  end

  def edit_event_start_date
    return nil unless json_data.is_a?(Hash)
    json_data.dig('event', 'start_date')
  end

  def edit_event_start_date=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['event'] ||= {}
    self.json_data['event']['start_date'] = value.to_s
  end

  def edit_event_end_date
    return nil unless json_data.is_a?(Hash)
    json_data.dig('event', 'end_date')
  end

  def edit_event_end_date=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['event'] ||= {}
    self.json_data['event']['end_date'] = value.to_s
  end

  def edit_event_start_time
    return nil unless json_data.is_a?(Hash)
    json_data.dig('event', 'start_time')
  end

  def edit_event_start_time=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['event'] ||= {}
    self.json_data['event']['start_time'] = value
  end

  def edit_event_end_time
    return nil unless json_data.is_a?(Hash)
    json_data.dig('event', 'end_time')
  end

  def edit_event_end_time=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['event'] ||= {}
    self.json_data['event']['end_time'] = value
  end

  def edit_event_price_normal
    return nil unless json_data.is_a?(Hash)
    json_data.dig('event', 'price_normal')
  end

  def edit_event_price_normal=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['event'] ||= {}
    self.json_data['event']['price_normal'] = value.to_f
  end

  def edit_event_price_reduced
    return nil unless json_data.is_a?(Hash)
    json_data.dig('event', 'price_reduced')
  end

  def edit_event_price_reduced=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['event'] ||= {}
    self.json_data['event']['price_reduced'] = value.to_f
  end

  def edit_event_currency
    return nil unless json_data.is_a?(Hash)
    json_data.dig('event', 'currency')
  end

  def edit_event_currency=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['event'] ||= {}
    self.json_data['event']['currency'] = value
  end

  def edit_event_source_url
    return nil unless json_data.is_a?(Hash)
    json_data.dig('event', 'source_url')
  end

  def edit_event_source_url=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['event'] ||= {}
    self.json_data['event']['source_url'] = value
  end

  # Teacher
  def edit_teacher_first_name
    return nil unless json_data.is_a?(Hash)
    json_data.dig('teacher', 'first_name')
  end

  def edit_teacher_first_name=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['teacher'] ||= {}
    self.json_data['teacher']['first_name'] = value
  end

  def edit_teacher_last_name
    return nil unless json_data.is_a?(Hash)
    json_data.dig('teacher', 'last_name')
  end

  def edit_teacher_last_name=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['teacher'] ||= {}
    self.json_data['teacher']['last_name'] = value
  end

  # Venue
  def edit_venue_name
    return nil unless json_data.is_a?(Hash)
    json_data.dig('venue', 'name')
  end

  def edit_venue_name=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['venue'] ||= {}
    self.json_data['venue']['name'] = value
  end

  def edit_venue_address_line1
    return nil unless json_data.is_a?(Hash)
    json_data.dig('venue', 'address_line1')
  end

  def edit_venue_address_line1=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['venue'] ||= {}
    self.json_data['venue']['address_line1'] = value
  end

  def edit_venue_address_line2
    return nil unless json_data.is_a?(Hash)
    json_data.dig('venue', 'address_line2')
  end

  def edit_venue_address_line2=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['venue'] ||= {}
    self.json_data['venue']['address_line2'] = value
  end

  def edit_venue_postal_code
    return nil unless json_data.is_a?(Hash)
    json_data.dig('venue', 'postal_code')
  end

  def edit_venue_postal_code=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['venue'] ||= {}
    self.json_data['venue']['postal_code'] = value
  end

  def edit_venue_city
    return nil unless json_data.is_a?(Hash)
    json_data.dig('venue', 'city')
  end

  def edit_venue_city=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['venue'] ||= {}
    self.json_data['venue']['city'] = value
  end

  def edit_venue_region
    return nil unless json_data.is_a?(Hash)
    json_data.dig('venue', 'region')
  end

  def edit_venue_region=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['venue'] ||= {}
    self.json_data['venue']['region'] = value
  end

  def edit_venue_country
    return nil unless json_data.is_a?(Hash)
    json_data.dig('venue', 'country')
  end

  def edit_venue_country=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['venue'] ||= {}
    self.json_data['venue']['country'] = value
  end

  def edit_venue_department_code
    return nil unless json_data.is_a?(Hash)
    json_data.dig('venue', 'department_code')
  end

  def edit_venue_department_code=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['venue'] ||= {}
    self.json_data['venue']['department_code'] = value
  end

  def edit_venue_department_name
    return nil unless json_data.is_a?(Hash)
    json_data.dig('venue', 'department_name')
  end

  def edit_venue_department_name=(value)
    return unless json_data.is_a?(Hash) && value.present?
    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['venue'] ||= {}
    self.json_data['venue']['department_name'] = value
  end

  private

  def set_scraped_at
    self.scraped_at ||= Time.current
  end

  def normalize_title_in_json
    return unless json_data.is_a?(Hash)
    title = json_data.dig('event', 'title')
    return unless title.present?

    normalized_title = title.titleize
    return if title == normalized_title

    self.json_data = json_data.dup if json_data.frozen?
    self.json_data['event'] ||= {}
    self.json_data['event']['title'] = normalized_title
  end
end

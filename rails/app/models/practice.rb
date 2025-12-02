class Practice < ApplicationRecord
  # Associations
  belongs_to :user
  has_and_belongs_to_many :teachers, join_table: 'teacher_practices'
  has_many :events, dependent: :restrict_with_error
  
  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :name, length: { maximum: 100 }
  validates :user, presence: true
  
  # Callbacks
  before_save :normalize_name
  
  # Scopes
  scope :ordered_by_name, -> { order(:name) }
  
  # Méthodes
  def teachers_count
    teachers.count
  end
  
  def events_count
    events.count
  end
  
  def to_s
    name
  end
  
  private
  
  def normalize_name
    self.name = name.strip.titleize if name.present?
  end
end

class Venue < ApplicationRecord
  belongs_to :user
  has_many :event_occurrences, dependent: :destroy
  has_many :events, through: :event_occurrences

  # Départements français (code => nom)
  FRENCH_DEPARTMENTS = {
    '01' => 'Ain', '02' => 'Aisne', '03' => 'Allier', '04' => 'Alpes-de-Haute-Provence',
    '05' => 'Hautes-Alpes', '06' => 'Alpes-Maritimes', '07' => 'Ardèche', '08' => 'Ardennes',
    '09' => 'Ariège', '10' => 'Aube', '11' => 'Aude', '12' => 'Aveyron',
    '13' => 'Bouches-du-Rhône', '14' => 'Calvados', '15' => 'Cantal', '16' => 'Charente',
    '17' => 'Charente-Maritime', '18' => 'Cher', '19' => 'Corrèze', '2A' => 'Corse-du-Sud',
    '2B' => 'Haute-Corse', '21' => 'Côte-d\'Or', '22' => 'Côtes-d\'Armor', '23' => 'Creuse',
    '24' => 'Dordogne', '25' => 'Doubs', '26' => 'Drôme', '27' => 'Eure',
    '28' => 'Eure-et-Loir', '29' => 'Finistère', '30' => 'Gard', '31' => 'Haute-Garonne',
    '32' => 'Gers', '33' => 'Gironde', '34' => 'Hérault', '35' => 'Ille-et-Vilaine',
    '36' => 'Indre', '37' => 'Indre-et-Loire', '38' => 'Isère', '39' => 'Jura',
    '40' => 'Landes', '41' => 'Loir-et-Cher', '42' => 'Loire', '43' => 'Haute-Loire',
    '44' => 'Loire-Atlantique', '45' => 'Loiret', '46' => 'Lot', '47' => 'Lot-et-Garonne',
    '48' => 'Lozère', '49' => 'Maine-et-Loire', '50' => 'Manche', '51' => 'Marne',
    '52' => 'Haute-Marne', '53' => 'Mayenne', '54' => 'Meurthe-et-Moselle', '55' => 'Meuse',
    '56' => 'Morbihan', '57' => 'Moselle', '58' => 'Nièvre', '59' => 'Nord',
    '60' => 'Oise', '61' => 'Orne', '62' => 'Pas-de-Calais', '63' => 'Puy-de-Dôme',
    '64' => 'Pyrénées-Atlantiques', '65' => 'Hautes-Pyrénées', '66' => 'Pyrénées-Orientales', '67' => 'Bas-Rhin',
    '68' => 'Haut-Rhin', '69' => 'Rhône', '70' => 'Haute-Saône', '71' => 'Saône-et-Loire',
    '72' => 'Sarthe', '73' => 'Savoie', '74' => 'Haute-Savoie', '75' => 'Paris',
    '76' => 'Seine-Maritime', '77' => 'Seine-et-Marne', '78' => 'Yvelines', '79' => 'Deux-Sèvres',
    '80' => 'Somme', '81' => 'Tarn', '82' => 'Tarn-et-Garonne', '83' => 'Var',
    '84' => 'Vaucluse', '85' => 'Vendée', '86' => 'Vienne', '87' => 'Haute-Vienne',
    '88' => 'Vosges', '89' => 'Yonne', '90' => 'Territoire de Belfort', '91' => 'Essonne',
    '92' => 'Hauts-de-Seine', '93' => 'Seine-Saint-Denis', '94' => 'Val-de-Marne', '95' => 'Val-d\'Oise',
    '971' => 'Guadeloupe', '972' => 'Martinique', '973' => 'Guyane', '974' => 'La Réunion',
    '976' => 'Mayotte'
  }.freeze

  validates :name, presence: true, length: { maximum: 100 }
  validates :address_line1, presence: false
  validates :city, presence: false
  validates :postal_code, presence: false
  validates :country, presence: true
  validates :latitude, :longitude, numericality: true, allow_blank: true

  # Callbacks
  before_save :normalize_name
  before_save :deduce_department
  
  scope :by_city, ->(city) { where("city ILIKE ?", "%#{city}%") if city.present? }
  scope :by_country, ->(country) { where("country ILIKE ?", "%#{country}%") if country.present? }
  
  def full_address
    parts = []
    parts << address_line1 if address_line1.present?
    parts << address_line2 if address_line2.present?

    # Gérer ville et code postal (peuvent être absents)
    city_postal = [postal_code, city].compact.reject(&:blank?).join(" ")
    parts << city_postal if city_postal.present?

    parts << region if region.present?
    parts << country if country.present?

    parts.join(", ")
  end
  
  def coordinates?
    latitude.present? && longitude.present?
  end
  
  private

  def normalize_name
    self.name = name.strip.titleize if name.present?
  end

  def deduce_department
    # Auto-déduction uniquement pour la France
    return unless country&.downcase&.include?('france')
    return unless postal_code.present?

    # Extraire le code département du code postal
    code = extract_department_code(postal_code)
    return unless code && FRENCH_DEPARTMENTS.key?(code)

    # Mettre à jour seulement si vides (ne pas écraser une saisie manuelle)
    self.department_code ||= code
    self.department_name ||= FRENCH_DEPARTMENTS[code]
  end

  def extract_department_code(postal_code)
    # Supprimer espaces et normaliser
    clean_code = postal_code.to_s.strip.gsub(/\s+/, '')

    # DOM-TOM (3 chiffres : 971, 972, 973, 974, 976)
    return clean_code[0..2] if clean_code.match?(/^97[1-6]/)

    # Corse (2A, 2B)
    return '2A' if clean_code.match?(/^200/)
    return '2B' if clean_code.match?(/^20[12]/)

    # Métropole (2 premiers chiffres)
    clean_code[0..1] if clean_code.match?(/^\d{5}/)
  end
end

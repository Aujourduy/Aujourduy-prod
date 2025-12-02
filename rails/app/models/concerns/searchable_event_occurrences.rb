module SearchableEventOccurrences
  extend ActiveSupport::Concern

  included do
    # Recherche avec logique ET (intersection)
    # Chaque mot-clé doit être présent quelque part dans les champs
    scope :search_by_keywords, ->(query) {
      return all if query.blank?

      # Nettoyer et splitter la query en mots individuels
      keywords = query.strip.downcase.split(/\s+/).reject(&:blank?)
      return all if keywords.empty?

      # Construire les jointures nécessaires
      relation = includes(:event, :venue, event: [:principal_teacher, :practice])
                  .joins(:event, :venue)
                  .joins("LEFT OUTER JOIN teachers AS event_teachers ON events.principal_teacher_id = event_teachers.id")
                  .joins("LEFT OUTER JOIN practices ON events.practice_id = practices.id")
                  .joins("LEFT OUTER JOIN event_occurrence_teachers ON event_occurrence_teachers.event_occurrence_id = event_occurrences.id")
                  .joins("LEFT OUTER JOIN teachers ON teachers.id = event_occurrence_teachers.teacher_id")

      # Pour chaque mot-clé, créer une condition OR sur tous les champs
      # Puis combiner tous les mots-clés avec AND
      keywords.each do |keyword|
        sanitized = "%#{ActiveRecord::Base.sanitize_sql_like(keyword)}%"
        
        relation = relation.where(
          "LOWER(events.title) LIKE ? OR
           LOWER(events.description) LIKE ? OR
           LOWER(event_occurrences.override_title) LIKE ? OR
           LOWER(event_occurrences.override_description) LIKE ? OR
           LOWER(venues.name) LIKE ? OR
           LOWER(venues.city) LIKE ? OR
           LOWER(venues.country) LIKE ? OR
           LOWER(venues.address_line1) LIKE ? OR
           LOWER(venues.address_line2) LIKE ? OR
           LOWER(venues.region) LIKE ? OR
           LOWER(venues.postal_code) LIKE ? OR
           LOWER(practices.name) LIKE ? OR
           LOWER(CONCAT(event_teachers.first_name, ' ', event_teachers.last_name)) LIKE ? OR
           LOWER(CONCAT(teachers.first_name, ' ', teachers.last_name)) LIKE ?",
          sanitized, sanitized, sanitized, sanitized,
          sanitized, sanitized, sanitized, sanitized, sanitized, sanitized, sanitized,
          sanitized, sanitized, sanitized
        )
      end

      # Utiliser DISTINCT pour éviter les doublons dus aux jointures multiples
      relation.distinct
    }
  end
end

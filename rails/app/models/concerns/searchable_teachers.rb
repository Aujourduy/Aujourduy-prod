module SearchableTeachers
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
      relation = includes(:practices)
                  .joins("LEFT OUTER JOIN teacher_practices ON teacher_practices.teacher_id = teachers.id")
                  .joins("LEFT OUTER JOIN practices ON practices.id = teacher_practices.practice_id")

      # Pour chaque mot-clé, créer une condition OR sur tous les champs
      # Puis combiner tous les mots-clés avec AND
      keywords.each do |keyword|
        sanitized = "%#{ActiveRecord::Base.sanitize_sql_like(keyword)}%"

        relation = relation.where(
          "LOWER(teachers.first_name) LIKE ? OR
           LOWER(teachers.last_name) LIKE ? OR
           LOWER(CONCAT(teachers.first_name, ' ', teachers.last_name)) LIKE ? OR
           LOWER(teachers.bio) LIKE ? OR
           LOWER(practices.name) LIKE ?",
          sanitized, sanitized, sanitized, sanitized, sanitized
        )
      end

      # Utiliser DISTINCT pour éviter les doublons dus aux jointures multiples
      relation.distinct
    }
  end
end

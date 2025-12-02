class NormalizeEventTitles < ActiveRecord::Migration[8.0]
  def up
    # Normaliser les titres des événements (Event.title)
    Event.find_each do |event|
      normalized_title = event.title.titleize
      next if event.title == normalized_title

      event.update_column(:title, normalized_title)
      puts "Event ##{event.id}: '#{event.title}' → '#{normalized_title}'"
    end

    # Normaliser les override_title des occurrences (EventOccurrence.override_title)
    EventOccurrence.where.not(override_title: nil).find_each do |occurrence|
      normalized_title = occurrence.override_title.titleize
      next if occurrence.override_title == normalized_title

      occurrence.update_column(:override_title, normalized_title)
      puts "EventOccurrence ##{occurrence.id}: '#{occurrence.override_title}' → '#{normalized_title}'"
    end

    puts "\n✅ Normalisation des titres terminée"
  end

  def down
    # Pas de rollback possible (on ne peut pas retrouver la casse originale)
    puts "⚠️ Rollback non supporté pour cette migration (transformation irréversible)"
  end
end

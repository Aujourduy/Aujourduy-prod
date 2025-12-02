class Avo::Filters::EventSort < Avo::Filters::SelectFilter
  self.name = "Trier par"

  def apply(request, query, value)
    return query if value.blank?

    case value
    when "date_asc"
      query.reorder(Arel.sql("(SELECT MIN(event_occurrences.start_date) FROM event_occurrences WHERE event_occurrences.event_id = events.id) ASC NULLS LAST"))
    when "date_desc"
      query.reorder(Arel.sql("(SELECT MIN(event_occurrences.start_date) FROM event_occurrences WHERE event_occurrences.event_id = events.id) DESC NULLS LAST"))
    when "title_asc"
      query.reorder("events.title ASC")
    when "title_desc"
      query.reorder("events.title DESC")
    when "created_asc"
      query.reorder("events.created_at ASC")
    when "created_desc"
      query.reorder("events.created_at DESC")
    else
      query
    end
  end

  def options
    {
      "date_desc" => "📅 Date début ⬇️ (plus récent)",
      "date_asc" => "📅 Date début ⬆️ (plus ancien)",
      "title_asc" => "📝 Titre ⬆️ (A → Z)",
      "title_desc" => "📝 Titre ⬇️ (Z → A)",
      "created_desc" => "🆕 Créé ⬇️ (plus récent)",
      "created_asc" => "🆕 Créé ⬆️ (plus ancien)"
    }
  end

  def default
    "date_desc"
  end
end

class Avo::Filters::ScrapedEventSort < Avo::Filters::SelectFilter
  self.name = "Trier par"

  def apply(request, query, value)
    return query if value.blank?

    case value
    when "reset"
      # Réinitialiser : retourner à l'ordre par défaut
      query.reorder(Arel.sql("json_data -> 'event' ->> 'start_date' DESC NULLS LAST"))
    when "date_asc"
      query.reorder(Arel.sql("json_data -> 'event' ->> 'start_date' ASC NULLS LAST"))
    when "date_desc"
      query.reorder(Arel.sql("json_data -> 'event' ->> 'start_date' DESC NULLS LAST"))
    when "title_asc"
      query.reorder(Arel.sql("json_data -> 'event' ->> 'title' ASC NULLS LAST"))
    when "title_desc"
      query.reorder(Arel.sql("json_data -> 'event' ->> 'title' DESC NULLS LAST"))
    else
      query
    end
  end

  def options
    # En Ruby, les Hash maintiennent l'ordre d'insertion depuis Ruby 1.9
    # L'ordre ici sera préservé dans l'affichage
    {
      "reset" => "🔄 Réinitialiser les filtres",
      "date_asc" => "📅 Date début ⬆️ (croissant)",
      "date_desc" => "📅 Date début ⬇️ (décroissant)",
      "title_asc" => "📝 Titre ⬆️ (A → Z)",
      "title_desc" => "📝 Titre ⬇️ (Z → A)"
    }
  end

  def default
    "date_desc"
  end
end

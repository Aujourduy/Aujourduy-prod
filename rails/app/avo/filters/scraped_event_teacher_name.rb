class Avo::Filters::ScrapedEventTeacherName < Avo::Filters::TextFilter
  self.name = "Nom du teacher"
  self.button_label = "Filtrer par teacher"

  def apply(request, query, value)
    return query if value.blank?

    query.where(
      "json_data->'teacher'->>'first_name' ILIKE ? OR json_data->'teacher'->>'last_name' ILIKE ?",
      "%#{value}%",
      "%#{value}%"
    )
  end
end

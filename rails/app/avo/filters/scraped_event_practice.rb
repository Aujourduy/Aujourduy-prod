class Avo::Filters::ScrapedEventPractice < Avo::Filters::TextFilter
  self.name = "Practice"
  self.button_label = "Filtrer par practice"

  def apply(request, query, value)
    return query if value.blank?

    query.where("json_data->'event'->>'practice' ILIKE ?", "%#{value}%")
  end
end

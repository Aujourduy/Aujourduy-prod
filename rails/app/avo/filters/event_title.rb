class Avo::Filters::EventTitle < Avo::Filters::TextFilter
  self.name = "Titre événement"
  self.button_label = "Filtrer par titre"

  def apply(request, query, value)
    return query if value.blank?

    query.where("events.title ILIKE ?", "%#{value}%")
  end
end

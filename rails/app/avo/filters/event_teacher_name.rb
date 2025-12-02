class Avo::Filters::EventTeacherName < Avo::Filters::TextFilter
  self.name = "Nom du teacher principal"
  self.button_label = "Filtrer par teacher"

  def apply(request, query, value)
    return query if value.blank?

    query.joins(:principal_teacher)
         .where(
           "teachers.first_name ILIKE ? OR teachers.last_name ILIKE ?",
           "%#{value}%",
           "%#{value}%"
         )
  end
end

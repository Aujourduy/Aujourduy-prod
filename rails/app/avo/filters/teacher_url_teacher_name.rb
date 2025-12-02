class Avo::Filters::TeacherUrlTeacherName < Avo::Filters::TextFilter
  self.name = "Nom du teacher"
  self.button_label = "Filtrer par teacher"

  def apply(request, query, value)
    return query if value.blank?

    query.joins(:teacher)
         .where(
           "teachers.first_name ILIKE ? OR teachers.last_name ILIKE ?",
           "%#{value}%",
           "%#{value}%"
         )
  end
end

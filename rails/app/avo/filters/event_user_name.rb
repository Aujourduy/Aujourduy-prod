class Avo::Filters::EventUserName < Avo::Filters::TextFilter
  self.name = "Nom de l'utilisateur"
  self.button_label = "Filtrer par utilisateur"

  def apply(request, query, value)
    return query if value.blank?

    query.joins(:user)
         .where(
           "users.first_name ILIKE ? OR users.last_name ILIKE ? OR users.email ILIKE ?",
           "%#{value}%",
           "%#{value}%",
           "%#{value}%"
         )
  end
end

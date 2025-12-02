class Avo::Resources::Venue < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :name, as: :text
    field :address_line1, as: :text
    field :address_line2, as: :text
    field :postal_code, as: :text
    field :city, as: :text
    field :department_code, as: :text, help: "Auto-déduit du code postal (France uniquement)"
    field :department_name, as: :text, help: "Auto-déduit du code postal (France uniquement)"
    field :region, as: :text
    field :country, as: :country
    field :latitude, as: :number
    field :longitude, as: :number
    field :user_id, as: :text
    field :user, as: :belongs_to
    field :event_occurrences, as: :has_many
    field :events, as: :has_many, through: :event_occurrences
  end
end

class Avo::Resources::Practice < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :name, as: :text
    field :description, as: :textarea
    field :user_id, as: :text
    field :user, as: :belongs_to
    field :teachers, as: :has_and_belongs_to_many
    field :events, as: :has_many
  end
end

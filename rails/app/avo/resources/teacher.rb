class Avo::Resources::Teacher < Avo::BaseResource
  self.title = :display_name
  
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :first_name, as: :text
    field :last_name, as: :text
    field :bio, as: :textarea
    field :contact_email, as: :text
    field :phone, as: :text
    field :photo_url, as: :text
    field :user_id, as: :text
    field :photo_cloudinary_id, as: :text
    field :reference_url, as: :text
    field :user, as: :belongs_to
    field :event_occurrences, as: :has_and_belongs_to_many
    field :practices, as: :has_and_belongs_to_many
    field :teacher_urls, as: :has_many
    field :principal_events, as: :has_many
  end
end
class Avo::Resources::User < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :email, as: :text
    field :sign_in_count, as: :number
    field :current_sign_in_at, as: :date_time
    field :last_sign_in_at, as: :date_time
    field :current_sign_in_ip, as: :text
    field :last_sign_in_ip, as: :text
    field :phone, as: :text
    field :phone_validated_at, as: :date_time
    field :country_code, as: :text
    field :google_uid, as: :text
    field :google_email, as: :text
    field :google_avatar_url, as: :text
    field :avatar_cloudinary_id, as: :text
    field :phone_verification_last_sent_at, as: :date_time
    field :phone_verification_attempts, as: :number
    field :first_name, as: :text
    field :last_name, as: :text
    field :is_admin, as: :boolean
    field :favorite_cities, as: :code
    field :favorite_countries, as: :code
    field :favorite_teacher_ids, as: :code
    field :search_keywords, as: :text
    field :filter_mode, as: :text
    field :favorite_practice_ids, as: :text
    field :teachers, as: :has_many
    field :events, as: :has_many
    field :venues, as: :has_many
    field :practices, as: :has_many
  end
end

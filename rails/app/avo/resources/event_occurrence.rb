class Avo::Resources::EventOccurrence < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }
  
  def fields
    field :id, as: :id
    field :event_id, as: :text
    field :venue_id, as: :text
    field :start_date, as: :date
    field :start_time, as: :date_time
    field :end_time, as: :date_time
    field :override_title, as: :text
    field :override_description, as: :textarea
    field :override_price_normal, as: :number
    field :override_price_reduced, as: :number
    field :override_currency, as: :text
    field :status, as: :select, enum: ::EventOccurrence.statuses
    field :is_override, as: :boolean
    field :recurrence_id, as: :text
    field :override_source_url, as: :text
    field :end_date, as: :date
    field :event, as: :belongs_to
    field :venue, as: :belongs_to
    field :teachers, as: :has_and_belongs_to_many
  end
end

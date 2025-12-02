class Avo::Resources::Event < Avo::BaseResource
  self.includes = [:user, :principal_teacher, :practice, :event_occurrences]

  self.index_query = -> {
    # Tri par défaut : utilise order() et non reorder() pour que les filtres puissent l'override
    query.order(Arel.sql("(SELECT MIN(event_occurrences.start_date) FROM event_occurrences WHERE event_occurrences.event_id = events.id) DESC NULLS LAST"))
  }

  def filters
    filter Avo::Filters::EventSort
    filter Avo::Filters::EventTitle
    filter Avo::Filters::EventTeacherName
    filter Avo::Filters::EventUserName
  end

  def actions
    action Avo::Actions::DeleteEvents
  end

  def fields
    field :id, as: :id
    field :first_occurrence_date, as: :text, hide_on: [:edit, :new] do
      record.event_occurrences.order(:start_date).first&.start_date&.strftime("%d/%m/%Y") || "Aucune occurrence"
    end
    field :principal_teacher_name, as: :text, hide_on: [:edit, :new] do
      record.principal_teacher_name
    end
    field :user_full_name, as: :text, hide_on: [:edit, :new] do
      "#{record.user.first_name} #{record.user.last_name}".strip
    end
    field :title, as: :text
    field :user_id, as: :text
    field :description, as: :textarea
    field :price_normal, as: :number
    field :price_reduced, as: :number
    field :currency, as: :text
    field :recurrence_rule, as: :textarea
    field :recurrence_end_date, as: :date
    field :is_recurring, as: :boolean
    field :principal_teacher_id, as: :text
    field :status, as: :select, enum: ::Event.statuses
    field :practice_id, as: :text
    field :source_url, as: :text
    field :teacher_url_id, as: :text
    field :is_online, as: :boolean
    field :online_url, as: :text
    field :user, as: :belongs_to
    field :principal_teacher, as: :belongs_to
    field :practice, as: :belongs_to
    field :teacher_url, as: :belongs_to
    field :event_occurrences, as: :has_many
    field :venues, as: :has_many, through: :event_occurrences
  end
end

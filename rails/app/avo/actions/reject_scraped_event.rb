class Avo::Actions::RejectScrapedEvent < Avo::BaseAction
  self.name = "Rejeter"
  self.message = "Rejeter cet événement ?"
  self.may_download_file = false
  self.visible = -> { true }
  self.confirm_button_label = "Rejeter"

  def fields
    field :validation_notes, as: :textarea, required: true, placeholder: "Raison du rejet (obligatoire)"
  end

  def handle(records:, fields:, current_user:, resource:, **args)
    rejected = 0
    notes = fields[:validation_notes]

    if notes.blank?
      error "❌ La raison du rejet est obligatoire."
      return
    end

    records.each do |scraped_event|
      if scraped_event.status == 'pending'
        scraped_event.reject!(current_user, notes)
        rejected += 1
      end
    end

    succeed "✅ #{rejected} événement(s) rejeté(s)."
  end
end

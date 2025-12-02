class AddPracticeToEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :events, :practice, null: false, foreign_key: true, type: :uuid
  end
end

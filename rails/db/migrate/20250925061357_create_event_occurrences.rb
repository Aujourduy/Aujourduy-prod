class CreateEventOccurrences < ActiveRecord::Migration[8.0]
  def change
    create_table :event_occurrences, id: :uuid do |t|
      t.references :event, null: false, foreign_key: true, type: :uuid
      t.references :venue, null: false, foreign_key: true, type: :uuid
      t.date :date
      t.time :start_time
      t.time :end_time

      t.timestamps
    end
  end
end

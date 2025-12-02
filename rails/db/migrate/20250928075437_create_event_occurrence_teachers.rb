class CreateEventOccurrenceTeachers < ActiveRecord::Migration[8.0]
  def change
    create_table :event_occurrence_teachers, id: :uuid do |t|
      t.references :event_occurrence, null: false, foreign_key: true, type: :uuid
      t.references :teacher, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :event_occurrence_teachers,
              [:event_occurrence_id, :teacher_id],
              unique: true,
              name: "index_event_occurrence_teachers_on_occurrence_and_teacher"
  end
end

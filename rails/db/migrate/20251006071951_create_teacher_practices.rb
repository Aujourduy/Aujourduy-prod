class CreateTeacherPractices < ActiveRecord::Migration[8.0]
  def change
    create_table :teacher_practices, id: :uuid do |t|
      t.references :teacher, null: false, foreign_key: true, type: :uuid
      t.references :practice, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :teacher_practices, [:teacher_id, :practice_id], unique: true
  end
end

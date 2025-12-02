class CreateTeachers < ActiveRecord::Migration[8.0]
  def change
    create_table :teachers, id: :uuid do |t|
      t.string :first_name
      t.string :last_name
      t.text :bio
      t.string :contact_email
      t.string :phone
      t.string :photo_url
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end

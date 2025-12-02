class CreatePractices < ActiveRecord::Migration[8.0]
  def change
    create_table :practices, id: :uuid do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end

    add_index :practices, :name, unique: true
  end
end

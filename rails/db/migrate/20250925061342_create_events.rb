class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :title
      t.text :description
      t.decimal :price_normal
      t.decimal :price_reduced
      t.string :currency

      t.timestamps
    end
  end
end

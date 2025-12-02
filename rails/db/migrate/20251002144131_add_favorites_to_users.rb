class AddFavoritesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :favorite_cities, :jsonb, default: []
    add_column :users, :favorite_countries, :jsonb, default: []
    add_column :users, :favorite_teacher_ids, :jsonb, default: []
    add_column :users, :search_keywords, :string
    add_column :users, :filter_mode, :string, default: "union"
  end
end

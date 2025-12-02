class AddFavoritePracticeIdsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :favorite_practice_ids, :uuid, array: true, default: []
  end
end

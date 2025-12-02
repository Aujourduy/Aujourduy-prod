class AddCloudinaryFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :avatar_cloudinary_id, :string
    rename_column :users, :avatar_url, :google_avatar_url
    
    add_index :users, :avatar_cloudinary_id
  end
end

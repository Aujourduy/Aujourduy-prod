class AddPhotoCloudinaryIdToTeachers < ActiveRecord::Migration[8.0]
  def change
    add_column :teachers, :photo_cloudinary_id, :string
    add_index :teachers, :photo_cloudinary_id
  end
end

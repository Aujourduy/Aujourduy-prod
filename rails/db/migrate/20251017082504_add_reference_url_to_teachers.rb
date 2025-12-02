class AddReferenceUrlToTeachers < ActiveRecord::Migration[8.0]
  def change
    add_column :teachers, :reference_url, :string
  end
end

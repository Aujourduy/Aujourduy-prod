class AddDepartmentToVenues < ActiveRecord::Migration[8.0]
  def change
    add_column :venues, :department_code, :string
    add_column :venues, :department_name, :string
  end
end

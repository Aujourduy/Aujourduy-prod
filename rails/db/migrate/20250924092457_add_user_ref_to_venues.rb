class AddUserRefToVenues < ActiveRecord::Migration[8.0]
  def change
    add_reference :venues, :user, null: false, foreign_key: true, type: :uuid
  end
end

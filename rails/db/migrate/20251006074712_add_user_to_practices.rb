class AddUserToPractices < ActiveRecord::Migration[8.0]
  def change
    add_reference :practices, :user, null: false, foreign_key: true, type: :uuid
  end
end

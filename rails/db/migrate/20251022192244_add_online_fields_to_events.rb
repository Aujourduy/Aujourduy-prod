class AddOnlineFieldsToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :is_online, :boolean, default: false, null: false
    add_column :events, :online_url, :string
  end
end

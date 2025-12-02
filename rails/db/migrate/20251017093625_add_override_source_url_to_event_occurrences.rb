class AddOverrideSourceUrlToEventOccurrences < ActiveRecord::Migration[8.0]
  def change
    add_column :event_occurrences, :override_source_url, :string
  end
end

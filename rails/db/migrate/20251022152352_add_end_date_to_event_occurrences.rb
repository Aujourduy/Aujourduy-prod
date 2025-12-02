class AddEndDateToEventOccurrences < ActiveRecord::Migration[8.0]
  def change
    rename_column :event_occurrences, :date, :start_date
    add_column :event_occurrences, :end_date, :date
  end
end

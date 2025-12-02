class AddImportedByUserToScrapedEvents < ActiveRecord::Migration[8.0]
  def change
    add_reference :scraped_events, :imported_by_user, null: true, foreign_key: { to_table: :users }, type: :uuid
  end
end

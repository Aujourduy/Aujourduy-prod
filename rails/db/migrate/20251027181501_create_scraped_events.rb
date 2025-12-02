class CreateScrapedEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :scraped_events, id: :uuid do |t|
      # Métadonnées scraping
      t.text :source_url, null: false
      t.uuid :teacher_url_id
      t.timestamp :scraped_at, null: false
      t.integer :scraping_duration_ms

      # Données extraites
      t.text :html_content
      t.jsonb :json_data, null: false

      # Statut et validation
      t.string :status, null: false, default: 'pending'
      t.text :validation_notes
      t.uuid :validated_by_user_id
      t.timestamp :validated_at

      # Import
      t.uuid :imported_event_id
      t.timestamp :imported_at
      t.text :import_error

      # Qualité
      t.decimal :confidence_score, precision: 5, scale: 2
      t.jsonb :quality_flags, default: {}

      t.timestamps
    end

    # Index pour performance
    add_index :scraped_events, :status
    add_index :scraped_events, :source_url
    add_index :scraped_events, :teacher_url_id
    add_index :scraped_events, :scraped_at
    add_index :scraped_events, :validated_by_user_id
    add_index :scraped_events, :imported_event_id

    # Foreign keys
    add_foreign_key :scraped_events, :teacher_urls, column: :teacher_url_id, on_delete: :nullify
    add_foreign_key :scraped_events, :users, column: :validated_by_user_id, on_delete: :nullify
    add_foreign_key :scraped_events, :events, column: :imported_event_id, on_delete: :nullify
  end
end

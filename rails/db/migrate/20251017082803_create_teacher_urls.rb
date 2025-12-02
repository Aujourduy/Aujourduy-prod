class CreateTeacherUrls < ActiveRecord::Migration[8.0]
  def change
    create_table :teacher_urls, id: :uuid do |t|
      t.references :teacher, null: false, foreign_key: true, type: :uuid
      t.string :url, null: false
      t.string :name
      t.datetime :last_scraped_at
      t.boolean :is_active, default: true, null: false
      t.jsonb :scraping_config, default: {}
      
      t.timestamps
    end
    
    # Index pour éviter les doublons
    add_index :teacher_urls, [:teacher_id, :url], unique: true
  end
end

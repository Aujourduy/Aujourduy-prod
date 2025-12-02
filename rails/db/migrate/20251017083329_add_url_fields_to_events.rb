class AddUrlFieldsToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :source_url, :string
    add_column :events, :teacher_url_id, :uuid
    
    # Index et foreign key optionnelle
    add_index :events, :teacher_url_id
    add_foreign_key :events, :teacher_urls, column: :teacher_url_id, on_delete: :nullify
  end
end

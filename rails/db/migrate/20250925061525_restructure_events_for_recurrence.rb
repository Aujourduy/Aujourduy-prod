class RestructureEventsForRecurrence < ActiveRecord::Migration[7.0]
  def up
    # 1. Ajout des champs de récurrence à Event (master template)
    add_column :events, :recurrence_rule, :text # JSON pour les règles de récurrence
    add_column :events, :recurrence_end_date, :date
    add_column :events, :is_recurring, :boolean, default: false
    add_column :events, :principal_teacher_id, :uuid
    add_column :events, :status, :string, default: 'active' # active, cancelled, draft
    
    # 2. Ajout des champs d'override à EventOccurrence
    add_column :event_occurrences, :override_title, :string
    add_column :event_occurrences, :override_description, :text
    add_column :event_occurrences, :override_price_normal, :decimal, precision: 8, scale: 2
    add_column :event_occurrences, :override_price_reduced, :decimal, precision: 8, scale: 2
    add_column :event_occurrences, :override_currency, :string
    add_column :event_occurrences, :status, :string, default: 'active' # active, cancelled, modified
    add_column :event_occurrences, :is_override, :boolean, default: false
    add_column :event_occurrences, :recurrence_id, :string # identifiant unique pour la série
    
    # 3. Ajout des index
    add_index :events, :principal_teacher_id
    add_index :events, :is_recurring
    add_index :event_occurrences, :recurrence_id
    add_index :event_occurrences, :is_override
    add_index :event_occurrences, :status
    
    # 4. Ajout des foreign keys
    add_foreign_key :events, :teachers, column: :principal_teacher_id
    
    # 5. Assurer que event_id est présent (si pas déjà fait)
    change_column_null :event_occurrences, :event_id, false unless column_allows_null?(:event_occurrences, :event_id)
  end

  def down
    # Suppression dans l'ordre inverse
    remove_foreign_key :events, :teachers if foreign_key_exists?(:events, :teachers)
    
    remove_index :event_occurrences, :status if index_exists?(:event_occurrences, :status)
    remove_index :event_occurrences, :is_override if index_exists?(:event_occurrences, :is_override)
    remove_index :event_occurrences, :recurrence_id if index_exists?(:event_occurrences, :recurrence_id)
    remove_index :events, :is_recurring if index_exists?(:events, :is_recurring)
    remove_index :events, :principal_teacher_id if index_exists?(:events, :principal_teacher_id)
    
    remove_column :event_occurrences, :recurrence_id
    remove_column :event_occurrences, :is_override
    remove_column :event_occurrences, :status
    remove_column :event_occurrences, :override_currency
    remove_column :event_occurrences, :override_price_reduced
    remove_column :event_occurrences, :override_price_normal
    remove_column :event_occurrences, :override_description
    remove_column :event_occurrences, :override_title
    
    remove_column :events, :status
    remove_column :events, :principal_teacher_id
    remove_column :events, :is_recurring
    remove_column :events, :recurrence_end_date
    remove_column :events, :recurrence_rule
  end

  private
  def column_allows_null?(table, column)
    connection.columns(table).find { |c| c.name == column.to_s }&.null
  end
end

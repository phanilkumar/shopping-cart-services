class AddLockoutFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    # Add lockout fields if they don't exist
    unless column_exists?(:users, :failed_attempts)
      add_column :users, :failed_attempts, :integer, default: 0, null: false
    end
    
    unless column_exists?(:users, :locked_at)
      add_column :users, :locked_at, :datetime
    end
    
    # Add indexes if they don't exist
    unless index_exists?(:users, :locked_at)
      add_index :users, :locked_at
    end
    
    unless index_exists?(:users, :failed_attempts)
      add_index :users, :failed_attempts
    end
  end
end

class AddLockoutFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :locked_at, :datetime
    add_column :users, :lock_expires_at, :datetime
    
    add_index :users, :locked_at
    add_index :users, :lock_expires_at
  end
end

class AddLockoutFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    # Only add lock_expires_at since failed_attempts and locked_at already exist from Devise
    add_column :users, :lock_expires_at, :datetime
    
    add_index :users, :lock_expires_at
  end
end

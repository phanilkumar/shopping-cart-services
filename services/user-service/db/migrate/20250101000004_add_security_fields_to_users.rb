class AddSecurityFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    # Add failed_attempts if it doesn't exist
    unless column_exists?(:users, :failed_attempts)
      add_column :users, :failed_attempts, :integer, default: 0, null: false
    end
    
    # Add locked_at if it doesn't exist
    unless column_exists?(:users, :locked_at)
      add_column :users, :locked_at, :datetime
    end
    
    # Add unlock_token if it doesn't exist
    unless column_exists?(:users, :unlock_token)
      add_column :users, :unlock_token, :string
      add_index :users, :unlock_token, unique: true
    end
    
    # Two-factor authentication fields
    unless column_exists?(:users, :two_factor_secret)
      add_column :users, :two_factor_secret, :string
    end
    
    unless column_exists?(:users, :two_factor_enabled)
      add_column :users, :two_factor_enabled, :boolean, default: false, null: false
    end
    
    # Security tracking fields
    unless column_exists?(:users, :last_sign_in_ip)
      add_column :users, :last_sign_in_ip, :string
    end
    
    unless column_exists?(:users, :current_sign_in_ip)
      add_column :users, :current_sign_in_ip, :string
    end
    
    unless column_exists?(:users, :sign_in_count)
      add_column :users, :sign_in_count, :integer, default: 0, null: false
    end
    
    unless column_exists?(:users, :current_sign_in_at)
      add_column :users, :current_sign_in_at, :datetime
    end
    
    unless column_exists?(:users, :last_sign_in_at)
      add_column :users, :last_sign_in_at, :datetime
    end
    
    # Session timeout
    unless column_exists?(:users, :timeout_in)
      add_column :users, :timeout_in, :integer, default: 30.minutes
    end
    
    # Password security
    unless column_exists?(:users, :password_changed_at)
      add_column :users, :password_changed_at, :datetime
    end
    
    unless column_exists?(:users, :password_expires_at)
      add_column :users, :password_expires_at, :datetime
    end
    
    # Account security
    unless column_exists?(:users, :suspicious_activity_detected_at)
      add_column :users, :suspicious_activity_detected_at, :datetime
    end
    
    unless column_exists?(:users, :security_questions_answered)
      add_column :users, :security_questions_answered, :boolean, default: false
    end
  end
end

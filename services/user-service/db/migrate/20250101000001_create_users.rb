class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      # Basic user information
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.string :phone
      
      # Authentication fields (for basic auth without Devise)
      t.string :password_digest, null: false
      
      # Status and role
      t.integer :status, default: 1  # 1 = active, 0 = inactive
      t.integer :role, default: 0    # 0 = user, 1 = admin
      
      # Timestamps
      t.datetime :last_login_at
      t.timestamps
    end
    
    add_index :users, :email, unique: true
    add_index :users, :phone, unique: true
  end
end





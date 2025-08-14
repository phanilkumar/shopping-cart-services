class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.integer :status
      t.integer :role
      t.datetime :last_login_at
      t.datetime :email_verified_at

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end

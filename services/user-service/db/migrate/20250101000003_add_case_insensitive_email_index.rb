class AddCaseInsensitiveEmailIndex < ActiveRecord::Migration[7.1]
  def change
    # Add a case-insensitive index on email for better performance
    add_index :users, "LOWER(email)", unique: true, name: "index_users_on_lower_email"
  end
end





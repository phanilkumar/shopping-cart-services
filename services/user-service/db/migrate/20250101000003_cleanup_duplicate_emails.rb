class CleanupDuplicateEmails < ActiveRecord::Migration[7.1]
  def up
    # First, remove the existing unique constraint on email
    remove_index :users, :email if index_exists?(:users, :email)
    
    # Normalize all existing emails to lowercase
    execute <<-SQL
      UPDATE users 
      SET email = LOWER(email)
      WHERE email != LOWER(email);
    SQL

    # Remove duplicates, keeping the first occurrence (lowest ID)
    execute <<-SQL
      DELETE FROM users 
      WHERE id NOT IN (
        SELECT MIN(id) 
        FROM users 
        GROUP BY LOWER(email)
      );
    SQL

    # Now add the case-insensitive index
    add_index :users, "LOWER(email)", unique: true, name: "index_users_on_lower_email"
  end

  def down
    remove_index :users, name: "index_users_on_lower_email"
    add_index :users, :email, unique: true
  end
end

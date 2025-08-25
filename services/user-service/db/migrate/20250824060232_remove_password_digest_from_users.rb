class RemovePasswordDigestFromUsers < ActiveRecord::Migration[7.1]
  def up
    # Check if the column exists before trying to remove it
    if column_exists?(:users, :password_digest)
      remove_column :users, :password_digest, :string
    end
  end

  def down
    # Add the column back if needed for rollback
    unless column_exists?(:users, :password_digest)
      add_column :users, :password_digest, :string
    end
  end
end

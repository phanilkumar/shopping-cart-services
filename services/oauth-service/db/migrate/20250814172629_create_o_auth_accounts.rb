class CreateOAuthAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :o_auth_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider
      t.string :provider_uid
      t.text :access_token
      t.text :refresh_token
      t.datetime :expires_at

      t.timestamps
    end
  end
end

class CreateAuditLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: true, foreign_key: true
      t.string :action, null: false
      t.string :resource_type
      t.bigint :resource_id
      t.json :details, default: {}
      t.string :ip_address
      t.text :user_agent
      t.string :session_id
      t.string :request_id
      t.timestamps
    end

    add_index :audit_logs, [:resource_type, :resource_id]
    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
    add_index :audit_logs, :ip_address
  end
end




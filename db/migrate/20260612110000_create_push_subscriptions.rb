class CreatePushSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.text :endpoint, null: false
      t.string :endpoint_sha256, null: false
      t.text :p256dh, null: false
      t.text :auth, null: false
      t.string :user_agent
      t.boolean :active, null: false, default: true
      t.datetime :last_success_at
      t.datetime :last_failure_at
      t.integer :failure_count, null: false, default: 0
      t.text :last_error

      t.timestamps
    end

    add_index :push_subscriptions, :endpoint_sha256, unique: true
    add_index :push_subscriptions, [ :user_id, :active ]
  end
end

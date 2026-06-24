# frozen_string_literal: true

class CreatePaveAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :pave_audit_events do |t|
      t.bigint :space_id, null: true
      t.string :key, null: false
      t.string :actor_type
      t.bigint :actor_id
      t.string :actor_label
      t.string :target_type
      t.bigint :target_id
      t.string :target_label
      t.jsonb :metadata, null: false, default: {}
      t.string :request_id
      t.string :idempotency_key
      t.string :source
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_index :pave_audit_events, %i[space_id occurred_at]
    add_index :pave_audit_events, %i[key occurred_at]
    add_index :pave_audit_events, %i[actor_type actor_id occurred_at]
    add_index :pave_audit_events, %i[target_type target_id occurred_at]
    add_index :pave_audit_events, :idempotency_key, unique: true, where: "idempotency_key IS NOT NULL"
  end
end

# frozen_string_literal: true

class CreateBillingCreditTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_credit_transactions do |t|
      t.references :space, null: false, foreign_key: true
      t.string :meter, null: false
      t.integer :amount, null: false
      t.integer :balance_after, null: false
      t.string :source, null: false
      t.string :idempotency_key
      t.references :actor, null: true, foreign_key: { to_table: :users }
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :billing_credit_transactions, :idempotency_key, unique: true
    add_index :billing_credit_transactions, %i[space_id meter]
    add_index :billing_credit_transactions, :meter
  end
end

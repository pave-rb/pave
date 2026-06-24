# frozen_string_literal: true

class CreateBillingCoupons < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_coupons do |t|
      t.references :billing_product, null: false, foreign_key: { to_table: :billing_products }
      t.string :code, null: false
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.boolean :public, null: false, default: true
      t.integer :discount_type, null: false
      t.integer :percent_off
      t.integer :amount_off_cents
      t.integer :duration, null: false, default: 0
      t.integer :duration_months, null: false, default: 1
      t.integer :max_redemptions
      t.integer :max_redemptions_per_space, null: false, default: 1
      t.datetime :starts_at
      t.datetime :expires_at
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :billing_coupons, [ :billing_product_id, :code ], unique: true
    add_index :billing_coupons, [ :active, :public ]
    add_index :billing_coupons, :expires_at

    add_check_constraint :billing_coupons,
                         "(discount_type = 0 AND percent_off BETWEEN 1 AND 100 AND amount_off_cents IS NULL) OR " \
                         "(discount_type = 1 AND amount_off_cents > 0 AND percent_off IS NULL)",
                         name: "chk_billing_coupons_discount_value"
    add_check_constraint :billing_coupons,
                         "duration <> 0 OR duration_months > 0",
                         name: "chk_billing_coupons_duration_months_positive"
    add_check_constraint :billing_coupons,
                         "max_redemptions IS NULL OR max_redemptions > 0",
                         name: "chk_billing_coupons_max_redemptions_positive"
    add_check_constraint :billing_coupons,
                         "max_redemptions_per_space > 0",
                         name: "chk_billing_coupons_max_per_space_positive"

    create_table :billing_coupon_redemptions do |t|
      t.references :coupon, null: false, foreign_key: { to_table: :billing_coupons }
      t.references :subscription, null: false, foreign_key: { to_table: :subscriptions }
      t.references :space, null: false, foreign_key: true
      t.references :billing_product, null: false, foreign_key: { to_table: :billing_products }
      t.integer :status, null: false, default: 0
      t.integer :source, null: false
      t.references :actor, foreign_key: { to_table: :users }
      t.string :coupon_code, null: false
      t.integer :discount_type, null: false
      t.integer :percent_off
      t.integer :amount_off_cents
      t.integer :duration, null: false
      t.integer :duration_months, null: false, default: 1
      t.integer :cycles_consumed, null: false, default: 0
      t.datetime :starts_at, null: false
      t.datetime :ended_at
      t.datetime :asaas_synced_at
      t.text :sync_error

      t.timestamps
    end

    add_index :billing_coupon_redemptions, [ :subscription_id, :status ]
    add_index :billing_coupon_redemptions, [ :coupon_id, :status ]
    add_index :billing_coupon_redemptions, [ :space_id, :coupon_id ]
    add_index :billing_coupon_redemptions,
              :subscription_id,
              unique: true,
              where: "status IN (0, 1, 2)",
              name: "idx_coupon_redemptions_one_current_per_subscription"

    add_check_constraint :billing_coupon_redemptions,
                         "cycles_consumed >= 0",
                         name: "chk_coupon_redemptions_cycles_non_negative"
    add_check_constraint :billing_coupon_redemptions,
                         "duration <> 0 OR duration_months > 0",
                         name: "chk_coupon_redemptions_duration_months_positive"

    create_table :billing_coupon_redemption_cycles do |t|
      t.references :coupon_redemption, null: false, foreign_key: { to_table: :billing_coupon_redemptions }
      t.references :payment, foreign_key: { to_table: :payments }
      t.string :asaas_payment_id, null: false
      t.integer :cycle_number, null: false
      t.integer :base_amount_cents, null: false
      t.integer :discount_amount_cents, null: false
      t.integer :charged_amount_cents, null: false

      t.timestamps
    end

    add_index :billing_coupon_redemption_cycles,
              [ :coupon_redemption_id, :asaas_payment_id ],
              unique: true,
              name: "idx_coupon_redemption_cycles_unique_payment"
    add_index :billing_coupon_redemption_cycles, :asaas_payment_id

    add_check_constraint :billing_coupon_redemption_cycles,
                         "cycle_number > 0 AND base_amount_cents > 0 AND discount_amount_cents >= 0 AND charged_amount_cents > 0",
                         name: "chk_coupon_redemption_cycles_amounts_positive"
  end
end

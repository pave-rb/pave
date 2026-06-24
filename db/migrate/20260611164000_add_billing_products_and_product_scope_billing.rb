# frozen_string_literal: true

class AddBillingProductsAndProductScopeBilling < ActiveRecord::Migration[8.1]
  class BillingProductRecord < ApplicationRecord
    self.table_name = "billing_products"
  end

  class BillingPlanRecord < ApplicationRecord
    self.table_name = "billing_plans"
  end

  class SubscriptionRecord < ApplicationRecord
    self.table_name = "subscriptions"
  end

  def up
    create_table :billing_products do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :billing_products, :key, unique: true

    add_reference :billing_plans,
                  :billing_product,
                  null: true,
                  foreign_key: { to_table: :billing_products },
                  index: false
    add_reference :subscriptions,
                  :billing_product,
                  null: true,
                  foreign_key: { to_table: :billing_products },
                  index: false

    backfill_crm_product

    change_column_null :billing_plans, :billing_product_id, false
    change_column_null :subscriptions, :billing_product_id, false

    replace_billing_plan_indexes
    replace_subscription_indexes
  end

  def down
    remove_index :subscriptions, name: "index_subscriptions_on_space_product_active", if_exists: true
    add_index :subscriptions,
              :space_id,
              unique: true,
              where: "status <> 4",
              name: "index_subscriptions_on_space_id_active"

    remove_index :subscriptions, :billing_product_id, if_exists: true
    remove_reference :subscriptions,
                     :billing_product,
                     foreign_key: { to_table: :billing_products }

    remove_index :billing_plans, name: "index_billing_plans_on_product_and_trial_default", if_exists: true
    remove_index :billing_plans, name: "index_billing_plans_on_product_and_slug", if_exists: true
    remove_index :billing_plans, :billing_product_id, if_exists: true
    add_index :billing_plans, :slug, unique: true
    add_index :billing_plans,
              :trial_default,
              unique: true,
              where: "trial_default = TRUE",
              name: "index_billing_plans_on_trial_default"
    remove_reference :billing_plans,
                     :billing_product,
                     foreign_key: { to_table: :billing_products }

    drop_table :billing_products
  end

  private

  def backfill_crm_product
    BillingProductRecord.reset_column_information
    crm_product = BillingProductRecord.find_or_create_by!(key: "crm") do |product|
      product.name = "CRM"
      product.description = "Anella CRM product"
      product.active = true
      product.position = 1
    end

    BillingPlanRecord.reset_column_information
    BillingPlanRecord.where(billing_product_id: nil).update_all(billing_product_id: crm_product.id)

    SubscriptionRecord.reset_column_information
    SubscriptionRecord.where(billing_product_id: nil).update_all(billing_product_id: crm_product.id)
  end

  def replace_billing_plan_indexes
    remove_index :billing_plans, name: "index_billing_plans_on_slug", if_exists: true
    remove_index :billing_plans, name: "index_billing_plans_on_trial_default", if_exists: true

    add_index :billing_plans, :billing_product_id
    add_index :billing_plans,
              [ :billing_product_id, :slug ],
              unique: true,
              name: "index_billing_plans_on_product_and_slug"
    add_index :billing_plans,
              [ :billing_product_id, :trial_default ],
              unique: true,
              where: "trial_default = TRUE",
              name: "index_billing_plans_on_product_and_trial_default"
  end

  def replace_subscription_indexes
    remove_index :subscriptions, name: "index_subscriptions_on_space_id_active", if_exists: true

    add_index :subscriptions, :billing_product_id
    add_index :subscriptions,
              [ :space_id, :billing_product_id ],
              unique: true,
              where: "status <> 4",
              name: "index_subscriptions_on_space_product_active"
  end
end

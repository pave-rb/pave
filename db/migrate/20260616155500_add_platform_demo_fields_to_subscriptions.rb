# frozen_string_literal: true

class AddPlatformDemoFieldsToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :funding_source, :integer, null: false, default: 0
    add_column :subscriptions, :platform_monthly_message_quota, :integer
    add_column :subscriptions, :demo_automations_enabled, :boolean, null: false, default: false

    add_index :subscriptions, :funding_source

    add_check_constraint :subscriptions,
                         "platform_monthly_message_quota IS NULL OR platform_monthly_message_quota >= 0",
                         name: "chk_subscriptions_platform_monthly_quota_non_negative"
    add_check_constraint :subscriptions,
                         "funding_source <> 1 OR (asaas_customer_id IS NULL AND asaas_subscription_id IS NULL AND payment_method IS NULL)",
                         name: "chk_subscriptions_platform_demo_unwired"
  end
end

# frozen_string_literal: true

module Pave
  module Billing
    class Subscription < ActiveRecord::Base
      self.table_name = "subscriptions"

      enum :status, { trialing: 0, active: 1, past_due: 2, canceled: 3, expired: 4, pending_payment: 5 }
      enum :funding_source, { customer_paid: 0, platform_demo: 1 }

      belongs_to :space, class_name: "Pave::Tenancy::Space"
      belongs_to :plan,
                 class_name: "Pave::Billing::Plan",
                 foreign_key: :billing_plan_id,
                 inverse_of: false
      belongs_to :billing_product,
                 class_name: "Pave::Billing::Product",
                 inverse_of: :subscriptions,
                 optional: true

      has_many :billing_events,
               class_name: "Pave::Billing::BillingEvent",
               foreign_key: :subscription_id,
               inverse_of: :subscription,
               dependent: :destroy

      scope :active, -> { where(status: statuses[:active]) }
      scope :trialing, -> { where(status: statuses[:trialing]) }
      scope :not_expired, -> { where.not(status: statuses[:expired]) }

      def active_subscription?
        trialing? || active?
      end

      def provider_customer_id
        read_attribute(:provider_customer_id) if has_attribute?(:provider_customer_id)
      end

      def provider_subscription_id
        read_attribute(:provider_subscription_id) if has_attribute?(:provider_subscription_id)
      end

      def provider_name
        read_attribute(:provider) if has_attribute?(:provider)
      end

      def customer_billable?
        funding_source == "customer_paid" && provider_customer_id.present?
      end

      def on_trial_subscription?
        trialing? || (trial_ends_at.present? && trial_ends_at > Time.current)
      end
    end
  end
end

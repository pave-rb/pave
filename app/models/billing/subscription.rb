# frozen_string_literal: true

module Billing
  class Subscription < ApplicationRecord
    self.table_name = "subscriptions"

    include SpaceScoped

    belongs_to :space
    belongs_to :billing_product,      class_name: "Billing::Product"
    belongs_to :billing_plan,         class_name: "Billing::Plan"
    belongs_to :pending_billing_plan, class_name: "Billing::Plan", optional: true
    has_many :payments,       class_name: "Billing::Payment",      dependent: :destroy
    has_many :billing_events, class_name: "Billing::BillingEvent", dependent: :destroy
    has_many :coupon_redemptions,
             class_name: "Billing::CouponRedemption",
             dependent: :destroy,
             inverse_of: :subscription

    before_validation :default_billing_product_from_plan

    enum :status, { trialing: 0, active: 1, past_due: 2, canceled: 3, expired: 4, pending_payment: 5 }
    enum :payment_method, { pix: 0, credit_card: 1, boleto: 2 }, prefix: true
    enum :funding_source, { customer_paid: 0, platform_demo: 1 }

    validates :space_id, presence: true
    validates :space_id,
              uniqueness: {
                scope: :billing_product_id,
                conditions: -> { where.not(status: Billing::Subscription.statuses[:expired]) }
              },
              unless: :expired?
    validates :billing_product, presence: true
    validates :platform_monthly_message_quota,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 },
              allow_nil: true
    validate :billing_plan_matches_product
    validate :pending_billing_plan_matches_product
    validate :platform_demo_must_not_be_provider_wired

    # Convenience alias — callers throughout the app use subscription.plan
    def plan
      billing_plan
    end

    def customer_billable?
      customer_paid? && asaas_customer_id.present?
    end

    def demo_automations_allowed?
      !platform_demo? || demo_automations_enabled?
    end

    def current_coupon_redemption
      coupon_redemptions.current.order(created_at: :desc).first
    end

    private

    def default_billing_product_from_plan
      self.billing_product ||= billing_plan&.billing_product
    end

    def billing_plan_matches_product
      return if billing_plan.blank? || billing_product.blank?
      return if billing_plan.billing_product_id == billing_product_id

      errors.add(:billing_plan, "must belong to the subscription billing product")
    end

    def pending_billing_plan_matches_product
      return if pending_billing_plan.blank? || billing_product.blank?
      return if pending_billing_plan.billing_product_id == billing_product_id

      errors.add(:pending_billing_plan, "must belong to the subscription billing product")
    end

    def platform_demo_must_not_be_provider_wired
      return unless platform_demo?
      return if asaas_customer_id.blank? && asaas_subscription_id.blank? && payment_method.blank?

      errors.add(:base, "platform demo subscriptions cannot be wired to a payment provider")
    end
  end
end

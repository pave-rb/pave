# frozen_string_literal: true

module Billing
  class CouponRedemption < ApplicationRecord
    self.table_name = "billing_coupon_redemptions"

    include SpaceScoped

    belongs_to :coupon,
               class_name: "Billing::Coupon",
               inverse_of: :redemptions
    belongs_to :subscription,
               class_name: "Billing::Subscription",
               inverse_of: :coupon_redemptions
    belongs_to :space
    belongs_to :billing_product, class_name: "Billing::Product"
    belongs_to :actor, class_name: "User", optional: true
    has_many :cycles,
             class_name: "Billing::CouponRedemptionCycle",
             dependent: :destroy,
             inverse_of: :coupon_redemption

    enum :status, { pending: 0, scheduled: 1, active: 2, exhausted: 3, canceled: 4, failed: 5 }
    enum :source, { checkout: 0, backoffice: 1 }
    enum :discount_type, { percentage: 0, fixed_amount: 1 }
    enum :duration, { repeating: 0, forever: 1 }, prefix: true

    before_validation :copy_coupon_snapshot, on: :create

    validates :space, :subscription, :billing_product, :coupon_code, :starts_at, presence: true
    validates :cycles_consumed,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :duration_months,
              numericality: { only_integer: true, greater_than: 0 },
              unless: :duration_forever?

    scope :current, -> { where(status: [ :pending, :scheduled, :active ]) }
    scope :redeemed, -> { where.not(status: :failed) }

    def applies_to_cycle?(due_at = Time.current)
      return false unless active? || scheduled?
      return true if starts_at.blank?

      due_at.to_date >= starts_at.to_date
    end

    def remaining_cycles?
      duration_forever? || cycles_consumed < duration_months
    end

    private

    def copy_coupon_snapshot
      return unless coupon

      self.space_id ||= subscription&.space_id
      self.billing_product ||= coupon.billing_product
      self.coupon_code ||= coupon.code
      self.discount_type ||= coupon.discount_type
      self.percent_off = coupon.percent_off
      self.amount_off_cents = coupon.amount_off_cents
      self.duration ||= coupon.duration
      self.duration_months ||= coupon.duration_months
    end
  end
end

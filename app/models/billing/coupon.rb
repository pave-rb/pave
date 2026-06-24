# frozen_string_literal: true

module Billing
  class Coupon < ApplicationRecord
    self.table_name = "billing_coupons"

    belongs_to :billing_product,
               class_name: "Billing::Product",
               inverse_of: :coupons
    belongs_to :created_by, class_name: "User", optional: true
    belongs_to :updated_by, class_name: "User", optional: true
    has_many :redemptions,
             class_name: "Billing::CouponRedemption",
             dependent: :restrict_with_error,
             inverse_of: :coupon

    enum :discount_type, { percentage: 0, fixed_amount: 1 }
    enum :duration, { repeating: 0, forever: 1 }, prefix: true

    before_validation :normalize_code
    before_validation :normalize_discount_fields

    validates :billing_product, :code, :name, :discount_type, :duration, presence: true
    validates :code,
              uniqueness: { scope: :billing_product_id },
              format: { with: /\A[A-Z0-9_-]+\z/ }
    validates :percent_off,
              numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 },
              allow_nil: true
    validates :amount_off_cents,
              numericality: { only_integer: true, greater_than: 0 },
              allow_nil: true
    validates :duration_months,
              numericality: { only_integer: true, greater_than: 0 },
              unless: :duration_forever?
    validates :max_redemptions,
              numericality: { only_integer: true, greater_than: 0 },
              allow_nil: true
    validates :max_redemptions_per_space,
              numericality: { only_integer: true, greater_than: 0 }
    validate :discount_value_matches_type
    validate :expires_after_starts

    scope :ordered, -> { order(active: :desc, created_at: :desc) }
    scope :enabled, -> { where(active: true) }
    scope :available_publicly, -> { where(active: true, public: true) }
    scope :for_product, ->(product = Billing::Product.crm) { where(billing_product: product) }

    def active_now?(at = Time.current)
      active? && (starts_at.blank? || starts_at <= at) && (expires_at.blank? || expires_at >= at)
    end

    def exhausted?
      max_redemptions.present? && redeemed_count >= max_redemptions
    end

    def redeemed_count
      Billing::CouponRedemption.unscoped.redeemed.where(coupon_id: id).count
    end

    private

    def normalize_code
      self.code = code.to_s.strip.upcase.presence
    end

    def normalize_discount_fields
      return if discount_type.blank?

      if percentage?
        self.amount_off_cents = nil
      elsif fixed_amount?
        self.percent_off = nil
      end
    end

    def discount_value_matches_type
      if percentage? && percent_off.blank?
        errors.add(:percent_off, :blank)
      elsif fixed_amount? && amount_off_cents.blank?
        errors.add(:amount_off_cents, :blank)
      end
    end

    def expires_after_starts
      return if starts_at.blank? || expires_at.blank? || expires_at > starts_at

      errors.add(:expires_at, "must be after the start date")
    end
  end
end

# frozen_string_literal: true

module Billing
  class CouponRedemptionCycle < ApplicationRecord
    self.table_name = "billing_coupon_redemption_cycles"

    belongs_to :coupon_redemption,
               class_name: "Billing::CouponRedemption",
               inverse_of: :cycles
    belongs_to :payment, class_name: "Billing::Payment", optional: true

    validates :asaas_payment_id, presence: true
    validates :cycle_number,
              numericality: { only_integer: true, greater_than: 0 }
    validates :base_amount_cents,
              :charged_amount_cents,
              numericality: { only_integer: true, greater_than: 0 }
    validates :discount_amount_cents,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  end
end

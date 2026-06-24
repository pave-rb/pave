# frozen_string_literal: true

module Billing
  class Product < ApplicationRecord
    self.table_name = "billing_products"

    CRM_KEY = "crm"

    has_many :plans,
             class_name: "Billing::Plan",
             foreign_key: :billing_product_id,
             inverse_of: :billing_product,
             dependent: :restrict_with_error
    has_many :subscriptions,
              class_name: "Billing::Subscription",
              foreign_key: :billing_product_id,
              inverse_of: :billing_product,
              dependent: :restrict_with_error
    has_many :coupons,
              class_name: "Billing::Coupon",
              foreign_key: :billing_product_id,
              inverse_of: :billing_product,
              dependent: :restrict_with_error

    validates :key, presence: true,
                    uniqueness: true,
                    format: { with: /\A[a-z0-9_]+\z/ }
    validates :name, presence: true
    validates :active, inclusion: { in: [ true, false ] }
    validates :position, presence: true

    scope :active, -> { where(active: true) }
    scope :ordered, -> { order(:position, :name) }

    def self.crm
      find_by!(key: CRM_KEY)
    end

    def crm?
      key == CRM_KEY
    end
  end
end

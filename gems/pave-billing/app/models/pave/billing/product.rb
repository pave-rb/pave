# frozen_string_literal: true

module Pave
  module Billing
    class Product < ActiveRecord::Base
      self.table_name = "billing_products"

      has_many :plans,
               class_name: "Pave::Billing::Plan",
               foreign_key: :billing_product_id,
               inverse_of: :billing_product,
               dependent: :restrict_with_error
      has_many :subscriptions,
               class_name: "Pave::Billing::Subscription",
               foreign_key: :billing_product_id,
               inverse_of: :billing_product,
               dependent: :restrict_with_error

      validates :key, presence: true, uniqueness: true
      validates :name, presence: true

      scope :active, -> { where(active: true) }
      scope :ordered, -> { order(:position, :name) }
    end
  end
end

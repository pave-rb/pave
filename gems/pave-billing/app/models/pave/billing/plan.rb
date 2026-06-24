# frozen_string_literal: true

module Pave
  module Billing
    class Plan < ActiveRecord::Base
      self.table_name = "billing_plans"

      belongs_to :billing_product,
                 class_name: "Pave::Billing::Product",
                 inverse_of: :plans,
                 optional: true

      scope :active, -> { where(active: true) }
      scope :ordered, -> { order(:position) }

      def free?
        price_cents.zero?
      end

      def has_capability?(capability)
        features.include?(capability.to_s)
      end

      def to_s
        name
      end
    end
  end
end

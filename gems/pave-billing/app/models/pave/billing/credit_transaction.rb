# frozen_string_literal: true

module Pave
  module Billing
    class CreditTransaction < ActiveRecord::Base
      self.table_name = "billing_credit_transactions"

      belongs_to :space, class_name: "Pave::Tenancy::Space"

      validates :meter, presence: true
      validates :amount, presence: true
      validates :source, presence: true
      validates :idempotency_key, uniqueness: true, allow_nil: true

      scope :for_meter, ->(meter) { where(meter: meter) }
      scope :chronological, -> { order(:created_at) }

      def space=(record)
        self.space_id = record&.id
      end

      def credit?
        amount > 0
      end

      def debit?
        amount < 0
      end
    end
  end
end

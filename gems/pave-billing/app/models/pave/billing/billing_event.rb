# frozen_string_literal: true

module Pave
  module Billing
    class BillingEvent < ActiveRecord::Base
      self.table_name = "billing_events"

      belongs_to :space, class_name: "Pave::Tenancy::Space"
      belongs_to :subscription,
                 class_name: "Pave::Billing::Subscription",
                 foreign_key: :subscription_id,
                 inverse_of: :billing_events,
                 optional: true

      validates :event_type, presence: true

      before_update { raise ActiveRecord::ReadOnlyRecord, "#{self.class} is append-only and cannot be updated" }
    end
  end
end

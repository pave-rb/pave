# frozen_string_literal: true

module Pave
  module Billing
    class NullAdapter < ProviderAdapter
      def name
        "null"
      end

      def create_customer(space:, customer_data: {})
        "null_customer_#{space.id}"
      end

      def create_subscription(space:, plan:, customer_id:, trial_days: 0)
        "null_subscription_#{space.id}_#{Time.current.to_i}"
      end

      def cancel_subscription(subscription_id)
        true
      end

      def update_subscription(subscription_id:, plan:)
        true
      end

      def retrieve_subscription(subscription_id)
        {}
      end

      def process_webhook(payload:, headers:)
        { status: "processed", provider: "null" }
      end
    end
  end
end

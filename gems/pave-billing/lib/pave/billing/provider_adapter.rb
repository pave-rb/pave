# frozen_string_literal: true

module Pave
  module Billing
    class ProviderAdapter
      def create_customer(space:, customer_data: {})
        raise NotImplementedError, "#{self.class} must implement #create_customer"
      end

      def create_subscription(space:, plan:, customer_id:, trial_days: 0)
        raise NotImplementedError, "#{self.class} must implement #create_subscription"
      end

      def cancel_subscription(subscription_id)
        raise NotImplementedError, "#{self.class} must implement #cancel_subscription"
      end

      def update_subscription(subscription_id:, plan:)
        raise NotImplementedError, "#{self.class} must implement #update_subscription"
      end

      def retrieve_subscription(subscription_id)
        raise NotImplementedError, "#{self.class} must implement #retrieve_subscription"
      end

      def process_webhook(payload:, headers:)
        raise NotImplementedError, "#{self.class} must implement #process_webhook"
      end

      def name
        raise NotImplementedError, "#{self.class} must implement #name"
      end
    end
  end
end

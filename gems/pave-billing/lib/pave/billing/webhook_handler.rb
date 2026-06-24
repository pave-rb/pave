# frozen_string_literal: true

module Pave
  module Billing
    class WebhookHandler
      def handle(payload:, headers:)
        raise NotImplementedError, "#{self.class} must implement #handle"
      end

      def normalize(payload:, headers:)
        raise NotImplementedError, "#{self.class} must implement #normalize"
      end

      def provider_name
        raise NotImplementedError, "#{self.class} must implement #provider_name"
      end
    end
  end
end

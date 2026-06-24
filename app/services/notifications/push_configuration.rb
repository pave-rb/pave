# frozen_string_literal: true

module Notifications
  class PushConfiguration
    class << self
      def configured?
        vapid_public_key.present? && vapid_private_key.present?
      end

      def vapid_options
        {
          subject: vapid_subject,
          public_key: vapid_public_key,
          private_key: vapid_private_key
        }
      end

      def vapid_public_key
        credentials[:vapid_public_key].presence
      end

      def vapid_private_key
        credentials[:vapid_private_key].presence
      end

      def vapid_subject
        credentials[:vapid_subject].presence ||
          credentials[:subject].presence ||
          default_subject
      end

      private

      def credentials
        push_credentials = Rails.application.credentials.dig(:push_notifications) ||
                           Rails.application.credentials.dig(:web_push) ||
                           {}

        push_credentials.respond_to?(:to_h) ? push_credentials.to_h.symbolize_keys : {}
      end

      def default_subject
        support_email = AppBrand.support_email.presence
        return "mailto:#{support_email}" if support_email

        Rails.configuration.x.app.base_url.presence || "mailto:push-notifications@example.invalid"
      end
    end
  end
end

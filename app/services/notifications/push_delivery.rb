# frozen_string_literal: true

module Notifications
  class PushDelivery
    DEFAULT_TTL = 24.hours.to_i
    Result = Struct.new(:sent, :failed, :skipped, keyword_init: true)

    def self.call(notification:)
      new(notification: notification).call
    end

    def initialize(notification:, web_push: WebPush)
      @notification = notification
      @web_push = web_push
      @sent = 0
      @failed = 0
    end

    def call
      return Result.new(sent: 0, failed: 0, skipped: true) unless PushConfiguration.configured?

      @notification.user.push_subscriptions.active.find_each do |subscription|
        deliver_to(subscription)
      end

      Result.new(sent: @sent, failed: @failed, skipped: false)
    end

    private

    def deliver_to(subscription)
      @web_push.payload_send(
        message: payload.to_json,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh,
        auth: subscription.auth,
        vapid: PushConfiguration.vapid_options,
        ttl: DEFAULT_TTL
      )

      subscription.record_success!
      @sent += 1
    rescue => e
      @failed += 1
      handle_delivery_failure(subscription, e)
    end

    def handle_delivery_failure(subscription, error)
      if expired_subscription_error?(error)
        subscription.deactivate!(error.message)
      else
        subscription.record_failure!(error.message)
      end

      Rails.logger.warn(
        "[Notifications] push_delivery_failed notification_id=#{@notification.id} " \
        "push_subscription_id=#{subscription.id} error_class=#{error.class} error=#{error.message}"
      )
    end

    def expired_subscription_error?(error)
      response_code = error.respond_to?(:response) ? error.response&.code.to_i : nil

      return true if defined?(WebPush::ExpiredSubscription) && error.is_a?(WebPush::ExpiredSubscription)
      return true if defined?(WebPush::InvalidSubscription) && error.is_a?(WebPush::InvalidSubscription)

      [ 404, 410 ].include?(response_code) ||
        error.class.name.to_s.match?(/ExpiredSubscription|InvalidSubscription/)
    end

    def payload
      {
        id: @notification.id,
        title: @notification.title,
        body: @notification.body,
        event_type: @notification.event_type,
        url: target_url,
        tag: "notification-#{@notification.id}",
        created_at: @notification.created_at.iso8601
      }
    end

    def target_url
      target = @notification.target_path
      return routes.root_path if target.blank?

      routes.url_for(target.merge(only_path: true))
    rescue ActionController::UrlGenerationError
      routes.root_path
    end

    def routes
      Rails.application.routes.url_helpers
    end
  end
end

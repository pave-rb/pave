# frozen_string_literal: true

require "test_helper"

module Notifications
  class PushDeliveryTest < ActiveSupport::TestCase
    FakeWebPush = Struct.new(:calls, :error) do
      def payload_send(**kwargs)
        calls << kwargs
        raise error if error
      end
    end

    ResponseError = Class.new(StandardError) do
      attr_reader :response

      def initialize(code)
        @response = Struct.new(:code).new(code.to_s)
        super("HTTP #{code}")
      end
    end

    setup do
      @user = users(:manager)
      @notification = notifications(:booking_received)
      @notification.update!(user: @user)
      @subscription = PushSubscription.create!(
        user: @user,
        endpoint: "https://push.example.test/subscriptions/abc",
        p256dh: "p256dh-key",
        auth: "auth-secret"
      )
    end

    test "sends payload to each active subscription" do
      fake_web_push = FakeWebPush.new([], nil)

      with_push_configuration do
        PushDelivery.new(notification: @notification, web_push: fake_web_push).call
      end

      assert_equal 1, fake_web_push.calls.size
      call = fake_web_push.calls.first
      assert_equal @subscription.endpoint, call[:endpoint]
      assert_equal @subscription.p256dh, call[:p256dh]
      assert_equal @subscription.auth, call[:auth]
      assert_equal "public-key", call[:vapid][:public_key]
      assert_equal "private-key", call[:vapid][:private_key]

      payload = JSON.parse(call[:message])
      assert_equal @notification.title, payload["title"]
      assert_equal @notification.body, payload["body"]
      assert_equal @notification.id, payload["id"]
      assert_equal "/appointments/#{@notification.notifiable_id}", payload["url"]
      assert_equal "notification-#{@notification.id}", payload["tag"]
      assert_not_nil @subscription.reload.last_success_at
    end

    test "skips when VAPID keys are missing" do
      fake_web_push = FakeWebPush.new([], nil)

      PushConfiguration.stub(:configured?, false) do
        PushDelivery.new(notification: @notification, web_push: fake_web_push).call
      end

      assert_empty fake_web_push.calls
      assert_nil @subscription.reload.last_success_at
    end

    test "does not send to inactive subscriptions" do
      @subscription.update!(active: false)
      fake_web_push = FakeWebPush.new([], nil)

      with_push_configuration do
        PushDelivery.new(notification: @notification, web_push: fake_web_push).call
      end

      assert_empty fake_web_push.calls
    end

    test "marks expired subscriptions inactive on 404 or 410 responses" do
      fake_web_push = FakeWebPush.new([], ResponseError.new(410))

      with_push_configuration do
        PushDelivery.new(notification: @notification, web_push: fake_web_push).call
      end

      assert_not @subscription.reload.active?
      assert_equal "HTTP 410", @subscription.last_error
    end

    test "records retryable failures without raising" do
      fake_web_push = FakeWebPush.new([], StandardError.new("timeout"))

      with_push_configuration do
        assert_nothing_raised do
          PushDelivery.new(notification: @notification, web_push: fake_web_push).call
        end
      end

      assert @subscription.reload.active?
      assert_equal 1, @subscription.failure_count
      assert_equal "timeout", @subscription.last_error
    end

    private

    def with_push_configuration(&block)
      PushConfiguration.stub(:configured?, true) do
        PushConfiguration.stub(:vapid_options, { subject: "mailto:test@example.com", public_key: "public-key", private_key: "private-key" }, &block)
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:manager)
    @user.create_user_preference!(locale: "pt-BR") unless @user.user_preference
    sign_in @user
    @payload = {
      subscription: {
        endpoint: "https://push.example.test/subscriptions/abc",
        keys: {
          p256dh: "p256dh-key",
          auth: "auth-secret"
        }
      }
    }
  end

  test "creates push subscription for current user" do
    assert_difference "PushSubscription.count", 1 do
      post push_subscriptions_path, params: @payload, as: :json
    end

    assert_response :created
    subscription = PushSubscription.last
    assert_equal @user, subscription.user
    assert_equal @payload[:subscription][:endpoint], subscription.endpoint
    assert_equal "p256dh-key", subscription.p256dh
    assert_equal "auth-secret", subscription.auth
    assert subscription.active?
    assert @user.user_preference.reload.push_notifications_enabled?
    assert_equal "granted", @user.user_preference.push_notifications_permission
  end

  test "upserts existing endpoint and moves it to current user" do
    existing = PushSubscription.create!(
      user: users(:secretary),
      endpoint: @payload[:subscription][:endpoint],
      p256dh: "old-key",
      auth: "old-secret",
      active: false
    )

    assert_no_difference "PushSubscription.count" do
      post push_subscriptions_path, params: @payload, as: :json
    end

    assert_response :ok
    existing.reload
    assert_equal @user, existing.user
    assert_equal "p256dh-key", existing.p256dh
    assert_equal "auth-secret", existing.auth
    assert existing.active?
    assert @user.user_preference.reload.push_notifications_enabled?
  end

  test "rejects malformed payload" do
    assert_no_difference "PushSubscription.count" do
      post push_subscriptions_path, params: { subscription: { endpoint: "" } }, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "requires authentication" do
    sign_out @user

    post push_subscriptions_path, params: @payload, as: :json

    assert_response :unauthorized
  end

  test "destroys current user push subscription by endpoint" do
    subscription = PushSubscription.create!(
      user: @user,
      endpoint: @payload[:subscription][:endpoint],
      p256dh: "p256dh-key",
      auth: "auth-secret"
    )

    delete push_subscription_path, params: { endpoint: subscription.endpoint }, as: :json

    assert_response :no_content
    assert_not subscription.reload.active?
    assert_not @user.user_preference.reload.push_notifications_enabled?
  end

  test "destroy does not touch another user's endpoint" do
    subscription = PushSubscription.create!(
      user: users(:secretary),
      endpoint: @payload[:subscription][:endpoint],
      p256dh: "p256dh-key",
      auth: "auth-secret"
    )

    delete push_subscription_path, params: { endpoint: subscription.endpoint }, as: :json

    assert_response :no_content
    assert subscription.reload.active?
  end
end

# frozen_string_literal: true

require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  test "valid with required browser subscription attributes" do
    subscription = PushSubscription.new(
      user: users(:manager),
      endpoint: "https://push.example.test/subscriptions/abc",
      p256dh: "p256dh-key",
      auth: "auth-secret"
    )

    assert subscription.valid?
  end

  test "requires endpoint keys and user" do
    subscription = PushSubscription.new

    assert_not subscription.valid?
    assert subscription.errors[:user].any?
    assert subscription.errors[:endpoint].any?
    assert subscription.errors[:p256dh].any?
    assert subscription.errors[:auth].any?
  end

  test "stores endpoint digest for lookup without exposing endpoint in indexes" do
    subscription = PushSubscription.create!(
      user: users(:manager),
      endpoint: "https://push.example.test/subscriptions/abc",
      p256dh: "p256dh-key",
      auth: "auth-secret"
    )

    assert_equal PushSubscription.endpoint_digest(subscription.endpoint), subscription.endpoint_sha256
  end

  test "endpoint digest is unique across users" do
    endpoint = "https://push.example.test/subscriptions/abc"
    PushSubscription.create!(
      user: users(:manager),
      endpoint: endpoint,
      p256dh: "p256dh-key",
      auth: "auth-secret"
    )

    duplicate = PushSubscription.new(
      user: users(:secretary),
      endpoint: endpoint,
      p256dh: "other-key",
      auth: "other-secret"
    )

    assert_not duplicate.valid?
    assert duplicate.errors[:endpoint_sha256].any?
  end

  test "record_success clears transient failure metadata" do
    subscription = PushSubscription.create!(
      user: users(:manager),
      endpoint: "https://push.example.test/subscriptions/abc",
      p256dh: "p256dh-key",
      auth: "auth-secret",
      failure_count: 2,
      last_error: "timeout",
      active: false
    )

    subscription.record_success!

    assert subscription.reload.active?
    assert_equal 0, subscription.failure_count
    assert_nil subscription.last_error
    assert_not_nil subscription.last_success_at
  end

  test "record_failure keeps subscription active for retryable failures" do
    subscription = PushSubscription.create!(
      user: users(:manager),
      endpoint: "https://push.example.test/subscriptions/abc",
      p256dh: "p256dh-key",
      auth: "auth-secret"
    )

    subscription.record_failure!("timeout")

    assert subscription.reload.active?
    assert_equal 1, subscription.failure_count
    assert_equal "timeout", subscription.last_error
    assert_not_nil subscription.last_failure_at
  end

  test "deactivate marks expired browser subscription inactive" do
    subscription = PushSubscription.create!(
      user: users(:manager),
      endpoint: "https://push.example.test/subscriptions/abc",
      p256dh: "p256dh-key",
      auth: "auth-secret"
    )

    subscription.deactivate!("gone")

    assert_not subscription.reload.active?
    assert_equal "gone", subscription.last_error
    assert_not_nil subscription.last_failure_at
  end
end

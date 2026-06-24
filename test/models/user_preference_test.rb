# frozen_string_literal: true

require "test_helper"

class UserPreferenceTest < ActiveSupport::TestCase
  setup do
    @preference = UserPreference.create!(user: users(:manager), locale: "pt-BR")
  end

  test "defaults push notifications to off and undecided" do
    assert_not @preference.push_notifications_enabled?
    assert_equal "default", @preference.push_notifications_permission
  end

  test "validates push notification permission" do
    @preference.push_notifications_permission = "maybe"

    assert_not @preference.valid?
    assert @preference.errors[:push_notifications_permission].any?
  end

  test "enable_push_notifications stores user decision timestamps" do
    freeze_time do
      @preference.enable_push_notifications!(permission: "granted")

      assert @preference.reload.push_notifications_enabled?
      assert_equal "granted", @preference.push_notifications_permission
      assert_equal Time.current, @preference.push_notifications_enabled_at
      assert_equal Time.current, @preference.push_notifications_decided_at
      assert_nil @preference.push_notifications_disabled_at
    end
  end

  test "disable_push_notifications stores disabled decision" do
    @preference.enable_push_notifications!(permission: "granted")

    freeze_time do
      @preference.disable_push_notifications!(permission: "granted")

      assert_not @preference.reload.push_notifications_enabled?
      assert_equal "granted", @preference.push_notifications_permission
      assert_equal Time.current, @preference.push_notifications_disabled_at
      assert_equal Time.current, @preference.push_notifications_decided_at
    end
  end

  test "record_push_notification_permission stores denied permission and keeps disabled" do
    @preference.record_push_notification_permission!(permission: "denied")

    assert_not @preference.reload.push_notifications_enabled?
    assert_equal "denied", @preference.push_notifications_permission
    assert_not_nil @preference.push_notifications_decided_at
  end
end

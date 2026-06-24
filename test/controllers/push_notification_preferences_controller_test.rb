# frozen_string_literal: true

require "test_helper"

class PushNotificationPreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:manager)
    @user.create_user_preference!(locale: "pt-BR") unless @user.user_preference
    sign_in @user
  end

  test "stores granted notification decision" do
    patch push_notification_preference_path, params: { enabled: true, permission: "granted" }, as: :json

    assert_response :success
    preference = @user.user_preference.reload
    assert preference.push_notifications_enabled?
    assert_equal "granted", preference.push_notifications_permission
  end

  test "stores denied notification decision without enabling" do
    patch push_notification_preference_path, params: { enabled: true, permission: "denied" }, as: :json

    assert_response :success
    preference = @user.user_preference.reload
    assert_not preference.push_notifications_enabled?
    assert_equal "denied", preference.push_notifications_permission
  end

  test "stores disabled notification decision" do
    @user.user_preference.enable_push_notifications!(permission: "granted")

    patch push_notification_preference_path, params: { enabled: false, permission: "granted" }, as: :json

    assert_response :success
    preference = @user.user_preference.reload
    assert_not preference.push_notifications_enabled?
    assert_equal "granted", preference.push_notifications_permission
  end

  test "requires authentication" do
    sign_out @user

    patch push_notification_preference_path, params: { enabled: true, permission: "granted" }, as: :json

    assert_response :unauthorized
  end
end

# frozen_string_literal: true

require "test_helper"

module Backoffice
  class RegistrationSettingsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @admin = users(:admin)
      @manager = users(:manager)
      RegistrationSetting.delete_all
    end

    test "unauthenticated users are redirected to login" do
      get backoffice_registrations_path

      assert_redirected_to new_user_session_path
    end

    test "non-admin users cannot access registrations page" do
      sign_in @manager
      get backoffice_registrations_path

      assert_redirected_to root_path
    end

    test "admin can view the registrations page" do
      sign_in @admin

      get backoffice_registrations_path

      assert_response :success
      assert_select "h1", text: I18n.t("backoffice.registrations.show.title")
    end

    test "admin can disable registrations" do
      sign_in @admin

      assert_difference "AuditLog.count", 1 do
        patch backoffice_disable_registrations_path
      end

      assert_redirected_to backoffice_registrations_path
      assert_equal false, RegistrationSetting.current.enabled?
      assert_equal "backoffice.registrations_disabled", AuditLog.order(:id).last.event_type
    end

    test "admin can enable registrations" do
      RegistrationSetting.current.update!(enabled: false)
      sign_in @admin

      assert_difference "AuditLog.count", 1 do
        patch backoffice_enable_registrations_path
      end

      assert_redirected_to backoffice_registrations_path
      assert RegistrationSetting.current.enabled?
      assert_equal "backoffice.registrations_enabled", AuditLog.order(:id).last.event_type
    end
  end
end

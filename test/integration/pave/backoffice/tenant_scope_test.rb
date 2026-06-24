# frozen_string_literal: true

require "test_helper"

module Pave
  module Backoffice
    class TenantScopeTest < ActionDispatch::IntegrationTest
      setup do
        @admin = users(:admin)
      end

      def sign_in_to_backoffice(user)
        post "/admin/sign_in", params: { email: user.email, password: "password123" }
        assert_redirected_to "/admin/"
      end

      test "TenantScopeLeakError is a StandardError" do
        assert Pave::Backoffice::TenantScopeLeakError < StandardError
      end

      test "normal backoffice request does not raise tenant scope error" do
        sign_in_to_backoffice(@admin)
        get "/admin"
        assert_response :success
      end

      test "normal backoffice request keeps Pave::Current.space nil" do
        sign_in_to_backoffice(@admin)
        get "/admin"
        assert_response :success
      end

      test "pre-existing Pave::Current.space does not prevent backoffice access" do
        Pave::Current.space = "leaked_from_previous_request"

        sign_in_to_backoffice(@admin)
        get "/admin"

        assert_response :success
      ensure
        Pave::Current.space = nil
      end

      def with_dashboard_controller
        get "/admin"
        yield
      end

      test "guard_tenant_scope raises when Pave::Current.space is set during action" do
        sign_in_to_backoffice(@admin)

        with_dashboard_controller do
          assert_raises(Pave::Backoffice::TenantScopeLeakError) do
            @controller.send(:guard_tenant_scope) do
              Pave::Current.space = Object.new
            end
          end
        end
      ensure
        Pave::Current.space = nil
      end

      test "guard_tenant_scope raises when legacy Current.space is set during action" do
        skip "::Current is not defined in this test environment" unless defined?(::Current)

        sign_in_to_backoffice(@admin)

        with_dashboard_controller do
          assert_raises(Pave::Backoffice::TenantScopeLeakError) do
            @controller.send(:guard_tenant_scope) do
              ::Current.space = Object.new
            end
          end
        end
      ensure
        ::Current.space = nil if defined?(::Current)
      end

      test "guard_tenant_scope does not raise when scope remains nil" do
        sign_in_to_backoffice(@admin)

        with_dashboard_controller do
          @controller.send(:guard_tenant_scope) do
          end
        end

        assert_nil Pave::Current.space
      end

      test "pre-existing legacy Current.space is cleared before action" do
        skip "::Current is not defined in this test environment" unless defined?(::Current)

        ::Current.space = Object.new
        sign_in_to_backoffice(@admin)
        get "/admin"
        assert_response :success
      ensure
        ::Current.space = nil if defined?(::Current)
      end
    end
  end
end

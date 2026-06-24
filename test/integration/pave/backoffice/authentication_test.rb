# frozen_string_literal: true

require "test_helper"

module Pave
  module Backoffice
    class AuthenticationTest < ActionDispatch::IntegrationTest
      setup do
        @admin = users(:admin)
        @manager = users(:manager)
      end

      test "sign in page renders" do
        get "/admin/sign_in"
        assert_response :success
        assert_select "h1", text: "Pave Backoffice"
      end

      test "super admin can sign in and creates backoffice session" do
        post "/admin/sign_in", params: { email: @admin.email, password: "password123" }
        assert_redirected_to "/admin/"
        assert_equal @admin.id, session[:pave_backoffice_admin_id],
          "expected backoffice admin session to be set"
      end

      test "non-super-admin cannot sign in" do
        post "/admin/sign_in", params: { email: @manager.email, password: "password123" }
        assert_response :unprocessable_entity
        assert_nil session[:pave_backoffice_admin_id],
          "expected no backoffice session for non-super-admin"
      end

      test "invalid credentials are rejected" do
        post "/admin/sign_in", params: { email: @admin.email, password: "wrongpassword" }
        assert_response :unprocessable_entity
        assert_nil session[:pave_backoffice_admin_id]
      end

      test "unknown email is rejected" do
        post "/admin/sign_in", params: { email: "unknown@example.com", password: "password123" }
        assert_response :unprocessable_entity
        assert_nil session[:pave_backoffice_admin_id]
      end

      test "sign out clears backoffice session" do
        post "/admin/sign_in", params: { email: @admin.email, password: "password123" }
        assert session[:pave_backoffice_admin_id].present?

        delete "/admin/sign_out"
        assert_redirected_to "/admin/sign_in"
        assert_nil session[:pave_backoffice_admin_id],
          "expected backoffice session to be cleared"
      end

      test "already signed in admin is redirected to dashboard" do
        post "/admin/sign_in", params: { email: @admin.email, password: "password123" }
        get "/admin/sign_in"
        assert_redirected_to "/admin/"
      end

      test "backoffice sign in does not create Devise product session" do
        post "/admin/sign_in", params: { email: @admin.email, password: "password123" }
        assert_nil session["warden.user.user.key"],
          "expected no Devise product session from backoffice sign-in"
      end

      test "product session alone does not set backoffice admin session" do
        sign_in @manager
        get "/admin/sign_in"
        assert_nil session[:pave_backoffice_admin_id],
          "expected product session not to create backoffice session"
      end

      test "backoffice sign-out does not destroy product session" do
        sign_in @manager
        post "/admin/sign_in", params: { email: @admin.email, password: "password123" }
        assert session["warden.user.user.key"].present?,
          "expected product session to exist before sign-out"

        delete "/admin/sign_out"

        assert session["warden.user.user.key"].present?,
          "expected product session to survive backoffice sign-out"
        assert_nil session[:pave_backoffice_admin_id],
          "expected backoffice session to be cleared"
      end

      test "unauthenticated access to admin dashboard redirects to sign in" do
        get "/admin"
        assert_redirected_to "/admin/sign_in"
      end

      test "unauthenticated access stores return_to location" do
        get "/admin/"
        assert_redirected_to "/admin/sign_in"
        assert_equal "/admin/", session[:pave_backoffice_return_to]
      end

      test "after sign in, redirects to stored return_to location" do
        get "/admin/"
        assert_redirected_to "/admin/sign_in"

        post "/admin/sign_in", params: { email: @admin.email, password: "password123" }
        assert_redirected_to "/admin/"
      end
    end
  end
end

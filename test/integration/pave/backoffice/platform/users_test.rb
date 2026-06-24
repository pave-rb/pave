# frozen_string_literal: true

require "test_helper"

module Pave
  module Backoffice
    module Platform
      class UsersTest < ActionDispatch::IntegrationTest
        setup do
          @admin = users(:admin)
        end

        def sign_in_to_backoffice
          post "/admin/sign_in", params: { email: @admin.email, password: "password123" }
          assert_redirected_to "/admin/"
        end

    test "users index renders for platform admin" do
      sign_in_to_backoffice
      get "/admin/users"
      assert_response :success
      assert_select "h1", "Platform Users"
      assert_select "[data-backoffice-filter-bar]"
      assert_select "[data-backoffice-data-table]"
    end

        test "users index lists users in the system" do
          sign_in_to_backoffice
          get "/admin/users"
          assert_response :success
          assert_select "tbody tr", minimum: 2
          assert_select "td", text: @admin.email
        end

    test "users index supports search by email" do
      sign_in_to_backoffice
      get "/admin/users", params: { q: @admin.email }
      assert_response :success
      assert_select "td", text: @admin.email
      assert_select "[data-backoffice-filter-chips]", text: /Q:.*#{Regexp.escape(@admin.email)}/
    end

        test "users index supports platform access filter" do
          sign_in_to_backoffice
          get "/admin/users", params: { platform_access: "1" }
          assert_response :success
          assert_select "td span", text: "Super admin"
        end

        test "users index shows empty state when no results" do
          sign_in_to_backoffice
          get "/admin/users", params: { q: "nonexistent-user-999@example.com" }
          assert_response :success
          assert_select "td", text: "No users found."
        end

        test "users index requires backoffice authentication" do
          get "/admin/users"
          assert_redirected_to "/admin/sign_in"
        end

        test "users show renders user detail" do
          sign_in_to_backoffice
          get "/admin/users/#{@admin.id}"
          assert_response :success
          assert_select "h1", text: @admin.name
        end

        test "users show renders identity section" do
          sign_in_to_backoffice
          get "/admin/users/#{@admin.id}"
          assert_response :success
          assert_select "h2", "Identity"
          assert_select "dd", text: @admin.email
        end

        test "users show renders platform access section" do
          sign_in_to_backoffice
          get "/admin/users/#{@admin.id}"
          assert_response :success
          assert_select "h2", "Platform Access"
        end

        test "users show renders product memberships section" do
          sign_in_to_backoffice
          get "/admin/users/#{@admin.id}"
          assert_response :success
          assert_select "h2", "Product Memberships"
        end

        test "users show renders recent audit events section" do
          sign_in_to_backoffice
          get "/admin/users/#{@admin.id}"
          assert_response :success
          assert_select "h2", "Recent Audit Events"
        end

        test "users show requires backoffice authentication" do
          get "/admin/users/#{@admin.id}"
          assert_redirected_to "/admin/sign_in"
        end

        test "users show 404s for nonexistent user" do
          sign_in_to_backoffice
          get "/admin/users/999999"
          assert_response :not_found
        end

        test "grant super admin promotes a non-admin user" do
          sign_in_to_backoffice
          user = users(:manager)

          assert_changes -> { user.reload.super_admin? }, from: false, to: true do
            post "/admin/users/#{user.id}/grant_super_admin"
          end
          assert_redirected_to "/admin/users/#{user.id}"
          assert_match(/now a super admin/, flash[:notice])
        end

        test "grant super admin on already-admin user is idempotent" do
          sign_in_to_backoffice
          user = users(:admin)

          assert_no_changes -> { user.reload.super_admin? } do
            post "/admin/users/#{user.id}/grant_super_admin"
          end
          assert_redirected_to "/admin/users/#{user.id}"
          assert_match(/already a super admin/, flash[:notice])
        end

        test "revoke super admin removes super admin from a non-admin user" do
          sign_in_to_backoffice
          user = users(:manager)

          user.update!(system_role: :super_admin)
          assert_changes -> { user.reload.super_admin? }, from: true, to: false do
            post "/admin/users/#{user.id}/revoke_super_admin"
          end
          assert_redirected_to "/admin/users/#{user.id}"
          assert_match(/no longer a super admin/, flash[:notice])
        end

        test "revoke super admin on non-admin user is idempotent" do
          sign_in_to_backoffice
          user = users(:manager)

          assert_no_changes -> { user.reload.super_admin? } do
            post "/admin/users/#{user.id}/revoke_super_admin"
          end
          assert_redirected_to "/admin/users/#{user.id}"
          assert_match(/is not a super admin/, flash[:notice])
        end

        test "revoke super admin prevents revoking the last super admin" do
          sign_in_to_backoffice

          User.where.not(id: @admin.id).update_all(system_role: nil)

          post "/admin/users/#{@admin.id}/revoke_super_admin"
          assert_redirected_to "/admin/users/#{@admin.id}"
          assert_match(/Cannot revoke your own super admin access/, flash[:alert])
          assert @admin.reload.super_admin?
        end

        test "grant super admin writes audit event" do
          sign_in_to_backoffice
          user = users(:manager)

          assert_difference -> { Pave::Audit::AuditEvent.where(key: "backoffice.super_admin.granted").count }, 1 do
            post "/admin/users/#{user.id}/grant_super_admin"
          end

          event = Pave::Audit::AuditEvent.where(key: "backoffice.super_admin.granted").last
          assert_equal "User", event.actor_type
          assert_equal @admin.id, event.actor_id
          assert_equal "User", event.target_type
          assert_equal user.id, event.target_id
        end

        test "revoke super admin writes audit event" do
          sign_in_to_backoffice
          user = users(:manager)
          user.update!(system_role: :super_admin)

          assert_difference -> { Pave::Audit::AuditEvent.where(key: "backoffice.super_admin.revoked").count }, 1 do
            post "/admin/users/#{user.id}/revoke_super_admin"
          end

          event = Pave::Audit::AuditEvent.where(key: "backoffice.super_admin.revoked").last
          assert_equal "User", event.actor_type
          assert_equal @admin.id, event.actor_id
          assert_equal "User", event.target_type
          assert_equal user.id, event.target_id
        end

        test "grant super admin requires backoffice authentication" do
          user = users(:manager)
          post "/admin/users/#{user.id}/grant_super_admin"
          assert_redirected_to "/admin/sign_in"
        end

        test "revoke super admin requires backoffice authentication" do
          user = users(:manager)
          post "/admin/users/#{user.id}/revoke_super_admin"
          assert_redirected_to "/admin/sign_in"
        end

        test "users show renders danger zone section" do
          sign_in_to_backoffice
          get "/admin/users/#{@admin.id}"
          assert_response :success
          assert_select "h2", "Danger Zone"
        end

        test "users show renders grant button for non-admin user" do
          sign_in_to_backoffice
          user = users(:manager)
          get "/admin/users/#{user.id}"
          assert_response :success
          assert_select "button", text: "Grant super admin access"
        end

        test "users show renders revoke button for admin user" do
          sign_in_to_backoffice
          get "/admin/users/#{@admin.id}"
          assert_response :success
          assert_select "button", text: "Revoke super admin access"
        end
      end
    end
  end
end

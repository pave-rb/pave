# frozen_string_literal: true

require "test_helper"

module Pave
  module Backoffice
    class AuditHelperTest < ActionDispatch::IntegrationTest
      setup do
        @admin = users(:admin)
      end

      def sign_in_to_backoffice(user)
        post "/admin/sign_in", params: { email: user.email, password: "password123" }
        assert_redirected_to "/admin/"
        follow_redirect!
      end

      test "audit_admin creates audit event with backoffice source" do
        sign_in_to_backoffice(@admin)

        event = @controller.send(:audit_admin, "test.admin_action",
          target: @admin,
          metadata: { detail: "test detail" }
        )

        assert_equal "test.admin_action", event.key
        assert_equal "backoffice", event.source
        assert_equal @admin.id, event.actor_id
        assert_nil event.space_id
        assert event.metadata["backoffice"]
        assert_equal "test detail", event.metadata["detail"]
      end

      test "audit_admin accepts key without target" do
        sign_in_to_backoffice(@admin)

        event = @controller.send(:audit_admin, "test.simple_action")

        assert_equal "test.simple_action", event.key
        assert_equal "backoffice", event.source
        assert_equal @admin.id, event.actor_id
        assert_nil event.space_id
        assert event.metadata["backoffice"]
      end

      test "audit_admin accepts string key" do
        sign_in_to_backoffice(@admin)

        event = @controller.send(:audit_admin, "backoffice.settings.updated",
          target: @admin,
          metadata: { setting: "theme" }
        )

        assert_equal "backoffice.settings.updated", event.key
        assert_equal "backoffice", event.source
        assert event.metadata["backoffice"]
      end

      test "audit_admin creates persisted event" do
        sign_in_to_backoffice(@admin)

        event = @controller.send(:audit_admin, "test.persisted_action")

        assert event.persisted?
        assert event.reload
      end

      test "audit_admin with target stores polymorphic target" do
        sign_in_to_backoffice(@admin)

        target_user = users(:manager)
        event = @controller.send(:audit_admin, "test.targeted_action",
          target: target_user
        )

        assert_equal "User", event.target_type
        assert_equal target_user.id, event.target_id
      end
    end
  end
end

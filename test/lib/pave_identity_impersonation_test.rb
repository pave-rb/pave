# frozen_string_literal: true

require "test_helper"

class PaveIdentityImpersonationTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin)
    @manager = users(:manager)
  end

  test "authorized? returns true for super_admin" do
    assert Pave::Identity::Impersonation.authorized?(@admin)
  end

  test "authorized? returns false for non-admin" do
    assert_not Pave::Identity::Impersonation.authorized?(@manager)
  end

  test "start! writes identity.impersonation.started audit event" do
    event = Pave::Identity::Impersonation.start!(
      actor: @admin,
      target_user: @manager,
      reason: "Support request"
    )

    assert event

    audit_event = Pave::Audit::AuditEvent.where(key: "identity.impersonation.started").last
    assert_not_nil audit_event
    assert_equal @admin.id, audit_event.actor_id
    assert_equal "User", audit_event.actor_type
    assert_equal @manager.id, audit_event.target_id
    assert_equal "Support request", audit_event.metadata["reason"]
  end

  test "start! raises AuthorizationError for unauthorized actor" do
    assert_raises(Pave::AuthorizationError) do
      Pave::Identity::Impersonation.start!(
        actor: @manager,
        target_user: @admin
      )
    end
  end

  test "stop! writes identity.impersonation.stopped audit event" do
    event = Pave::Identity::Impersonation.stop!(
      actor: @admin,
      target_user: @manager
    )

    assert event

    audit_event = Pave::Audit::AuditEvent.where(key: "identity.impersonation.stopped").last
    assert_not_nil audit_event
    assert_equal @admin.id, audit_event.actor_id
    assert_equal @manager.id, audit_event.target_id
  end

  test "stop! works without target_user" do
    event = Pave::Identity::Impersonation.stop!(actor: @admin)

    assert event

    audit_event = Pave::Audit::AuditEvent.where(key: "identity.impersonation.stopped").last
    assert_not_nil audit_event
    assert_nil audit_event.target_id
  end

  test "denied! writes identity.impersonation.denied audit event" do
    event = Pave::Identity::Impersonation.denied!(
      actor: @admin,
      target_user: @manager,
      reason: "No permission"
    )

    assert event

    audit_event = Pave::Audit::AuditEvent.where(key: "identity.impersonation.denied").last
    assert_not_nil audit_event
    assert_equal @admin.id, audit_event.actor_id
    assert_equal @manager.id, audit_event.target_id
    assert_equal "No permission", audit_event.metadata["reason"]
  end

  test "impersonation audit events use expected table schema" do
    column_names = Pave::Audit::AuditEvent.columns.map(&:name)

    assert_includes column_names, "key"
    assert_includes column_names, "actor_type"
    assert_includes column_names, "actor_id"
    assert_includes column_names, "target_type"
    assert_includes column_names, "target_id"
  end

  test "start! accepts optional idempotency_key" do
    key = SecureRandom.hex(8)

    Pave::Identity::Impersonation.start!(
      actor: @admin,
      target_user: @manager,
      idempotency_key: key
    )

    assert_raises(Pave::ConflictError) do
      Pave::Identity::Impersonation.start!(
        actor: @admin,
        target_user: @manager,
        idempotency_key: key
      )
    end
  end
end

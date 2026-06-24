# frozen_string_literal: true

require "test_helper"

class PaveAuditContractsTest < ActiveSupport::TestCase
  test "log writes an audit event and returns success result" do
    result = Pave::Audit.log(key: "test.event", occurred_at: Time.current)

    assert result.success?
    assert_kind_of Pave::Audit::AuditEvent, result.value
    assert_equal "test.event", result.value.key
    assert result.value.persisted?
  end

  test "log! writes and returns the event directly" do
    event = Pave::Audit.log!(key: "test.bang", occurred_at: Time.current)

    assert_kind_of Pave::Audit::AuditEvent, event
    assert_equal "test.bang", event.key
    assert event.persisted?
  end

  test "log returns failure for invalid event" do
    result = Pave::Audit.log(key: nil, occurred_at: Time.current)

    assert result.failure?
  end

  test "log! raises Pave::ValidationError for invalid event" do
    assert_raises(Pave::ValidationError) do
      Pave::Audit.log!(key: nil, occurred_at: Time.current)
    end
  end

  test "log accepts system actors and nil space" do
    result = Pave::Audit.log(
      key: "system.heartbeat",
      actor_label: "System",
      target_label: "Worker",
      metadata: { pool: "default" },
      occurred_at: Time.current
    )

    assert result.success?
    event = result.value
    assert_nil event.actor_type
    assert_nil event.actor_id
    assert_equal "System", event.actor_label
    assert_nil event.space_id
  end

  test "log accepts polymorphic actor with explicit space" do
    space = Pave::Tenancy::Space.create!(name: "Audit Test Space")
    user = users(:manager)

    result = Pave::Audit.log(
      key: "tenancy.space.created",
      actor: user,
      space: space,
      target_label: "Test Audit",
      metadata: { env: "test" },
      occurred_at: Time.current
    )

    assert result.success?
    event = result.value
    assert_equal "User", event.actor_type
    assert_equal user.id, event.actor_id
    assert_equal space.id, event.space_id
  end

  test "log uses Pave::Current space by default when available" do
    space = Pave::Tenancy::Space.create!(name: "Current Space")
    Pave::Tenancy.with_space(space) do
      result = Pave::Audit.log(key: "test.current_space", occurred_at: Time.current)

      assert result.success?
      assert_equal space.id, result.value.space_id
    end
  end

  test "log scopes metadata correctly and rejects unserializable data" do
    result = Pave::Audit.log(
      key: "test.metadata",
      metadata: { string: "ok", number: 42, bool: true, nested: { a: 1 } },
      occurred_at: Time.current
    )

    assert result.success?
    assert_equal "ok", result.value.metadata["string"]
    assert_equal 42, result.value.metadata["number"]
  end

  test "log returns failure for unserializable metadata" do
    result = Pave::Audit.log(
      key: "test.bad_metadata",
      metadata: { object: Object.new },
      occurred_at: Time.current
    )

    assert result.failure?
  end

  test "idempotency key prevents duplicates" do
    key = "idem-#{SecureRandom.hex(8)}"

    first = Pave::Audit.log!(key: "test.idempotent", idempotency_key: key, occurred_at: Time.current)
    assert first.persisted?

    result = Pave::Audit.log(key: "test.idempotent", idempotency_key: key, occurred_at: Time.current)
    assert result.failure?
    assert_kind_of Pave::ConflictError, result.error
  end

  test "audit event is append-only" do
    event = Pave::Audit.log!(key: "test.append_only", occurred_at: Time.current)

    assert_raises(ActiveRecord::ReadOnlyRecord) { event.update!(key: "changed") }
    assert_raises(ActiveRecord::ReadOnlyRecord) { event.destroy! }
  end

  test "event key is required" do
    event = Pave::Audit::AuditEvent.new(occurred_at: Time.current)
    assert_not event.valid?
    assert event.errors[:key].any?
  end

  test "runtime audit uses expected table schema" do
    assert_equal "pave_audit_events", Pave::Audit::AuditEvent.table_name

    column_names = Pave::Audit::AuditEvent.columns.map(&:name)
    assert_includes column_names, "key"
    assert_includes column_names, "actor_type"
    assert_includes column_names, "actor_id"
    assert_includes column_names, "target_type"
    assert_includes column_names, "target_id"
  end

  test "Pave::Audit responds to public API" do
    assert_respond_to Pave::Audit, :log
    assert_respond_to Pave::Audit, :log!
  end
end

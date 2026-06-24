# frozen_string_literal: true

require "test_helper"

class BackofficeAuditTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @event = Pave::Audit::AuditEvent.create!(
      key: "backoffice.settings.updated",
      source: "backoffice",
      occurred_at: Time.current,
      actor_type: "Pave::Identity::User",
      actor_id: @admin.id,
      actor_label: @admin.email,
      metadata: { namespace: "billing", changed_keys: ["api_key"] }
    )
  end

  teardown do
    Pave::Audit::AuditEvent.delete_all
  end

  test "audit index links open event detail in drawer via Turbo Frame" do
    sign_in_to_backoffice(@admin)

    get "/admin/audit"

    assert_response :success
    assert_select "turbo-frame#audit_event_detail"
    assert_select "a[href='/admin/audit/#{@event.id}'][data-turbo-frame='audit_event_detail']"
  end

  test "audit drawer renders event content without full page navigation" do
    sign_in_to_backoffice(@admin)

    get "/admin/audit/#{@event.id}"

    assert_response :success
    assert_select "turbo-frame#audit_event_detail"
    assert_select "[data-backoffice-drawer='true']"
    assert_select "[data-controller='pave--backoffice--drawer']"
    assert_select "h2#audit-event-detail-title", text: "backoffice.settings.updated"
    assert_includes response.body, "Event envelope"
    assert_includes response.body, "Actor and target"
    assert_nil Pave::Current.space
  end

  private

  def sign_in_to_backoffice(user)
    post "/admin/sign_in", params: { email: user.email, password: "password123" }
    assert_redirected_to "/admin/"
  end
end

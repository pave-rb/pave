# frozen_string_literal: true

require "test_helper"

class BackofficeFiltersTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
  end

  teardown do
    Pave::Audit::AuditEvent.delete_all
  end

  test "audit filter form is wired to Turbo Frame with advance and Stimulus controller" do
    sign_in_to_backoffice(@admin)

    get "/admin/audit"

    assert_response :success
    assert_select "turbo-frame#backoffice_audit_index"
    assert_select "form[action='/admin/audit']" do
      assert_select "[data-controller='pave--backoffice--filter-bar']"
      assert_select "[data-turbo-frame='backoffice_audit_index']"
      assert_select "[data-turbo-action='advance']"
    end
    assert_select "[data-backoffice-data-table][data-controller='pave--backoffice--data-table']"
    assert_select "[data-pave--backoffice--data-table-target='loading']"
    assert_select "[data-pave--backoffice--data-table-target='error']"
  end

  test "audit filters serialize to query params and keep the table inside the frame" do
    event = Pave::Audit::AuditEvent.create!(
      key: "backoffice.settings.updated",
      source: "backoffice",
      occurred_at: Time.current,
      actor_type: "Pave::Identity::User",
      actor_id: @admin.id,
      actor_label: @admin.email
    )

    sign_in_to_backoffice(@admin)

    get "/admin/audit", params: { source: "backoffice" }

    assert_response :success
    assert_select "turbo-frame#backoffice_audit_index"
    assert_select "select[name='source'] option[selected][value='backoffice']"
    assert_includes response.body, event.key
  end

  test "audit filter chips render with removable params" do
    sign_in_to_backoffice(@admin)

    get "/admin/audit", params: { actor: "admin" }

    assert_response :success
    assert_select "[data-backoffice-filter-chips]", text: /Actor: admin/
    assert_select "a[href='/admin/audit']", text: "×"
  end

  test "audit table request with Turbo-Frame header skips the layout" do
    sign_in_to_backoffice(@admin)

    get "/admin/audit", headers: { "Turbo-Frame" => "backoffice_audit_index" }

    assert_response :success
    assert_select "turbo-frame#backoffice_audit_index"
    refute_includes response.body, "<title>"
    assert_nil Pave::Current.space
  end

  test "users filter form targets the table frame and filters records" do
    sign_in_to_backoffice(@admin)

    get "/admin/users", params: { platform_access: "1" }

    assert_response :success
    assert_select "turbo-frame#backoffice_users_index"
    assert_select "form[action='/admin/users'][data-turbo-frame='backoffice_users_index'][data-turbo-action='advance']"
    assert_includes response.body, @admin.email
    refute_includes response.body, users(:manager).email
  end

  test "users filter chips serialize query params for clearing" do
    sign_in_to_backoffice(@admin)

    get "/admin/users", params: { q: "manager" }

    assert_response :success
    assert_select "[data-backoffice-filter-chips]", text: /Q: manager/
    assert_select "a[href='/admin/users']", text: "×"
    refute_includes response.body, users(:secretary).email
  end

  test "users table request with Turbo-Frame header skips the layout" do
    sign_in_to_backoffice(@admin)

    get "/admin/users", headers: { "Turbo-Frame" => "backoffice_users_index" }

    assert_response :success
    assert_select "turbo-frame#backoffice_users_index"
    refute_includes response.body, "<title>"
    assert_nil Pave::Current.space
  end

  private

  def sign_in_to_backoffice(user)
    post "/admin/sign_in", params: { email: user.email, password: "password123" }
    assert_redirected_to "/admin/"
  end
end

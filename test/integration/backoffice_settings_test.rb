# frozen_string_literal: true

require "test_helper"

class BackofficeSettingsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    Pave::Backoffice::Setting.delete_all
    Pave::Audit::AuditEvent.delete_all
    Pave::Settings.reset!
    Pave::Settings.adapter = Pave::Backoffice::SettingsAdapter.new
  end

  teardown do
    Pave::Backoffice::Setting.delete_all
    Pave::Settings.reset!
    Pave::Settings.adapter = Pave::Backoffice::SettingsAdapter.new
  end

  test "settings page renders empty state when no schemas exist" do
    sign_in_to_backoffice(@admin)

    get "/admin/settings"

    assert_response :success
    assert_select "h1", text: "Settings"
    assert_select "h2", text: "No settings schemas registered"
  end

  test "settings namespace save stores values and writes audit event" do
    Pave::Settings.define(:billing) do |settings|
      settings.key :api_key, encrypted: true, required: true
      settings.key :retry_count, type: :integer
    end

    sign_in_to_backoffice(@admin)

    patch "/admin/settings", params: {
      namespace: "billing",
      settings: {
        api_key: "database-secret",
        retry_count: "3"
      }
    }

    assert_redirected_to "/admin/settings?namespace=billing"
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Settings saved. A backoffice audit event was recorded."

    assert_equal "database-secret", Pave::Settings.get(:billing, :api_key)
    assert_equal 3, Pave::Settings.get(:billing, :retry_count)

    event = Pave::Audit::AuditEvent.find_by!(key: "backoffice.settings.updated")
    assert_nil event.space_id
    assert_equal "backoffice", event.source
    assert_equal "billing", event.metadata["namespace"]
    assert_equal ["api_key", "retry_count"], event.metadata["changed_keys"]
  end

  test "secret fields never render plaintext by default" do
    Pave::Settings.define(:billing) do |settings|
      settings.key :api_key, encrypted: true, required: true
    end
    Pave::Settings.adapter.write_namespace(
      :billing,
      { api_key: "database-secret" },
      updated_by: Pave::Identity::User.find(@admin.id)
    )

    sign_in_to_backoffice(@admin)

    get "/admin/settings?namespace=billing"

    assert_response :success
    assert_select "[data-pave--backoffice--secret-field-target='maskedValue']", text: /••••••••/
    refute_includes response.body, "database-secret"
    assert_includes response.body, "data-controller=\"pave--backoffice--secret-field\""
  end

  test "settings validation failure does not write audit event" do
    Pave::Settings.define(:billing) do |settings|
      settings.key :api_key, encrypted: true, required: true
      settings.key :retry_count, type: :integer
    end

    sign_in_to_backoffice(@admin)

    patch "/admin/settings", params: {
      namespace: "billing",
      settings: {
        api_key: "",
        retry_count: "not-a-number"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Some settings need attention before they can be saved."
    assert_includes response.body, "must be an integer"
    assert_equal 0, Pave::Audit::AuditEvent.where(key: "backoffice.settings.updated").count
  end

  private

  def sign_in_to_backoffice(user)
    post "/admin/sign_in", params: { email: user.email, password: "password123" }
    assert_redirected_to "/admin/"
  end
end

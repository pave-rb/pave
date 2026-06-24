# frozen_string_literal: true

require "test_helper"

class PaveBackofficeSettingsTest < ActiveSupport::TestCase
  setup do
    Pave::Backoffice::Setting.delete_all
    Pave::Settings.reset!
    Pave::Settings.adapter = Pave::Backoffice::SettingsAdapter.new
  end

  teardown do
    Pave::Backoffice::Setting.delete_all
    Pave::Settings.reset!
  end

  test "settings adapter reads database values before credentials fallback" do
    Pave::Backoffice::Setting.create!(namespace: "billing", key: "api_key", value: "database-secret")

    Rails.application.credentials.stub(:dig, "credentials-secret") do
      assert_equal "database-secret", Pave::Settings.get(:billing, :api_key)
    end
  end

  test "settings adapter writes a namespace using declared value types" do
    Pave::Settings.define(:billing) do |settings|
      settings.key :api_key, type: :string, encrypted: true
      settings.key :retry_count, type: :integer
      settings.key :enabled, type: :boolean
    end

    Pave::Settings.adapter.write_namespace(:billing, {
      api_key: "database-secret",
      retry_count: "3",
      enabled: "1"
    })

    assert_equal "database-secret", Pave::Settings.get(:billing, :api_key)
    assert_equal 3, Pave::Settings.get(:billing, :retry_count)
    assert_equal true, Pave::Settings.get(:billing, :enabled)
  end

  test "settings adapter rejects undeclared namespace and keys" do
    Pave::Settings.define(:billing) { |settings| settings.key :api_key }

    assert_raises(Pave::ConfigurationError) do
      Pave::Settings.adapter.write_namespace(:missing, { api_key: "secret" })
    end

    assert_raises(Pave::ConfigurationError) do
      Pave::Settings.adapter.write_namespace(:billing, { missing: "secret" })
    end
  end

  test "settings adapter exposes source status without plaintext values" do
    Pave::Settings.define(:billing) do |settings|
      settings.key :api_key, encrypted: true, required: true
      settings.key :optional_label
    end

    missing_status = Pave::Settings.adapter.status(:billing, :api_key)
    optional_status = Pave::Settings.adapter.status(:billing, :optional_label)

    assert_equal :missing, missing_status.source
    assert_predicate missing_status, :encrypted
    assert_predicate missing_status, :required
    refute_predicate missing_status, :present
    assert_equal :optional_unset, optional_status.source

    Pave::Settings.adapter.write_namespace(:billing, { api_key: "database-secret" })
    database_status = Pave::Settings.adapter.status(:billing, :api_key)

    assert_equal :database, database_status.source
    assert_predicate database_status, :present
    refute_respond_to database_status, :value
  end

  test "settings adapter treats false credentials fallback as present" do
    Pave::Settings.define(:billing) { |settings| settings.key :enabled, type: :boolean }

    Rails.application.credentials.stub(:dig, false) do
      status = Pave::Settings.adapter.status(:billing, :enabled)

      assert_equal :credentials, status.source
      assert_predicate status, :present
    end
  end

  test "setting preserves updater metadata" do
    user = Pave::Identity::User.find(users(:admin).id)
    Pave::Settings.define(:billing) { |settings| settings.key :api_key }

    Pave::Settings.adapter.write_namespace(:billing, { api_key: "database-secret" }, updated_by: user)

    setting = Pave::Backoffice::Setting.find_by!(namespace: "billing", key: "api_key")

    assert_equal user.id, setting.updated_by.id
  end
end

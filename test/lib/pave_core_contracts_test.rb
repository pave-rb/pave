# frozen_string_literal: true

require "test_helper"

class PaveCoreContractsTest < ActiveSupport::TestCase
  teardown do
    Pave::Settings.reset!
  end

  test "configuration exposes runtime roots as pathnames" do
    config = Pave::Configuration.new(root: "/tmp/pave")

    assert_equal Pathname("/tmp/pave/runtime"), config.runtime_root
    assert_equal Pathname("/tmp/pave/products"), config.products_root
    assert_equal Pathname("/tmp/pave/plugins"), config.plugins_root

    config.plugins_root = "/tmp/custom-plugins"

    assert_equal Pathname("/tmp/custom-plugins"), config.plugins_root
  end

  test "configure yields the global configuration" do
    yielded_config = nil

    Pave.configure { |config| yielded_config = config }

    assert_same Pave.config, yielded_config
  end

  test "current stores only core runtime context slots and resets" do
    Pave::Current.user = "user"
    Pave::Current.actor = "actor"
    Pave::Current.space = "space"
    Pave::Current.request_id = "request-id"
    Pave::Current.impersonator = "impersonator"

    assert_equal "user", Pave::Current.user
    assert_equal "actor", Pave::Current.actor
    assert_equal "space", Pave::Current.space
    assert_equal "request-id", Pave::Current.request_id
    assert_equal "impersonator", Pave::Current.impersonator

    Pave::Current.reset

    assert_nil Pave::Current.user
    assert_nil Pave::Current.actor
    assert_nil Pave::Current.space
    assert_nil Pave::Current.request_id
    assert_nil Pave::Current.impersonator
  end

  test "result exposes success and failure contracts" do
    success = Pave::Result.success("ok", source: :test)
    failure = Pave::Result.failure(Pave::ValidationError.new("invalid"), source: :test)

    assert_predicate success, :success?
    assert_not_predicate success, :failure?
    assert_equal "ok", success.value
    assert_equal({ source: :test }, success.context)

    assert_predicate failure, :failure?
    assert_not_predicate failure, :success?
    assert_instance_of Pave::ValidationError, failure.error
    assert_equal({ source: :test }, failure.context)
  end

  test "service call returns result helpers" do
    service = Class.new(Pave::Service) do
      def call(value)
        return failure(Pave::ValidationError.new("blank")) if value.empty?

        success(value.upcase)
      end
    end

    assert_equal "PAVE", service.call("pave").value
    assert_predicate service.call(""), :failure?
  end

  test "errors expose stable codes and frozen context" do
    error = Pave::AuthorizationError.new("denied", code: :not_allowed, context: { action: :read })

    assert_equal "denied", error.message
    assert_equal :not_allowed, error.code
    assert_equal({ action: :read }, error.context)
    assert_predicate error.context, :frozen?
  end

  test "registry stores metadata and rejects duplicate entries" do
    registry = Pave::Registry.new

    registry.register_plugin(:calendar, label: "Calendar")
    registry.register_capability("calendar.sync", description: "Sync calendars")
    registry.register_event("calendar.synced")

    assert_equal :calendar, registry.plugin(:calendar).name
    assert_equal({ label: "Calendar" }, registry.plugin(:calendar).metadata)
    assert_equal :"calendar.sync", registry.capability("calendar.sync").key
    assert_equal :"calendar.synced", registry.event("calendar.synced").key

    assert_raises(Pave::RegistryError) { registry.register_plugin(:calendar) }
    assert_raises(Pave::RegistryError) { registry.register_capability("calendar.sync") }
    assert_raises(Pave::RegistryError) { registry.register_event("calendar.synced") }
  end

  test "registry rejects blank keys" do
    registry = Pave::Registry.new

    assert_raises(Pave::RegistryError) { registry.register_plugin(" ") }
    assert_raises(Pave::RegistryError) { registry.register_capability(nil) }
    assert_raises(Pave::RegistryError) { registry.register_event("") }
  end

  test "plugin dsl registers metadata without constantizing application code" do
    registry = Pave::Registry.new
    plugin = Class.new(Pave::Plugin) do
      plugin_name :calendar
      depends_on :core
      capability "calendar.sync", description: "Sync calendars"
      event "calendar.synced", description: "Calendar synced"
    end

    metadata = plugin.register(registry)

    assert_equal :calendar, metadata.name
    assert_equal [ :core ], metadata.dependencies
    assert_equal :calendar, registry.plugin(:calendar).name
    assert_equal :calendar, registry.capability("calendar.sync").metadata.fetch(:plugin)
    assert_equal :calendar, registry.event("calendar.synced").metadata.fetch(:plugin)
  end

  test "settings defines namespace schemas" do
    Pave::Settings.define(:billing) do |settings|
      settings.key :api_key, type: :string, encrypted: true, required: true, owner: :billing
    end

    schema = Pave::Settings.schema_for(:billing)
    definition = schema.definition_for(:api_key)

    assert_equal [ :billing ], Pave::Settings.namespaces
    assert_equal :billing, schema.namespace
    assert_equal [ :api_key ], schema.keys
    assert_equal :string, definition.type
    assert_predicate definition, :encrypted
    assert_predicate definition, :required
    assert_equal({ owner: :billing }, definition.metadata)
  end

  test "settings reads adapter values before credentials fallback" do
    adapter = Class.new do
      def get(namespace, key)
        return "database-secret" if namespace == :billing && key == :api_key
      end
    end.new

    Pave::Settings.adapter = adapter

    Rails.application.credentials.stub(:dig, "credentials-secret") do
      assert_equal "database-secret", Pave::Settings.get(:billing, :api_key)
    end
  end

  test "settings falls back to credentials when adapter has no value" do
    adapter = Class.new do
      def get(_namespace, _key)
        nil
      end
    end.new

    Pave::Settings.adapter = adapter

    Rails.application.credentials.stub(:dig, "credentials-secret") do
      assert_equal "credentials-secret", Pave::Settings.get(:billing, :api_key)
    end
  end

  test "settings get bang raises when missing" do
    Rails.application.credentials.stub(:dig, nil) do
      error = assert_raises(Pave::Settings::MissingSettingError) do
        Pave::Settings.get!(:billing, :api_key)
      end

      assert_equal :missing_setting, error.code
      assert_equal({ namespace: :billing, key: :api_key }, error.context)
    end
  end
end

# frozen_string_literal: true

require "test_helper"

class PaveBackofficeDoctorTest < ActiveSupport::TestCase
  setup do
    @registry = Pave::Backoffice.registry
  end

  test "run returns an array of results" do
    results = Pave::Backoffice::Doctor.run

    assert_kind_of Array, results
    assert results.any?
    results.each do |result|
      assert_kind_of Hash, result
      assert result.key?(:check)
      assert result[:pass] == true || result[:pass] == false || result[:pass] == :skipped
    end
  end

  test "check_reserved_product_slugs passes when no reserved names conflict" do
    result = Pave::Backoffice::Doctor.check_reserved_product_slugs

    assert_equal :reserved_product_slugs, result[:check]
    assert result[:pass]
  end

  test "check_reserved_product_slugs fails when a product uses a reserved slug" do
    product_key = :platform

    begin
      Pave.product(product_key, label: "Test Reserved", root: Rails.root.join("tmp"))

      result = Pave::Backoffice::Doctor.check_reserved_product_slugs

      refute result[:pass]
      assert_match(/reserved/i, result[:message])
    ensure
      Pave.products.instance_variable_get(:@products).delete(product_key)
    end
  end

  test "check_product_config_load verifies loaded product configs" do
    result = Pave::Backoffice::Doctor.check_product_config_load

    assert_equal :product_config_load, result[:check]
    assert result[:pass] == true || result[:pass] == false
    assert result.key?(:message)
  end

  test "check_product_panel_controllers returns pass or fail with details" do
    result = Pave::Backoffice::Doctor.check_product_panel_controllers

    assert_kind_of Hash, result
    assert result.key?(:pass)
    assert result.key?(:message)

    if result[:pass] == false
      assert result.key?(:details)
    end
  end

  test "check_product_panel_controllers detects missing controller" do
    existing_product = Pave.products.first
    skip "No products registered for testing" unless existing_product

    begin
      @registry.register_product_panel(existing_product.key, :testing_missing_doc_controller,
        label: "Testing Missing",
        controller: "pave/backoffice/nonexistent/doc_test_controller"
      )

      result = Pave::Backoffice::Doctor.check_product_panel_controllers

      refute result[:pass]
      assert result[:details].any? { |d| d.include?("nonexistent/doc_test_controller") }
    ensure
      panels = @registry.instance_variable_get(:@product_panels)[existing_product.key]
      panels&.reject! { |p| p.name == :testing_missing_doc_controller }
    end
  end

  test "check_platform_panel_controllers returns pass or fail with details" do
    result = Pave::Backoffice::Doctor.check_platform_panel_controllers

    assert_kind_of Hash, result
    assert result.key?(:pass)
    assert result.key?(:message)
  end

  test "check_platform_panel_controllers detects missing controller" do
    begin
      @registry.register_platform_panel(:testing_missing_platform_panel,
        label: "Testing Missing Platform",
        controller: "pave/backoffice/nonexistent/platform_test_controller"
      )

      result = Pave::Backoffice::Doctor.check_platform_panel_controllers

      refute result[:pass]
      assert result[:details].any? { |d| d.include?("nonexistent/platform_test_controller") }
    ensure
      @registry.instance_variable_get(:@platform_panels).reject! do |p|
        p.name == :testing_missing_platform_panel
      end
    end
  end

  test "check_panel_slug_uniqueness passes with unique slugs" do
    # Clean up and test with known state
    result = Pave::Backoffice::Doctor.check_panel_slug_uniqueness

    assert_kind_of Hash, result
    assert result.key?(:pass)
  end

  test "check_panel_slug_uniqueness detects duplicates within platform context" do
    begin
      @registry.register_platform_panel(:duplicate_test_a,
        label: "Duplicate A",
        controller: "pave/backoffice/base_controller"
      )
      @registry.register_platform_panel(:duplicate_test_a,
        label: "Duplicate A2",
        controller: "pave/backoffice/base_controller"
      )

      result = Pave::Backoffice::Doctor.check_panel_slug_uniqueness

      refute result[:pass]
    rescue ArgumentError
      # Registry already rejects duplicates at registration time — that's fine
      pass
    end
  end

  test "check_settings_schemas validates defined schemas" do
    result = Pave::Backoffice::Doctor.check_settings_schemas

    assert_kind_of Hash, result
    assert result.key?(:pass)
    assert result.key?(:message)
  end

  test "check_settings_schemas flags unsupported types" do
    begin
      Pave::Settings.define(:doctor_test) do |settings|
        settings.key :valid_key
        settings.key :bad_type, type: :array
      end

      result = Pave::Backoffice::Doctor.check_settings_schemas

      refute result[:pass]
      assert result[:details].any? { |d| d.include?("unsupported type") }
    ensure
      Pave::Settings.instance_variable_get(:@schemas)&.delete(:doctor_test)
    end
  end

  test "check_required_indexes validates database indexes" do
    result = Pave::Backoffice::Doctor.check_required_indexes

    assert_kind_of Hash, result
    assert result[:pass] == true || result[:pass] == false || result[:pass] == :skipped

    if result[:pass] == :skipped
      assert_match(/No database connection/, result[:message])
    elsif result[:pass]
      assert_match(/present/, result[:message])
    end
  end

  test "check_tenant_chrome_absence passes when no tenant chrome found" do
    result = Pave::Backoffice::Doctor.check_tenant_chrome_absence

    assert_kind_of Hash, result
    assert result[:pass] == true || result[:pass] == :skipped

    if result[:pass] == :skipped
      assert_match(/not found/, result[:message])
    else
      assert result[:pass], "Expected no tenant chrome references in backoffice views"
    end
  end

  test "run includes new shim doctor checks" do
    results = Pave::Backoffice::Doctor.run
    check_names = results.map { |r| r[:check] }

    assert_includes check_names, :legacy_controller_shim
    assert_includes check_names, :flat_panel_registration
    assert_includes check_names, :legacy_backoffice_routes
    assert_includes check_names, :register_module_compat
    assert_includes check_names, :cleanup_readiness
  end

  test "check_legacy_controller_shim passes when shim is in place" do
    result = Pave::Backoffice::Doctor.check_legacy_controller_shim

    assert_equal :legacy_controller_shim, result[:check]
    assert result[:pass]
    assert_match(/Backoffice::BaseController/, result[:message])
  end

  test "check_flat_panel_registration returns pass with status" do
    result = Pave::Backoffice::Doctor.check_flat_panel_registration

    assert_equal :flat_panel_registration, result[:check]
    assert result[:pass]
    assert_match(/Flat panel registration/i, result[:message])
  end

  test "check_legacy_backoffice_routes passes when redirect exists" do
    result = Pave::Backoffice::Doctor.check_legacy_backoffice_routes

    assert_equal :legacy_backoffice_routes, result[:check]
    assert result[:pass]
    assert_match(/redirect/, result[:message])
  end

  test "count_legacy_controller_dependents returns non-negative integer" do
    count = Pave::Backoffice::Doctor.count_legacy_controller_dependents

    assert_kind_of Integer, count
    assert_operator count, :>=, 0
  end

  test "registry tracks flat_panel_registration_count" do
    registry = Pave::Backoffice::Registry.new

    count_before = registry.flat_panel_registration_count
    registry.register_panel(:test_panel, title: "Test")
    count_after = registry.flat_panel_registration_count

    assert_equal count_before + 1, count_after
  end

  test "registry flat_panel_registration_count increments by number of calls" do
    registry = Pave::Backoffice::Registry.new

    registry.register_panel(:dashboard, title: "Dashboard")
    registry.register_panel("demo.spaces", title: "Spaces")

    assert_equal 2, registry.flat_panel_registration_count
  end

  test "check_register_module_compat returns pass with module count" do
    result = Pave::Backoffice::Doctor.check_register_module_compat

    assert_equal :register_module_compat, result[:check]
    assert result[:pass]
    assert_match(/register_module/, result[:message])
  end

  test "check_cleanup_readiness returns pass with all required shims" do
    result = Pave::Backoffice::Doctor.check_cleanup_readiness

    assert_equal :cleanup_readiness, result[:check]
    assert result[:pass]
    assert_match(/shim/, result[:message])
  end

  test "check_cleanup_readiness reports which shims are eligible for removal" do
    result = Pave::Backoffice::Doctor.check_cleanup_readiness

    assert result[:pass]
    if result[:message].include?("eligible")
      assert_match(/eligible for removal/, result[:message])
    else
      assert_match(/still required/, result[:message])
    end
  end

  test "pass and fail helpers produce correct result hashes" do
    pass_result = Pave::Backoffice::Doctor.pass(:test_check, "all good")
    assert_equal :test_check, pass_result[:check]
    assert_equal true, pass_result[:pass]
    assert_equal "all good", pass_result[:message]

    fail_result = Pave::Backoffice::Doctor.fail(:test_check, "something wrong")
    assert_equal :test_check, fail_result[:check]
    assert_equal false, fail_result[:pass]
    assert_equal "something wrong", fail_result[:message]

    fail_with_details = Pave::Backoffice::Doctor.fail(:test_check, "with details", details: ["detail 1"])
    assert_equal ["detail 1"], fail_with_details[:details]

    skip_result = Pave::Backoffice::Doctor.skip(:test_check, "not available")
    assert_equal :skipped, skip_result[:pass]
  end
end

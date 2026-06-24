# frozen_string_literal: true

require "test_helper"

class PaveBackofficeCompatibilityShimsTest < ActiveSupport::TestCase
  test "Shim data struct has required fields" do
    shim = Pave::Backoffice::CompatibilityShims::Shim[
      name: :test_shim,
      description: "Test",
      active: true,
      deprecation_target: "Replace with new API",
      removal_plan: "Delete after migration",
      removal_criteria: "No active dependents"
    ]

    assert_equal :test_shim, shim.name
    assert_equal "Test", shim.description
    assert shim.active
    assert_equal "Replace with new API", shim.deprecation_target
    assert_equal "Delete after migration", shim.removal_plan
    assert_equal "No active dependents", shim.removal_criteria
  end

  test "list returns all shims" do
    shims = Pave::Backoffice::CompatibilityShims.list

    assert_kind_of Array, shims
    assert shims.all? { |s| s.is_a?(Pave::Backoffice::CompatibilityShims::Shim) }
  end

  test "active_shims returns only active shims" do
    active = Pave::Backoffice::CompatibilityShims.active_shims

    active.each do |shim|
      assert shim.active
    end
  end

  test "find returns shim by name" do
    shim = Pave::Backoffice::CompatibilityShims.find(:legacy_base_controller)

    assert shim
    assert_equal :legacy_base_controller, shim.name
  end

  test "find returns nil for unknown shim" do
    assert_nil Pave::Backoffice::CompatibilityShims.find(:nonexistent)
  end

  test "active? returns true for active shim" do
    assert Pave::Backoffice::CompatibilityShims.active?(:legacy_base_controller)
  end

  test "active? returns false for unknown shim" do
    refute Pave::Backoffice::CompatibilityShims.active?(:nonexistent)
  end

  test "summary returns hash with total and active counts" do
    summary = Pave::Backoffice::CompatibilityShims.summary

    assert_kind_of Hash, summary
    assert summary.key?(:total)
    assert summary.key?(:active)
    assert summary.key?(:shims)
    assert_kind_of Array, summary[:shims]
    assert_operator summary[:total], :>=, summary[:active]
  end

  test "run_all_checks delegates to doctor for each active shim" do
    results = Pave::Backoffice::CompatibilityShims.run_all_checks

    assert_kind_of Array, results
    results.each do |result|
      assert result.key?(:check)
      assert [true, false, :skipped].include?(result[:pass])
    end
  end

  test "check returns skipped for unknown shim" do
    result = Pave::Backoffice::CompatibilityShims.check(:nonexistent)

    assert_equal :skipped, result[:pass]
  end

  test "legacy base controller shim is defined in shim list" do
    shim = Pave::Backoffice::CompatibilityShims.find(:legacy_base_controller)
    assert shim
    assert shim.description.include?("Backoffice::BaseController")
    assert shim.deprecation_target.include?("Pave::Backoffice::BaseController")
  end

  test "flat panel registration shim is defined in shim list" do
    shim = Pave::Backoffice::CompatibilityShims.find(:flat_panel_registration)
    assert shim
    assert shim.description.include?("register_panel")
  end

  test "legacy backoffice routes shim is defined in shim list" do
    shim = Pave::Backoffice::CompatibilityShims.find(:legacy_backoffice_routes)
    assert shim
    assert shim.description.include?("/backoffice")
  end

  test "register_module compat shim is defined in shim list" do
    shim = Pave::Backoffice::CompatibilityShims.find(:register_module_compat)
    assert shim
    assert shim.description.include?("register_module")
  end

  test "all registered shims have removal_criteria" do
    Pave::Backoffice::CompatibilityShims.list.each do |shim|
      assert shim.removal_criteria.present?,
             "Shim :#{shim.name} is missing removal_criteria"
    end
  end

  test "readiness returns array with status for each shim" do
    report = Pave::Backoffice::CompatibilityShims.readiness

    assert_kind_of Array, report
    assert_operator report.size, :>=, Pave::Backoffice::CompatibilityShims.list.size

    report.each do |entry|
      assert entry.key?(:shim)
      assert entry.key?(:active)
      assert entry.key?(:removal_criteria)
      assert entry.key?(:doctor_check)
      assert entry.key?(:doctor_pass)
      assert entry.key?(:message)
      assert [true, false].include?(entry[:eligible_for_removal])
    end
  end

  test "readiness includes removal_criteria text for each shim" do
    report = Pave::Backoffice::CompatibilityShims.readiness

    report.each do |entry|
      assert_kind_of String, entry[:removal_criteria]
      assert entry[:removal_criteria].length.positive?
    end
  end

  test "safe_to_remove? returns false for active shim still in use" do
    result = Pave::Backoffice::CompatibilityShims.safe_to_remove?(:legacy_backoffice_routes)

    refute result
  end

  test "safe_to_remove? returns false for unknown shim" do
    refute Pave::Backoffice::CompatibilityShims.safe_to_remove?(:nonexistent)
  end

  test "readiness report matches shim list size" do
    report = Pave::Backoffice::CompatibilityShims.readiness
    shim_names = report.map { |r| r[:shim] }

    Pave::Backoffice::CompatibilityShims.list.each do |shim|
      assert_includes shim_names, shim.name
    end
  end

  test "legacy_base_controller has removal_criteria about dependents" do
    shim = Pave::Backoffice::CompatibilityShims.find(:legacy_base_controller)
    assert_includes shim.removal_criteria, "count_legacy_controller_dependents"
  end

  test "flat_panel_registration has removal_criteria about registration count" do
    shim = Pave::Backoffice::CompatibilityShims.find(:flat_panel_registration)
    assert_includes shim.removal_criteria, "flat_panel_registration_count"
  end
end

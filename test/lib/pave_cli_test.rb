# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"

class PaveCliTest < ActiveSupport::TestCase
  def run_pave(*args)
    Open3.capture3(
      { "RAILS_ENV" => "test" },
      RbConfig.ruby,
      Rails.root.join("bin/pave").to_s,
      *args,
      chdir: Rails.root.to_s
    )
  end

  test "help prints available commands" do
    stdout, stderr, status = run_pave("help")

    assert status.success?, stderr
    assert_includes stdout, "Usage: bin/pave COMMAND"
    assert_includes stdout, "doctor"
  end

  test "version prints runtime version" do
    stdout, stderr, status = run_pave("version")

    assert status.success?, stderr
    assert_match(/\Apave \d+\.\d+\.\d+\n\z/, stdout)
  end

  test "doctor checks runtime scaffold" do
    stdout, stderr, status = run_pave("doctor")

    assert_includes stdout, "Pave runtime doctor"
    assert_includes stdout, "PASS gems directory"
    assert_includes stdout, "PASS pave-core require"
    assert_includes stdout, "PASS pave-core APIs"
    assert_includes stdout, "PASS pave-tenancy APIs"
    assert_includes stdout, "PASS pave-tenancy models"
    assert_includes stdout, "PASS pave-audit APIs"
    assert_includes stdout, "PASS Rails boot"
    assert_includes stdout, "PASS Packwerk availability"
    assert_includes stdout, "PASS runtime dependency graph"
    assert_includes stdout, "PASS runtime anti-contamination"
  end

  test "doctor prints backoffice check labels" do
    stdout, stderr, status = run_pave("doctor")

    assert_includes stdout, "backoffice: reserved product slugs"
    assert_includes stdout, "backoffice: product config load"
    assert_includes stdout, "backoffice: product panel controllers"
    assert_includes stdout, "backoffice: platform panel controllers"
    assert_includes stdout, "backoffice: panel slug uniqueness"
    assert_includes stdout, "backoffice: settings schemas"
    assert_includes stdout, "backoffice: required indexes"
    assert_includes stdout, "backoffice: tenant chrome absence"
  end

  test "context prints repo info" do
    stdout, stderr, status = run_pave("context")

    assert status.success?, stderr
    assert_includes stdout, "Pav\u00EA Runtime Repository Context"
    assert_includes stdout, "pave-core"
    assert_includes stdout, "DemoScheduling"
    assert_includes stdout, "repo:check-clean"
  end

  test "doctor --upgrade prints expected checks" do
    stdout, stderr, status = run_pave("doctor", "--upgrade")

    assert status.success?, stderr
    assert_includes stdout, "upgrade doctor"
    assert_includes stdout, "Bundler runtime version bump"
    assert_includes stdout, "Generated config reconciliation"
  end

  test "list products succeeds" do
    stdout, stderr, status = run_pave("list", "products")

    assert status.success?, stderr
  end

  test "repo:check-clean runs without error" do
    stdout, stderr, status = run_pave("repo:check-clean")

    assert_includes [0, 1], status.exitstatus,
      "Expected exit 0 (clean) or 1 (contamination found), got #{status.exitstatus}: #{stderr}"
    assert(stdout.include?("PASS") || stdout.include?("FAIL"),
      "Expected PASS or FAIL in output")
  end

  test "install:migrations is a stub" do
    stdout, stderr, status = run_pave("install:migrations")

    assert status.success?, stderr
    assert_includes stdout, "stub"
  end

  test "upgrade is a stub" do
    stdout, stderr, status = run_pave("upgrade")

    assert status.success?, stderr
    assert_includes stdout, "stub"
  end

  test "app:update is a stub" do
    stdout, stderr, status = run_pave("app:update")

    assert status.success?, stderr
    assert_includes stdout, "stub"
  end

  test "unknown command shows error" do
    stdout, stderr, status = run_pave("nonexistent")

    assert_not status.success?
    assert_includes stderr, "Unknown command"
  end

  test "new product without name shows usage" do
    stdout, stderr, status = run_pave("new", "product")

    assert_not status.success?
    assert_includes stderr, "Usage"
  end
end

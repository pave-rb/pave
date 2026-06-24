# frozen_string_literal: true

require "open3"
require "pathname"
require "yaml"

module PaveCli
  PACKAGES = {
    "pave-core" => "pave/core",
    "pave-tenancy" => "pave/tenancy",
    "pave-audit" => "pave/audit",
    "pave-identity" => "pave/identity",
    "pave-billing" => "pave/billing",
    "pave-backoffice" => "pave/backoffice"
  }.freeze
  PACKAGE_DEPENDENCIES = {
    "gems/pave-core" => [],
    "gems/pave-tenancy" => ["gems/pave-core"],
    "gems/pave-audit" => ["gems/pave-core", "gems/pave-tenancy"],
    "gems/pave-identity" => ["gems/pave-core", "gems/pave-tenancy", "gems/pave-audit"],
    "gems/pave-billing" => ["gems/pave-core", "gems/pave-tenancy", "gems/pave-audit"],
    "gems/pave-backoffice" => [
      "gems/pave-core",
      "gems/pave-tenancy",
      "gems/pave-audit",
      "gems/pave-identity",
      "gems/pave-billing"
    ]
  }.freeze
  FORBIDDEN_RUNTIME_PATTERN = /Appointment|Whatsapp|WhatsApp|Asaas|booking|clinic|salon/.freeze

  module_function

  def root
    @root || Pathname.new(File.expand_path("../..", __dir__))
  end

  def run(argv, root: nil)
    @root = Pathname.new(root) if root
    case argv.first
    when nil, "help", "--help", "-h"
      puts help_text
      0
    when "version", "--version", "-v"
      print_version
    when "doctor"
      if argv.include?("--upgrade")
        doctor_upgrade
      else
        doctor
      end
    when "context"
      generate_context
    when "new"
      if argv[1] == "product" && argv[2]
        new_product(argv[2])
      else
        warn "Usage: bin/pave new product <name>"
        1
      end
    when "list"
      if argv[1] == "products"
        list_products
      else
        warn "Unknown list target: #{argv[1]}"
        warn "Usage: bin/pave list products"
        1
      end
    when "install:migrations"
      install_migrations
    when "upgrade"
      upgrade
    when "app:update"
      app_update
    when "repo:check-clean"
      repo_check_clean
    else
      warn "Unknown command: #{argv.first}"
      warn help_text
      1
    end
  end

  def help_text
    <<~HELP
      Usage: bin/pave COMMAND

      Commands:
        help                Show this help
        version             Print the Pav\u00ea runtime version
        doctor              Run runtime health checks
        doctor --upgrade    Print planned upgrade checks (stub)
        context             Generate an agent context snapshot
        new product <name>  Generate a new product scaffold
        list products       List registered products
        install:migrations  Copy runtime engine migrations to the host app (stub)
        upgrade             Print an upgrade plan and run safe reconciliations (stub)
        app:update          Update host app config (stub)
        repo:check-clean    Check for Anella contamination in the repository
    HELP
  end

  def print_version
    require "pave/core"
    puts "pave #{Pave::Core::VERSION}"
    0
  rescue LoadError => error
    warn "Cannot load pave-core: #{error.message}"
    1
  end

  def doctor_upgrade
    puts "Pave runtime upgrade doctor (planned)"
    puts
    puts "The following upgrade checks are planned but not yet implemented:"
    puts "  - Bundler runtime version bump"
    puts "  - Generated config reconciliation"
    puts "  - Runtime migrations"
    puts "  - Product/plugin compatibility"
    puts "  - AGENTS.md and context regeneration"
    puts "  - pave.lock update"
    puts "  - Upgrade report generation"
    0
  end

  def doctor
    failures = []

    puts "Pave runtime doctor"

    failures << "gems directory" unless check("gems directory") { root.join("gems").directory? }

    PACKAGES.each do |package, require_path|
      package_root = root.join("gems", package)

      failures << "#{package} package files" unless check("#{package} package files") do
        [
          package_root.join("#{package}.gemspec"),
          package_root.join("lib", "#{require_path}.rb"),
          package_root.join("lib", *require_path.split("/"), "version.rb"),
          package_root.join("lib", *require_path.split("/"), "engine.rb"),
          package_root.join("package.yml"),
          package_root.join("README.md")
        ].all?(&:exist?)
      end

      failures << "#{package} require" unless check("#{package} require") { require require_path }
    rescue StandardError, LoadError => error
      failures << "#{package} require: #{error.class}: #{error.message}"
      puts "FAIL #{package} require (#{error.class}: #{error.message})"
    end

    failures << "pave-core APIs" unless check("pave-core APIs") do
      require "pave/core"
      [
        Pave.config,
        Pave.registry,
        Pave::Configuration,
        Pave::Current,
        Pave::Service,
        Pave::Result,
        Pave::Error,
        Pave::Registry,
        Pave::Plugin
      ].all?
    end

    failures << "pave-tenancy APIs" unless check("pave-tenancy APIs") do
      require "pave/tenancy"
      [
        Pave::Tenancy,
        Pave::Tenancy.method(:with_space),
        Pave::Tenancy.method(:current_space),
        Pave::Tenancy.method(:space_required!),
        Pave::Tenancy.method(:assert_same_space!)
      ].all?
    end

    failures << "Rails boot" unless check("Rails boot") { require root.join("config/environment").to_s }

    if Rails.application
      failures << "pave-tenancy models" unless check("pave-tenancy models") do
        [
          Pave::Tenancy::Space,
          Pave::Tenancy::SpaceMembership,
          Pave::Tenancy::BaseController
        ].all?
      end

      failures << "pave-audit APIs" unless check("pave-audit APIs") do
        require "pave/audit"
        [
          Pave::Audit,
          Pave::Audit.method(:log),
          Pave::Audit.method(:log!),
          Pave::Audit::AuditEvent,
          Pave::Audit::Error
        ].all?
      end
      failures << "pave-identity APIs" unless check("pave-identity APIs") do
        require "pave/identity"
        [
          Pave::Identity,
          Pave::Identity.method(:current_user),
          Pave::Identity.method(:current_actor),
          Pave::Identity.method(:current_impersonator),
          Pave::Identity::User,
          Pave::Identity::Impersonation,
          Pave::Identity::Impersonation.method(:start!),
          Pave::Identity::Impersonation.method(:stop!),
          Pave::Identity::Impersonation.method(:denied!),
          Pave::Identity::Impersonation.method(:authorized?)
        ].all?
      end

      failures << "pave-billing APIs" unless check("pave-billing APIs") do
        require "pave/billing"
        [
          Pave::Billing,
          Pave::Billing.method(:allowed?),
          Pave::Billing.method(:enforce!),
          Pave::Billing.method(:debit_credit!),
          Pave::Billing.method(:grant_credit!),
          Pave::Billing.method(:current_balance),
          Pave::Billing::Plan,
          Pave::Billing::Subscription,
          Pave::Billing::BillingEvent,
          Pave::Billing::CreditTransaction,
          Pave::Billing::ProviderAdapter,
          Pave::Billing::WebhookHandler,
          Pave::Billing::NullAdapter
        ].all?
      end

      run_backoffice_doctor(failures)
    end

    failures << "Packwerk availability" unless check("Packwerk availability") { gem_available?("packwerk") }
    failures << "Packwerk config" unless check("Packwerk config") { root.join("packwerk.yml").file? && root.join("package.yml").file? }
    failures << "runtime dependency graph" unless check("runtime dependency graph") { runtime_dependency_graph_valid? }
    failures << "runtime anti-contamination" unless check("runtime anti-contamination") { runtime_product_references.empty? }
    failures << "Packwerk validation" unless check("Packwerk validation") { run_command("bundle", "exec", "packwerk", "validate") }
    failures << "Packwerk dependency enforcement" unless check("Packwerk dependency enforcement") { run_command("bundle", "exec", "packwerk", "check") }

    failures.empty? ? 0 : 1
  rescue StandardError, LoadError => error
    puts "FAIL #{error.class}: #{error.message}"
    1
  end

  def generate_context
    puts <<~CONTEXT
      # Pav\u00ea Runtime Repository Context

      Repository: pave-rb/pave
      Type: runtime_source_monorepo
      Description: Produces Pav\u00ea gems and runtime tooling consumed by host apps.

      ## Packages

      #{PACKAGES.map { |name, _| "- #{name}" }.join("\n")}

      ## Test Fixture

      Dummy product: DemoScheduling (under test/dummy/products/demo_scheduling)

      ## Agent Instructions

      See AGENTS.md for full agent behavior guidelines.

      ## CLI Surface

      bin/pave help          -- list commands
      bin/pave version       -- print version
      bin/pave doctor        -- runtime health checks
      bin/pave context       -- this output
      bin/pave list products -- list registered products
      bin/pave repo:check-clean -- check for Anella contamination
    CONTEXT
    0
  end

  def new_product(name)
    rails_bin = root.join("bin/rails")
    if rails_bin.exist?
      exec rails_bin.to_s, "generate", "pave:product", name
    else
      warn "Rails not found in this repository. Run this command from a host app."
      1
    end
  end

  def list_products
    require "pave/core"
    puts "  (no products registered)"
    0
  end

  def install_migrations
    puts "Pave install:migrations (stub)"
    puts
    puts "This command will copy runtime engine migrations to the host app."
    puts "Not yet implemented."
    0
  end

  def upgrade
    puts "Pave upgrade (stub)"
    puts
    puts "This command will upgrade the Pav\u00ea runtime in the current host app."
    puts "Planned steps:"
    puts "  1. Check current runtime version"
    puts "  2. Resolve latest compatible version"
    puts "  3. Update Gemfile and run bundle update"
    puts "  4. Run pending runtime migrations"
    puts "  5. Regenerate agent context"
    puts "  6. Generate upgrade report"
    puts
    puts "Use 'bin/pave doctor --upgrade' to preview planned upgrade checks."
    0
  end

  def app_update
    puts "Pave app:update (stub)"
    puts
    puts "This command will update host app config files and initializers."
    puts "Not yet implemented."
    0
  end

  def repo_check_clean
    require "open3"

    stdout, stderr, status = Open3.capture3(
      "grep", "-R", "Anella\\|anella\\|ANELLA", ".",
      "--exclude-dir=.git",
      "--exclude-dir=.agents",
      "--exclude-dir=.DS_Store",
      "--exclude-dir=log",
      "--exclude-dir=tmp",
      "--exclude-dir=vendor",
      "--exclude-dir=public",
      "--exclude-dir=db",
      "--exclude-dir=node_modules",
      "--exclude-dir=storage",
      "--exclude-dir=coverage",
      "--exclude='*.png'",
      "--exclude='*.jpg'",
      "--exclude='*.gif'",
      "--exclude='*.ico'",
      "--exclude='*.svg'",
      "--exclude='*.pdf'",
      "--exclude=SPEC_CLEAN_PAVE_REPO.md"
    )

    if stdout.empty? && status.success?
      puts "PASS No Anella references found."
      0
    else
      puts "FAIL Anella references found:"
      puts stdout
      unless stderr.empty?
        warn stderr
      end
      1
    end
  rescue Errno::ENOENT => error
    warn "Cannot run check: #{error.message}"
    1
  end

  def run_backoffice_doctor(failures)
    return unless defined?(Pave::Backoffice::Doctor)

    backoffice_checks = Pave::Backoffice::Doctor.run
    backoffice_checks.each do |result|
      label = "backoffice: #{result[:check].to_s.tr('_', ' ')}"
      case result[:pass]
      when true
        puts "PASS #{label}"
      when :skipped
        puts "SKIP #{label} (#{result[:message]})"
      else
        puts "FAIL #{label} (#{result[:message]})"
        Array(result[:details]).each { |detail| puts "  #{detail}" }
        failures << label
      end
    end
  end

  def check(label, required: true)
    if yield
      puts "PASS #{label}"
      true
    elsif required
      puts "FAIL #{label}"
      false
    else
      puts "SKIP #{label} (not installed)"
      true
    end
  rescue StandardError, LoadError => error
    if required
      puts "FAIL #{label} (#{error.class}: #{error.message})"
      false
    else
      puts "SKIP #{label} (#{error.class}: #{error.message})"
      true
    end
  end

  def gem_available?(name)
    Gem::Specification.find_by_name(name)
    true
  rescue Gem::LoadError
    false
  end

  def runtime_dependency_graph_valid?
    PACKAGE_DEPENDENCIES.all? do |package, dependencies|
      manifest = package_manifest(package)
      manifest["enforce_dependencies"] == true && Array(manifest["dependencies"]) == dependencies
    end
  end

  def package_manifest(package)
    load_manifest(root.join(package, "package.yml"))
  end

  def load_manifest(path)
    YAML.safe_load(path.read, permitted_classes: [Symbol], aliases: true) || {}
  end

  def runtime_product_references
    root.join("gems").glob("**/*.{rb,erb,md,yml}").select do |path|
      next if path.to_s.end_with?("cli.rb")
      path.file? && path.read.match?(FORBIDDEN_RUNTIME_PATTERN)
    end
  end

  def run_command(*command)
    _stdout, stderr, status = Open3.capture3({ "RAILS_ENV" => ENV.fetch("RAILS_ENV", "test") }, *command, chdir: root.to_s)
    warn stderr unless status.success? || stderr.empty?
    status.success?
  end
end

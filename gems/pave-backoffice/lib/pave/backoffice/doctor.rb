# frozen_string_literal: true

module Pave
  module Backoffice
    module Doctor
      REQUIRED_INDEXES = [
        { table: :pave_settings, columns: %w[namespace key], unique: true },
        { table: :pave_settings, columns: %w[updated_by_id] },
        { table: :pave_audit_events, columns: %w[key occurred_at] },
        { table: :pave_audit_events, columns: %w[actor_type actor_id occurred_at] },
        { table: :pave_audit_events, columns: %w[target_type target_id occurred_at] },
        { table: :pave_audit_events, columns: %w[space_id occurred_at] }
      ].freeze

      TENANT_CHROME_PATTERNS = [
        /Pave::Current\.space/,
        /space.?selector/i,
        /space.?switcher/i,
        /space.?picker/i,
        /current_space/i
      ].freeze

      module_function

      def run
        results = []
        results << check_reserved_product_slugs
        results << check_product_config_load
        results << check_product_panel_controllers
        results << check_platform_panel_controllers
        results << check_panel_slug_uniqueness
        results << check_settings_schemas
        results << check_required_indexes
        results << check_tenant_chrome_absence
        results << check_legacy_controller_shim
        results << check_flat_panel_registration
        results << check_legacy_backoffice_routes
        results << check_register_module_compat
        results << check_cleanup_readiness
        results.compact
      end

      def check_reserved_product_slugs
        Pave::Backoffice::ProductValidator.validate!
        pass(:reserved_product_slugs, "No reserved product slugs detected")
      rescue Pave::Backoffice::ReservedNameError => e
        fail(:reserved_product_slugs, e.message)
      end

      def check_product_config_load
        unconfigured = Pave.products.reject do |product|
          product.root.join(Pave::Backoffice::ProductConfigLoader::CONFIG_PATH).file?
        end

        configured = Pave.products.select do |product|
          product.root.join(Pave::Backoffice::ProductConfigLoader::CONFIG_PATH).file?
        end

        issues = []
        configured.each do |product|
          unless Pave::Backoffice.registry.product_panels(product.key).any?
            issues << "#{product.key}: config file exists but no panels registered"
          end
        end

        if issues.any?
          fail(:product_config_load, "#{issues.size} product config issue(s)", details: issues)
        elsif unconfigured.any? && configured.none?
          pass(:product_config_load, "No product backoffice configs declared (valid for zero-config products)")
        else
          pass(:product_config_load, "Product backoffice configs loaded successfully (#{configured.size} configured, #{unconfigured.size} unconfigured)")
        end
      end

      def check_product_panel_controllers
        result = Pave::Backoffice::RouteDrawer.validate_panel_controllers!
        if result[:missing_controllers].any?
          details = result[:missing_controllers].map { |mc| "#{mc[:product]} / #{mc[:panel]} -> #{mc[:controller]}" }
          fail(:product_panel_controllers,
               "#{result[:missing_controllers].size} missing product panel controller(s)",
               details: details)
        else
          pass(:product_panel_controllers, "All product panel controllers are available")
        end
      end

      def check_platform_panel_controllers
        registry = Pave::Backoffice.registry
        missing = registry.platform_panels.select do |panel|
          panel.controller.present? && !Pave::Backoffice::RouteDrawer.controller_available?(panel.controller)
        end

        if missing.any?
          details = missing.map { |p| "#{p.name} -> #{p.controller}" }
          fail(:platform_panel_controllers,
               "#{missing.size} missing platform panel controller(s)",
               details: details)
        else
          pass(:platform_panel_controllers, "All platform panel controllers are available")
        end
      end

      def check_panel_slug_uniqueness
        registry = Pave::Backoffice.registry
        duplicates = []

        registry.platform_panels.map(&:slug).tally.each do |slug, count|
          duplicates << { context: :platform, slug: slug, count: count } if count > 1
        end

        registry.product_panels.each do |product_key, panels|
          panels.map(&:slug).tally.each do |slug, count|
            duplicates << { context: product_key, slug: slug, count: count } if count > 1
          end
        end

        if duplicates.any?
          details = duplicates.map { |d| "#{d[:slug]} (#{d[:count]}x in #{d[:context]})" }
          fail(:panel_slug_uniqueness,
               "#{duplicates.size} duplicate panel slug(s) found",
               details: details)
        else
          pass(:panel_slug_uniqueness, "All panel slugs are unique within their context")
        end
      end

      def check_settings_schemas
        errors = []

        Pave::Settings.namespaces.each do |namespace|
          schema = Pave::Settings.schema_for(namespace)
          next unless schema

          schema.definitions.each_value do |definition|
            if definition.key.to_s.strip.empty?
              errors << { namespace: namespace, issue: "blank key" }
            end

            unless %w[string integer boolean].include?(definition.type.to_s)
              errors << { namespace: namespace, key: definition.key, issue: "unsupported type: #{definition.type}" }
            end
          end
        end

        if errors.any?
          details = errors.map { |e| "#{e[:namespace]}.#{e[:key]}: #{e[:issue]}" }
          fail(:settings_schemas,
               "#{errors.size} setting schema issue(s)",
               details: details)
        else
          pass(:settings_schemas, "All settings schemas have valid key names and types")
        end
      end

      def check_required_indexes
        return skip(:required_indexes, "No database connection available") unless connected?

        missing = []

        REQUIRED_INDEXES.each do |idx|
          columns = idx[:columns]
          table = idx[:table]

          present = if idx[:unique]
                      connection.index_exists?(table, columns, unique: true)
                    else
                      connection.index_exists?(table, columns)
                    end

          unless present
            present = connection.indexes(table).any? do |index|
              index.columns == columns && (idx[:unique] ? index.unique : true)
            end
          end

          missing << idx unless present
        end

        if missing.any?
          details = missing.map { |idx| "#{idx[:table]} (#{idx[:columns].join(', ')})" }
          fail(:required_indexes,
               "#{missing.size} required index(es) missing",
               details: details)
        else
          pass(:required_indexes, "All required indexes are present")
        end
      end

      def check_tenant_chrome_absence
        backoffice_view_path = ::Rails.root.join("gems/pave-backoffice/app/views")
        return skip(:tenant_chrome_absence, "Backoffice views directory not found") unless backoffice_view_path.directory?

        suspicious = []

        Dir[backoffice_view_path.join("**/*.erb")].each do |path|
          content = File.read(path)
          relative = path.sub(::Rails.root.to_s, "")

              TENANT_CHROME_PATTERNS.each do |pattern|
            if content.match?(pattern)
              suspicious << { file: relative, pattern: pattern.source }
            end
          end
        end

        if suspicious.any?
          details = suspicious.map { |s| "#{s[:file]} (matches #{s[:pattern]})" }
          fail(:tenant_chrome_absence,
               "#{suspicious.size} potential tenant chrome reference(s) found",
               details: details)
        else
          pass(:tenant_chrome_absence, "No tenant chrome references in backoffice views")
        end
      end

      def check_legacy_controller_shim
        unless defined?(::Backoffice::BaseController)
          return fail(:legacy_controller_shim, "Backoffice::BaseController shim is not defined")
        end

        unless ::Backoffice::BaseController < Pave::Backoffice::BaseController
          return fail(:legacy_controller_shim, "Backoffice::BaseController does not inherit from Pave::Backoffice::BaseController")
        end

        legacy_controllers = count_legacy_controller_dependents
        if legacy_controllers > 0
          pass(:legacy_controller_shim,
               "Backoffice::BaseController shim in place (#{legacy_controllers} dependents)")
        else
          pass(:legacy_controller_shim,
               "Backoffice::BaseController shim in place (no dependents — eligible for removal)")
        end
      end

      def check_flat_panel_registration
        count = Pave::Backoffice.registry.flat_panel_registration_count
        if count > 0
          pass(:flat_panel_registration,
               "Flat panel registration backward compat active (#{count} registrations tracked)")
        else
          pass(:flat_panel_registration,
               "Flat panel registration backward compat active (no calls recorded — eligible for removal)")
        end
      end

      def check_legacy_backoffice_routes
        router = ::Rails.application.routes
        has_redirect = router.routes.any? do |route|
          path = route.path.spec.to_s
          path.start_with?("/backoffice") && route.app.app.is_a?(ActionDispatch::Routing::Redirect)
        end

        if has_redirect
          pass(:legacy_backoffice_routes, "/backoffice redirects to /admin are in place")
        else
          fail(:legacy_backoffice_routes, "No /backoffice redirect routes found")
        end
      end

      def check_register_module_compat
        count = Pave::Backoffice.registry.modules.size
        if count > 0
          pass(:register_module_compat,
               "register_module backward compat active (#{count} modules tracked)")
        else
          pass(:register_module_compat,
               "register_module backward compat active (no modules recorded — eligible for removal)")
        end
      end

      def check_cleanup_readiness
        readiness = Pave::Backoffice::CompatibilityShims.readiness
        eligible = readiness.select { |r| r[:eligible_for_removal] }
        still_needed = readiness.select { |r| r[:active] && !r[:eligible_for_removal] }

        if eligible.any?
          eligible_names = eligible.map { |r| r[:shim] }.join(", ")
          pass(:cleanup_readiness,
               "#{eligible.size} shim(s) eligible for removal: #{eligible_names}" \
               "#{still_needed.any? ? "; #{still_needed.size} still required" : ""}")
        else
          needed_names = still_needed.map { |r| r[:shim] }.join(", ")
          pass(:cleanup_readiness,
               "All #{still_needed.size} active shim(s) still required: #{needed_names}")
        end
      end

      def count_legacy_controller_dependents
        return 0 unless defined?(::Backoffice)

        ::Backoffice.constants.map { |c| ::Backoffice.const_get(c) }
          .select { |mod| mod.is_a?(Class) && mod < Pave::Backoffice::BaseController }
          .reject { |klass| klass == ::Backoffice::BaseController }
          .size
      end

      def pass(check, message)
        { check: check, pass: true, message: message }
      end

      def fail(check, message, details: nil)
        result = { check: check, pass: false, message: message }
        result[:details] = details if details
        result
      end

      def skip(check, message)
        { check: check, pass: :skipped, message: message }
      end

      def connection
        ActiveRecord::Base.connection
      end

      def connected?
        ActiveRecord::Base.connection_pool.with_connection { true }
      rescue StandardError
        false
      end
    end
  end
end

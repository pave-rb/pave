# frozen_string_literal: true

module Pave
  module Backoffice
    module CompatibilityShims
      Shim = Data.define(
        :name, :description, :active, :deprecation_target, :removal_plan, :removal_criteria
      )

      SHIMS = [
        Shim.new(
          name: :legacy_base_controller,
          description: "Backoffice::BaseController inherits from Pave::Backoffice::BaseController",
          active: true,
          deprecation_target: "All backoffice controllers should inherit from Pave::Backoffice::BaseController directly",
          removal_plan: "Delete app/controllers/backoffice/base_controller.rb after all legacy controllers are migrated",
          removal_criteria: "No controllers inherit from Backoffice::BaseController (count_legacy_controller_dependents == 0)"
        ),
        Shim.new(
          name: :flat_panel_registration,
          description: "Registry#register_panel accepts old flat-format panel keys (e.g. 'product.home')",
          active: true,
          deprecation_target: "Replace with register_platform_panel / register_product_panel",
          removal_plan: "Remove Registry#register_panel after all config/products.rb and plugin declarations use the new context-aware API",
          removal_criteria: "No product or plugin calls register_panel with flat-format keys (flat_panel_registration_count == 0)"
        ),
        Shim.new(
          name: :legacy_backoffice_routes,
          description: "GET /backoffice redirects to /admin",
          active: true,
          deprecation_target: "Remove legacy /backoffice route redirects from config/routes.rb",
          removal_plan: "Delete redirect lines from config/routes.rb after confirming no production bookmarks or integrations depend on /backoffice/* URLs",
          removal_criteria: "No production traffic depends on /backoffice/* URLs and redirect lines removed from host config/routes.rb"
        ),
        Shim.new(
          name: :register_module_compat,
          description: "Registry#register_module maps legacy module declarations for backward compat",
          active: true,
          deprecation_target: "Products should declare panels via config/backoffice.rb using Pave::Backoffice.product",
          removal_plan: "Deprecate register_module method when all products have migrated to config/backoffice.rb and panel-based declarations",
          removal_criteria: "All products declare panels via config/backoffice.rb; no calls to register_module remain"
        )
      ].freeze

      class << self
        def list
          SHIMS.dup
        end

        def active_shims
          SHIMS.select(&:active)
        end

        def find(name)
          SHIMS.find { |s| s.name == name.to_s.to_sym }
        end

        def active?(name)
          shim = find(name)
          shim&.active || false
        end

        def check(name)
          check_method = :"check_#{name}"
          return Doctor.public_send(check_method) if Doctor.respond_to?(check_method)

          { check: name, pass: :skipped, message: "No matching doctor check for shim :#{name}" }
        end

        def run_all_checks
          active_shims.map do |shim|
            check(shim.name)
          end
        end

        def summary
          active = active_shims
          {
            total: SHIMS.size,
            active: active.size,
            shims: active.map { |s| { name: s.name, description: s.description } }
          }
        end

        def readiness
          SHIMS.map do |shim|
            result = check(shim.name)
            eligible = removal_eligible?(shim)
            {
              shim: shim.name,
              active: shim.active,
              removal_criteria: shim.removal_criteria,
              doctor_check: result[:check],
              doctor_pass: result[:pass],
              message: result[:message],
              eligible_for_removal: eligible
            }
          end
        end

        def safe_to_remove?(name)
          shim = find(name)
          return false unless shim&.active

          removal_eligible?(shim)
        end

        private

        def removal_eligible?(shim)
          case shim.name
          when :legacy_base_controller
            Doctor.count_legacy_controller_dependents == 0
          when :flat_panel_registration
            Pave::Backoffice.registry.flat_panel_registration_count == 0
          when :legacy_backoffice_routes
            false
          when :register_module_compat
            Pave::Backoffice.registry.modules.empty?
          else
            false
          end
        end
      end
    end
  end
end

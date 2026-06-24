# frozen_string_literal: true

module Pave
  module Backoffice
    module UiHelper
      def backoffice_environment_label
        ::Rails.env.to_s.titleize
      end

      def backoffice_current_product
        current_product if respond_to?(:current_product) && current_product.present?
      rescue ActionController::RoutingError
        nil
      end

      def backoffice_current_panel
        current_panel if respond_to?(:current_panel) && current_panel.present?
      rescue ActionController::RoutingError
        nil
      end

      def backoffice_context_text
        product = backoffice_current_product
        panel = backoffice_current_panel

        return backoffice_context_badge_text(:product, [product.label, panel&.label].compact.join(" · ")) if product

        backoffice_context_badge_text(:platform)
      end

      def backoffice_context_classes
        backoffice_context_badge_classes(backoffice_current_product ? :product : :platform)
      end

      def backoffice_context_badge_text(variant, label = nil)
        case variant.to_s
        when "product"
          ["Product", label.presence].compact.join(" · ")
        when "plugin"
          ["Plugin", label.presence].compact.join(" · ")
        when "runtime_module"
          ["Runtime module", label.presence].compact.join(" · ")
        else
          "Platform"
        end
      end

      def backoffice_context_badge_classes(variant)
        case variant.to_s
        when "product"
          "border-indigo-300/40 bg-indigo-950/60 text-indigo-100"
        when "plugin"
          "border-cyan-300/40 bg-cyan-950/60 text-cyan-100"
        when "runtime_module"
          "border-blue-300/40 bg-blue-950/60 text-blue-100"
        else
          "border-amber-300/40 bg-amber-950/60 text-amber-100"
        end
      end

      def backoffice_status_rail_items
        [
          ["Products", backoffice_products.size, "Registered products"],
          ["Product panels", backoffice_registered_product_panels_count, "Declared product panels"],
          ["Plugins", backoffice_registered_plugins_count, "Registered plugins"],
          ["Settings", backoffice_settings_namespace_count, "Settings namespaces"],
          ["Audit", backoffice_recent_audit_events_count, "Recent backoffice events"]
        ]
      end

      def backoffice_page_title
        return content_for(:page_title) if content_for?(:page_title)
        return content_for(:title) if content_for?(:title)
        return backoffice_current_panel.label if backoffice_current_panel
        return backoffice_current_product.label if backoffice_current_product

        case [controller_path, action_name]
        when ["pave/backoffice/platform/dashboard", "show"] then "Dashboard"
        when ["pave/backoffice/platform/users", "index"] then "Platform Users"
        when ["pave/backoffice/platform/audit_events", "index"] then "Audit Log"
        when ["pave/backoffice/platform/settings", "index"] then "Settings"
        else
          controller_name.to_s.humanize
        end
      end

      def backoffice_page_scope_label
        backoffice_current_product ? "Product context" : "Platform context"
      end

      def backoffice_page_description
        return content_for(:page_description) if content_for?(:page_description)
        return backoffice_current_panel.description if backoffice_current_panel&.description.present?
        return "Runtime product administration for #{backoffice_current_product.label}. No tenant space is active." if backoffice_current_product

        case controller_path
        when "pave/backoffice/platform/dashboard"
          "Platform administration and runtime overview."
        when "pave/backoffice/platform/users"
          "Runtime identity users and platform super-admin access."
        when "pave/backoffice/platform/audit_events"
          "Backoffice audit event log. All state-mutating actions are recorded."
        when "pave/backoffice/platform/settings"
          "Runtime configuration and encrypted credentials."
        end
      end

      def backoffice_default_breadcrumbs
        crumbs = []
        product = backoffice_current_product
        panel = backoffice_current_panel

        if product
          crumbs << ["Products", nil]
          crumbs << [product.label, backoffice_product_path(product)]
          crumbs << [panel.label, nil] if panel
        else
          crumbs << ["Platform", pave_backoffice.dashboard_path]
          crumbs << [backoffice_page_title, nil]
        end

        crumbs
      end

      def backoffice_platform_nav_items
        [
          ["Dashboard", pave_backoffice.dashboard_path],
          ["Users", pave_backoffice.users_path],
          ["Audit", pave_backoffice.audit_path],
          ["Settings", pave_backoffice.settings_path]
        ]
      end

      def backoffice_products
        Pave.products.to_a
      end

      def backoffice_registered_product_panels_count
        Pave::Backoffice.registry.product_panels.values.sum(&:size)
      end

      def backoffice_registered_plugins_count
        return 0 unless Pave.respond_to?(:registry) && Pave.registry.respond_to?(:plugins)

        Pave.registry.plugins.size
      end

      def backoffice_settings_namespace_count
        return 0 unless defined?(Pave::Settings) && Pave::Settings.respond_to?(:namespaces)

        Pave::Settings.namespaces.size
      end

      def backoffice_recent_audit_events_count
        return 0 unless defined?(Pave::Audit::AuditEvent)

        Pave::Audit::AuditEvent.where(source: "backoffice").where("occurred_at >= ?", 24.hours.ago).count
      end

      def backoffice_product_path(product)
        "#{pave_backoffice.dashboard_path.sub(%r{/\z}, "")}/#{product.key}"
      end

      def backoffice_product_panel_path(product, panel)
        "#{backoffice_product_path(product)}/#{panel.slug}"
      end

      def backoffice_selected_product?(product)
        backoffice_current_product&.key.to_s == product.key.to_s
      end

      def backoffice_selected_platform_path?(path)
        request.path == path || (path != pave_backoffice.dashboard_path && request.path.start_with?(path))
      end

      def backoffice_filter_input_class
        "rounded-md border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-white placeholder-slate-500 focus:border-electric focus:outline-none focus:ring-1 focus:ring-electric"
      end

      def backoffice_filter_select_class
        "rounded-md border border-slate-700 bg-slate-800 px-3 py-2 text-sm text-white focus:border-electric focus:outline-none focus:ring-1 focus:ring-electric"
      end

      def backoffice_filter_chips(except: %w[controller action utf8])
        return [] unless respond_to?(:request) && request.respond_to?(:query_parameters)

        request.query_parameters.except(*except).filter_map do |key, value|
          next if value.blank?

          label = "#{key.to_s.humanize}: #{value.to_s.truncate(30)}"
          remove_params = request.query_parameters.merge(key => nil).compact
          remove_url = url_for(remove_params)
          [label, remove_url]
        end
      end

      def backoffice_table_column(key, header: nil, classes: nil, &block)
        Pave::Backoffice::TableColumn.new(key: key, header: header, cell: block, classes: classes)
      end

      def default_empty_state_title(variant)
        case variant.to_s
        when "missing_configuration" then "Missing configuration"
        when "module_absent" then "Module unavailable"
        when "boot_validation_failed" then "Boot validation failed"
        when "restricted_by_access" then "Access restricted"
        else "Nothing here"
        end
      end

      def default_empty_state_description(variant)
        case variant.to_s
        when "missing_configuration"
          "Required configuration is missing. Check the docs or run bin/pave doctor."
        when "module_absent"
          "The module that provides this feature is not installed or is not loaded."
        when "boot_validation_failed"
          "Runtime validation failed during boot. Review the error output and restart."
        when "restricted_by_access"
          "You do not have permission to view this content."
        else
          "There are no records to display."
        end
      end

      def empty_state_border_classes(variant)
        case variant.to_s
        when "missing_configuration" then "border-amber-600"
        when "module_absent" then "border-slate-600"
        when "boot_validation_failed" then "border-red-600"
        when "restricted_by_access" then "border-slate-600"
        else "border-slate-600"
        end
      end

      def empty_state_icon_classes(variant)
        case variant.to_s
        when "missing_configuration" then "bg-amber-950/60 text-amber-300"
        when "module_absent" then "bg-slate-800 text-slate-400"
        when "boot_validation_failed" then "bg-red-950/60 text-red-300"
        when "restricted_by_access" then "bg-slate-800 text-slate-400"
        else "bg-slate-800 text-slate-400"
        end
      end

      def secret_field_type_label(source, required)
        type = source.to_s == "database" ? "secret" : "value"
        suffix = required ? "required" : "optional"
        "#{type} - #{suffix}"
      end
    end
  end
end

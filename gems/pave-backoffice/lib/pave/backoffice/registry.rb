# frozen_string_literal: true

module Pave
  module Backoffice
    class Registry
      Product = Data.define(:key, :label, :description, :status, :path, :i18n_key, :runtime_product)
      ModuleDefinition = Data.define(:product_key, :key, :label, :root, :path, :metadata)

      def initialize(product_registry: nil)
        @product_registry = product_registry
        @products = {}
        @modules_by_product = Hash.new { |modules, product_key| modules[product_key] = {} }
        @platform_panels = []
        @product_panels = Hash.new { |h, k| h[k] = [] }
        @flat_panel_registration_count = 0
      end

      def flat_panel_registration_count
        @flat_panel_registration_count
      end

      attr_writer :product_registry

      def register_product(key, label: nil, description: nil, status: nil, path:, i18n_key: nil)
        runtime_product = fetch_runtime_product(key)
        @products[runtime_product.key] = Product.new(
          key: runtime_product.key,
          label: label || runtime_product.label,
          description: description,
          status: status,
          path: path,
          i18n_key: i18n_key,
          runtime_product: runtime_product
        )
      end

      def register_module(product_key, key, label:, root: nil, path: nil, **metadata)
        product = product(product_key)
        key = key.to_s
        @modules_by_product[product.key][key] = ModuleDefinition.new(
          product_key: product.key,
          key: key,
          label: label,
          root: root,
          path: path,
          metadata: metadata.freeze
        )
      end

      def products
        @products.values
      end

      def product(key)
        @products.fetch(key.to_sym)
      end

      def modules
        @modules_by_product.values.flat_map(&:values)
      end

      def modules_for(product_key)
        @modules_by_product[product_key.to_sym].values
      end

      # --- New context-aware panel API ---

      def register_platform_panel(name, label:, controller: nil, routes: nil, position: 99,
                                  source: nil, source_package: nil, description: nil,
                                  status: nil, diagnostics: nil, **extra)
        panel = Panel.new(
          name: name, label: label, controller: controller,
          route_block: routes, position: position,
          source: source, source_package: source_package,
          description: description, status: status, diagnostics: diagnostics,
          **extra.slice(:route, :capability, :group, :icon)
        )
        assert_unique_slug!(panel, @platform_panels, "platform")
        @platform_panels << panel
        sort_panels!(@platform_panels)
      end

      def register_product_panel(product_name, name, label:, controller: nil, routes: nil, position: 99,
                                 source: nil, source_package: nil, description: nil,
                                 status: nil, diagnostics: nil, **extra)
        panel = Panel.new(
          name: name, label: label, controller: controller,
          route_block: routes, position: position,
          source: source, source_package: source_package,
          description: description, status: status, diagnostics: diagnostics,
          **extra.slice(:route, :capability, :group, :icon)
        )
        product_key = product_name.to_s.to_sym
        assert_unique_slug!(panel, @product_panels[product_key], "product #{product_key}")
        @product_panels[product_key] << panel
        sort_panels!(@product_panels[product_key])
      end

      def product_panel(product_name, name, **options)
        register_product_panel(product_name, name, **options)
      end

      def platform_panels
        @platform_panels.dup
      end

      def product_panels(product_key = :__all__)
        if product_key == :__all__
          @product_panels
        else
          @product_panels[product_key.to_s.to_sym].dup
        end
      end

      # --- Deprecated flat panel API (backward compat) ---

      def register_panel(key, **options)
        @flat_panel_registration_count += 1
        if key.to_s.include?(".")
          parts = key.to_s.split(".", 2)
          register_product_panel(parts[0], parts[1],
            label: options[:title] || parts[1].titleize,
            controller: options[:controller],
            position: options[:position] || 100,
            source: options[:owner],
            source_package: options[:owner]&.to_s,
            route: options[:route],
            capability: options[:capability],
            group: options[:group],
            icon: options[:icon]
          )
        else
          register_platform_panel(key,
            label: options[:title] || key.to_s.titleize,
            controller: options[:controller],
            position: options[:position] || 100,
            source: options[:owner],
            source_package: options[:owner]&.to_s,
            route: options[:route],
            capability: options[:capability],
            group: options[:group],
            icon: options[:icon]
          )
        end
      end

      def panels
        @platform_panels + @product_panels.values.flatten
      end

      def panel(key)
        panels.find { |p| p.name == key.to_s.to_sym }
      end

      private

      def assert_unique_slug!(panel, collection, context_label)
        if collection.any? { |p| p.slug == panel.slug }
          raise ArgumentError, "duplicate panel slug :#{panel.slug} in #{context_label}"
        end
      end

      def sort_panels!(panels)
        panels.sort_by! { |p| [p.position, p.label.to_s, p.slug] }
      end

      def fetch_runtime_product(key)
        raise ArgumentError, "product registry is required" unless @product_registry

        @product_registry.fetch(key)
      end
    end
  end
end

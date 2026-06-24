# frozen_string_literal: true

require "pave/backoffice/version"
require "pave/backoffice/panel"
require "pave/backoffice/registry"
require "pave/backoffice/navigation"
require "pave/backoffice/breadcrumbs"
require "pave/backoffice/authentication"
require "pave/backoffice/settings_adapter"
require "pave/backoffice/reserved_name_error"
require "pave/backoffice/product_validator"
require "pave/backoffice/product_config_loader"
require "pave/backoffice/route_drawer"
require "pave/backoffice/tenant_scope_leak_error"
require "pave/backoffice/doctor"
require "pave/backoffice/compatibility_shims"
require "pave/backoffice/engine"

module Pave
  module Backoffice
    class << self
      def registry
        @registry ||= Registry.new
      end

      def configure
        yield registry
        registry
      end

      def register_panel(...)
        registry.register_panel(...)
      end

      def panels
        registry.panels
      end

      def panel(key)
        registry.panel(key)
      end

      # --- New context-aware panel API ---

      def platform_panel(name, **options)
        registry.register_platform_panel(name, **options)
      end

      def product_panel(product_name, name, **options)
        registry.product_panel(product_name, name, **options)
      end

      def product(product_name, &block)
        builder = ProductPanelBuilder.new(product_name.to_s.to_sym)
        block.call(builder)
        builder.each_panel do |panel_attrs|
          registry.register_product_panel(product_name, panel_attrs[:name], **panel_attrs.except(:name))
        end
      end
    end

    class ProductPanelBuilder
      def initialize(product_name)
        @product_name = product_name
        @panels = []
      end

      def panel(name, **options)
        @panels << { name: name, **options }
      end

      def each_panel(&block)
        @panels.each(&block)
      end
    end
  end
end

# frozen_string_literal: true

require "pathname"

require "pave/core/version"
require "pave/core/configuration"
require "pave/core/current"
require "pave/core/error"
require "pave/core/result"
require "pave/core/service"
require "pave/core/registry"
require "pave/core/plugin"
require "pave/core/settings"
require "pave/core/product"
require "pave/core/product_registry"
require "pave/core/engine"

module Pave
  class << self
    def configure
      yield config
      config
    end

    def config
      @config ||= Configuration.new
    end

    def registry
      @registry ||= Registry.new
    end

    def product(key, **options)
      products.register(key, **options)
    end

    def products
      @products ||= ProductRegistry.new
    end

    def tenant_chrome(key, **options, &block)
      products.register_tenant_chrome(key, **options, &block)
    end

    def tenant_settings(key, &block)
      products.register_tenant_settings(key, &block)
    end

    def after_sign_in_redirect(key, &block)
      products.register_after_sign_in_redirect(key, &block)
    end

    def after_sign_up_redirect(key, &block)
      products.register_after_sign_up_redirect(key, &block)
    end

    def signed_in_root_redirect(key, &block)
      products.register_signed_in_root_redirect(key, &block)
    end

    def backoffice
      Pave::Backoffice.registry.tap { |registry| registry.product_registry = products }
    end
  end

  module Core
  end
end

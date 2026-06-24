# frozen_string_literal: true

module Pave
  class ProductRegistry
    include Enumerable

    TenantChrome = Data.define(:product_key, :partial, :setup)
    TenantSettings = Data.define(:product_key, :resolver)
    ProductRedirect = Data.define(:product_key, :resolver)

    def initialize
      @products = {}
      @tenant_chrome = {}
      @tenant_settings = {}
      @after_sign_in_redirects = {}
      @after_sign_up_redirects = {}
      @signed_in_root_redirects = {}
    end

    def register(key, **options)
      product = Product.new(key: key, **options)
      products[product.key] = product
    end

    def each(&block)
      products.values.each(&block)
    end

    def [](key)
      products[key.to_sym]
    end

    def fetch(key)
      products.fetch(key.to_sym)
    end

    def keys
      products.keys
    end

    def stylesheets
      products.values.filter_map(&:stylesheet)
    end

    def draw_routes(router)
      each { |product| product.draw_routes(router) }
    end

    def register_tenant_chrome(key, partial:, &setup)
      product = fetch(key)
      tenant_chrome[product.key] = TenantChrome.new(product.key, partial, setup)
    end

    def tenant_chrome_partial
      tenant_chrome.values.first&.partial
    end

    def prepare_tenant_chrome(controller, space:, user:)
      return if space.blank? || user.blank?

      tenant_chrome.each_value do |chrome|
        chrome.setup&.call(controller, space:, user:)
      end
    end

    def register_tenant_settings(key, &resolver)
      product = fetch(key)
      tenant_settings[product.key] = TenantSettings.new(product.key, resolver)
    end

    def tenant_settings_groups_for(view_context)
      tenant_settings.values.flat_map do |settings|
        Array(settings.resolver&.call(view_context))
      end
    end

    def register_after_sign_in_redirect(key, &resolver)
      product = fetch(key)
      after_sign_in_redirects[product.key] = ProductRedirect.new(product.key, resolver)
    end

    def after_sign_in_path_for(controller, resource, stored_location:)
      after_sign_in_redirects.each_value do |redirect|
        path = redirect.resolver&.call(controller, resource, stored_location:)
        return path if path.present?
      end

      nil
    end

    def register_after_sign_up_redirect(key, &resolver)
      product = fetch(key)
      after_sign_up_redirects[product.key] = ProductRedirect.new(product.key, resolver)
    end

    def after_sign_up_path_for(controller, resource)
      after_sign_up_redirects.each_value do |redirect|
        path = redirect.resolver&.call(controller, resource)
        return path if path.present?
      end

      nil
    end

    def register_signed_in_root_redirect(key, &resolver)
      product = fetch(key)
      signed_in_root_redirects[product.key] = ProductRedirect.new(product.key, resolver)
    end

    def signed_in_root_path_for(controller, resource)
      signed_in_root_redirects.each_value do |redirect|
        path = redirect.resolver&.call(controller, resource)
        return path if path.present?
      end

      nil
    end

    private

    attr_reader :products, :tenant_chrome, :tenant_settings, :after_sign_in_redirects, :after_sign_up_redirects,
      :signed_in_root_redirects
  end
end

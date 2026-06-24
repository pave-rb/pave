# frozen_string_literal: true

module Pave
  class ProductBoot
    def self.apply!(config)
      new(config).apply!
    end

    def initialize(config)
      @config = config
    end

    def apply!
      Pave.products.each do |product|
        register_load_paths(product)
        register_helper_path(product)
        register_view_path(product)
        register_asset_paths(product)
        register_migration_path(product)
        register_locale_paths(product)
      end
    end

    private

    attr_reader :config

    def register_load_paths(product)
      product.load_paths.each do |path|
        add_path(config.autoload_paths, path)
        add_path(config.eager_load_paths, path)
      end
    end

    def register_view_path(product)
      add_path(config.paths["app/views"], product.view_path)
    end

    def register_helper_path(product)
      add_path(config.paths["app/helpers"], product.helper_path)
    end

    def register_asset_paths(product)
      return unless config.respond_to?(:assets) && config.assets.respond_to?(:paths)

      product.asset_paths.each { |path| add_path(config.assets.paths, path) }
    end

    def register_migration_path(product)
      add_path(config.paths["db/migrate"], product.migration_path)
    end

    def register_locale_paths(product)
      locale_path = product.root.join("config/locales")
      return unless locale_path.directory?

      Dir[locale_path.join("**/*.yml")].each do |file|
        config.i18n.load_path << file unless config.i18n.load_path.include?(file)
      end
    end

    def add_path(paths, path)
      return unless path.directory?

      path = path.to_s
      paths << path unless paths.map(&:to_s).include?(path)
    end
  end
end

# frozen_string_literal: true

require "pathname"

module Pave
  class Product
    APP_LOAD_PATHS = %w[
      app/controllers
      app/controllers/concerns
      app/helpers
      app/jobs
      app/mailers
      app/models
      app/models/concerns
      app/services
    ].freeze

    ASSET_PATHS = %w[
      app/assets/images
      app/assets/stylesheets
      app/javascript
    ].freeze

    attr_reader :key, :label, :root, :mode, :dev_subdomain, :metadata

    def initialize(key:, label:, root:, mode: :namespaced, dev_subdomain: nil, **metadata)
      @key = key.to_sym
      @label = label
      @root = Pathname(root)
      @mode = mode.to_sym
      @dev_subdomain = dev_subdomain
      @metadata = metadata.freeze
    end

    def legacy_constants?
      mode == :legacy_constants
    end

    def load_paths
      APP_LOAD_PATHS.filter_map { |path| existing_path(path) }
    end

    def asset_paths
      ASSET_PATHS.filter_map { |path| existing_path(path) }
    end

    def stylesheet
      stylesheet_path.file? ? key.to_s : nil
    end

    def view_path
      root.join("app/views")
    end

    def helper_path
      root.join("app/helpers")
    end

    def migration_path
      root.join("db/migrate")
    end

    def stylesheet_path
      root.join("app/assets/stylesheets/#{key}.css")
    end

    def routes_path
      root.join("config/routes.rb")
    end

    def test_path
      root.join("test")
    end

    def draw_routes(router)
      return unless routes_path.file?

      router.instance_eval(routes_path.read, routes_path.to_s)
    end

    private

    def existing_path(path)
      full_path = root.join(path)
      full_path if full_path.directory?
    end
  end
end

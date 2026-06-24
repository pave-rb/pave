# frozen_string_literal: true

module Pave
  module Rails
    module Generators
      class InstallGenerator < ::Rails::Generators::Base
        desc "Install Pav\u00ea into the host application"
        source_root File.expand_path("templates", __dir__)

        def create_config_directory
          empty_directory "config"
        end

        def create_pave_config
          template "config/pave.rb", "config/pave.rb"
        end

        def create_initializers_directory
          empty_directory "config/initializers"
        end

        def create_pave_initializer
          template "config/initializers/pave.rb", "config/initializers/pave.rb"
        end

        def update_routes
          route 'mount Pave::Rails::Engine, at: "/pave"'
        end

        def create_products_directory
          empty_directory "products"
          create_file "products/.keep"
        end

        def create_agents_dot_md
          template "AGENTS.md", "AGENTS.md"
        end

        def create_pave_manifest
          template "PAVE_MANIFEST.yml", "PAVE_MANIFEST.yml"
        end

        def create_pave_lock
          create_file "pave.lock", "# Pav\u00ea lockfile placeholder\n"
        end
      end
    end
  end
end

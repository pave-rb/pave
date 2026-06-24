# frozen_string_literal: true

module Pave
  module Rails
    module Generators
      class ProductGenerator < ::Rails::Generators::NamedBase
        desc "Generate a Pav\u00ea product scaffold under products/<name>/"
        source_root File.expand_path("templates/products", __dir__)

        class_option :module, type: :string, default: "App", desc: "Ruby module name for the product"
        hook_for :test_framework

        def create_product_directory
          empty_directory product_path
        end

        def create_product_config
          template "product.yml", File.join(product_path, "product.yml")
        end

        def create_product_rb
          template "product.rb", File.join(product_path, "config/product.rb")
        end

        def create_backoffice_config
          template "backoffice.rb", File.join(product_path, "config/backoffice.rb")
        end

        def create_routes
          template "routes.rb", File.join(product_path, "config/routes.rb")
        end

        def create_app_directories
          empty_directory File.join(product_path, "app/controllers")
          empty_directory File.join(product_path, "app/models")
          empty_directory File.join(product_path, "app/services")
          empty_directory File.join(product_path, "app/views")
        end

        def create_migrations_directory
          empty_directory File.join(product_path, "db/migrate")
        end

        def create_context_doc
          template "CONTEXT.md", File.join(product_path, "CONTEXT.md")
        end

        private

        def product_path
          @product_path ||= "products/#{file_name}"
        end

        def product_module_name
          options[:module]
        end

        def product_class_name
          class_name
        end
      end
    end
  end
end

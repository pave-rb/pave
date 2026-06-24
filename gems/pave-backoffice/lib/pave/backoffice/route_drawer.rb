# frozen_string_literal: true

module Pave
  module Backoffice
    module RouteDrawer
      FALLBACK_CONTROLLER = "pave/backoffice/products/unavailable"
      GENERIC_CONTROLLER = "pave/backoffice/products/panels"

      def self.draw(router)
        Pave.products.each do |product|
          product_key = product.key.to_s

          router.scope "/#{product_key}", defaults: { product_id: product_key } do
            router.get "/", to: "products/dashboard#show"

            Pave::Backoffice.registry.product_panels(product_key).each do |panel|
              draw_panel_route(router, product_key, panel)
            end
          end
        end
      end

      def self.draw_panel_route(router, product_key, panel)
        controller = panel.controller
        controller = GENERIC_CONTROLLER if controller.blank?
        controller = FALLBACK_CONTROLLER unless controller_available?(controller)

        if panel.route_block
          router.scope "/#{panel.slug}", defaults: { panel_id: panel.slug } do
            router.instance_exec(&panel.route_block)
          end
        elsif controller.present?
          router.get "/#{panel.slug}", to: "#{route_controller(controller)}#index",
                    defaults: { panel_id: panel.slug }
        end
      end

      def self.controller_available?(controller_path)
        controller_class_name(controller_path).constantize
        true
      rescue NameError
        false
      end

      def self.route_controller(controller_path)
        if controller_path.to_s.start_with?("pave/backoffice/")
          controller_path.to_s.delete_prefix("pave/backoffice/")
        else
          "/#{controller_path}"
        end
      end

      def self.controller_class_name(controller_path)
        normalized = controller_path.to_s.end_with?("_controller") ? controller_path.to_s : "#{controller_path}_controller"
        normalized.camelize
      end

      def self.validate_panel_controllers!
        diagnostics = { missing_controllers: [] }

        Pave.products.each do |product|
          product_key = product.key.to_s
          Pave::Backoffice.registry.product_panels(product_key).each do |panel|
            next if panel.controller.nil? || controller_available?(panel.controller)

            diagnostics[:missing_controllers] << {
              product: product_key,
              panel: panel.name,
              controller: panel.controller
            }
          end
        end

        diagnostics
      end
    end
  end
end

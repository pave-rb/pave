# frozen_string_literal: true

module Pave
  module Backoffice
    module Products
      class BaseController < Pave::Backoffice::BaseController
        helper_method :current_product, :current_panel, :product_panels, :plugin_panels

        before_action :set_current_product
        before_action :set_current_panel

        private

        attr_reader :current_product, :current_panel

        def backoffice_context
          :product
        end

        def product_panels
          @product_panels ||= all_product_panels.reject { |panel| panel.source.to_s == "plugin" }
        end

        def plugin_panels
          @plugin_panels ||= all_product_panels.select { |panel| panel.source.to_s == "plugin" }
        end

        def all_product_panels
          @all_product_panels ||= Pave::Backoffice.registry.product_panels(current_product.key)
        end

        def set_current_product
          @current_product = Pave.products[params[:product_id]]
          raise ActionController::RoutingError, "Product not found" unless @current_product
        end

        def set_current_panel
          return unless params[:panel_id].present?

          @current_panel = all_product_panels.find { |panel| panel.slug == params[:panel_id].to_s }
          raise ActionController::RoutingError, "Panel not found" unless @current_panel
        end
      end
    end
  end
end

# frozen_string_literal: true

module Pave
  module Backoffice
    module Products
      class UnavailableController < Pave::Backoffice::Products::BaseController
        def index
          @product = current_product
          @panel = current_panel

          backoffice_breadcrumbs.add("Platform", route: pave_backoffice.dashboard_path)
          backoffice_breadcrumbs.add(@product.label, route: "/admin/#{@product.key}")
          backoffice_breadcrumbs.add(@panel.label)

          render status: :not_found
        end
      end
    end
  end
end

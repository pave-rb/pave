# frozen_string_literal: true

module Pave
  module Backoffice
    module Products
      class DashboardController < Pave::Backoffice::Products::BaseController
        def show
          @product = current_product
          @product_panels = product_panels
          @plugin_panels = plugin_panels
          @recent_audit_events = recent_product_audit_events
          backoffice_breadcrumbs.add("Platform", route: pave_backoffice.dashboard_path)
          backoffice_breadcrumbs.add(@product.label)
        end

        private

        def recent_product_audit_events
          Pave::Audit::AuditEvent
            .order(occurred_at: :desc)
            .limit(20)
            .select { |event| event.source == "backoffice" && event.metadata["product"] == @product.key.to_s }
            .first(5)
        end
      end
    end
  end
end

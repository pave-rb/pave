module Pave
  module Backoffice
    module Platform
      class DashboardController < Pave::Backoffice::BaseController
        def show
          @products = Pave.products.to_a
          @platform_panels = Pave::Backoffice.registry.platform_panels
          @plugins = Pave.registry.plugins
          @recent_audit_events = Pave::Audit::AuditEvent.order(occurred_at: :desc).limit(5)
          @runtime_modules = detect_runtime_modules
        end

        private

        def detect_runtime_modules
          Dir[::Rails.root.join("gems/pave-*")].filter_map do |path|
            basename = File.basename(path)
            next unless File.directory?(path)

            name = basename.sub("pave-", "").humanize
            { key: basename, name: name, path: path }
          end.sort_by { |m| m[:name] }
        end
      end
    end
  end
end

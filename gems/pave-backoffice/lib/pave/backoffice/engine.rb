# frozen_string_literal: true

require "rails"

module Pave
  module Backoffice
    class Engine < ::Rails::Engine
      isolate_namespace Pave::Backoffice

      initializer "pave_backoffice.add_javascript_asset_path" do
        ::Rails.application.config.assets.paths << root.join("app/javascript") if ::Rails.application.config.respond_to?(:assets)
      end

      config.before_initialize do
        Pave::Backoffice::ProductValidator.validate!
      end

      initializer "pave_backoffice.load_product_backoffice_configs" do
        Pave::Backoffice::ProductConfigLoader.load_all
      end

      initializer "pave_backoffice.register_platform_panels" do
        Pave::Backoffice.platform_panel :audit,
          label: "Audit",
          position: 20,
          description: "Backoffice audit event log",
          route: "/admin/audit"

        Pave::Backoffice.platform_panel :settings,
          label: "Settings",
          position: 30,
          description: "Runtime configuration and encrypted credentials",
          route: "/admin/settings"
      end

      initializer "pave_backoffice.install_settings_adapter" do
        Pave::Settings.adapter ||= Pave::Backoffice::SettingsAdapter.new
      end
    end
  end
end

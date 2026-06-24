# frozen_string_literal: true

module Pave
  module Backoffice
    class BaseController < ApplicationController
      include Pave::Backoffice::Authentication

      layout -> { turbo_frame_request? ? false : "pave/backoffice/application" }
      helper Pave::Backoffice::UiHelper

      rescue_from Pave::Backoffice::TenantScopeLeakError, with: :render_tenant_scope_leak

      skip_before_action :set_product_chrome_context

      around_action :guard_tenant_scope
      before_action :authenticate_backoffice_admin!
      before_action :authorize_backoffice_admin!

      helper_method :current_admin, :current_product, :backoffice_context, :backoffice_breadcrumbs, :backoffice_navigation

      before_action :detect_product_context

      private

      def current_admin
        current_backoffice_admin
      end

      def current_product
        @_backoffice_current_product
      end

      def detect_product_context
        product_key = params[:product_id]
        return unless product_key.present?

        @_backoffice_current_product = Pave.products[product_key]
      end

      def backoffice_context
        current_product ? :product : :platform
      end

      def authorize_backoffice_admin!
        return if current_admin&.super_admin?

        render_backoffice_forbidden
      end

      def backoffice_navigation
        Pave::Backoffice::Navigation.new(
          panels: Pave::Backoffice.panels,
          authorizer: ->(panel) {
            capability = panel.respond_to?(:capability) ? panel.capability : nil
            capability ? current_admin&.can?(capability) : true
          }
        )
      end

      def backoffice_breadcrumbs
        @backoffice_breadcrumbs ||= Pave::Backoffice::Breadcrumbs.new
      end

      def render_backoffice_forbidden
        render "pave/backoffice/errors/forbidden", status: :forbidden
      end

      def audit_admin(key, target: nil, metadata: {})
        Pave::Audit.log!(
          key: key.to_s,
          actor: current_admin,
          target: target,
          space: nil,
          metadata: metadata.merge(backoffice: true),
          source: "backoffice",
          request_id: request.request_id
        )
      end

      def guard_tenant_scope
        Pave::Current.space = nil
        clear_legacy_current_space
        yield
      ensure
        raise Pave::Backoffice::TenantScopeLeakError if Pave::Current.space.present?
        raise Pave::Backoffice::TenantScopeLeakError if legacy_current_space_present?
      end

      def clear_legacy_current_space
        return unless defined?(::Current) && ::Current.respond_to?(:space=)

        ::Current.space = nil
      end

      def legacy_current_space_present?
        defined?(::Current) && ::Current.respond_to?(:space) && ::Current.space.present?
      end

      def render_tenant_scope_leak
        render "pave/backoffice/errors/tenant_scope_leak", status: :internal_server_error
      end
    end
  end
end

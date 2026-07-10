# frozen_string_literal: true

module Pave
  module Backoffice
    module Mfa
      class RecoveryCodesController < ActionController::Base
        include Pave::Backoffice::Authentication

        layout "pave/backoffice/auth"
        helper Pave::Backoffice::UiHelper

        before_action :set_pending_admin
        before_action :set_recovery_codes

        def show
        end

        def create
          @admin.update!(last_mfa_at: Time.current)
          session.delete(:pave_backoffice_admin_mfa_user_id)
          session.delete(:pave_backoffice_recovery_codes)
          sign_in_backoffice_admin(@admin)
          redirect_to backoffice_return_location, notice: "Signed in to backoffice."
        end

        private

        def set_pending_admin
          admin_id = session[:pave_backoffice_admin_mfa_user_id]
          @admin = User.find_by(id: admin_id) if admin_id
          return if @admin.present?

          redirect_to sign_in_path, alert: t("mfa.challenge.expired")
        end

        def set_recovery_codes
          @recovery_codes = Array(session[:pave_backoffice_recovery_codes])
          return if @recovery_codes.present?

          redirect_to mfa_challenge_path, alert: t("mfa.challenge.expired")
        end
      end
    end
  end
end

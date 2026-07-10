# frozen_string_literal: true

module Pave
  module Backoffice
    module ProfileSecurity
      class RecoveryCodesController < BaseController
        before_action :set_recovery_codes, only: :show

        def show
        end

        def regenerate
          return redirect_to profile_security_path, alert: t("profiles.security.recovery_codes.unavailable") unless @user.mfa_enabled?

          recovery_codes = Auth::Mfa::GenerateRecoveryCodes.call(user: @user)
          session[:pave_backoffice_profile_recovery_codes] = recovery_codes

          redirect_to profile_security_recovery_codes_path
        end

        def acknowledge
          session.delete(:pave_backoffice_profile_recovery_codes)
          redirect_to profile_security_path, notice: t("profiles.security.recovery_codes.acknowledged")
        end

        private

        def set_recovery_codes
          @recovery_codes = Array(session[:pave_backoffice_profile_recovery_codes]).presence
          return if @recovery_codes.present?

          redirect_to profile_security_path, alert: t("profiles.security.recovery_codes.missing")
        end
      end
    end
  end
end

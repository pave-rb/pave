# frozen_string_literal: true

module Pave
  module Backoffice
    module ProfileSecurity
      class TotpEnrollmentsController < BaseController
        before_action :prepare_enrollment, only: [ :new, :create ]

        def new
        end

        def create
          result = Auth::Mfa::EnrollTotp.call(user: @user, secret: @provisioning_secret, code: params[:code])

          unless result.success?
            flash.now[:alert] = t("mfa.totp_enrollment.errors.#{result.error}")
            return render :new, status: :unprocessable_entity
          end

          session.delete(:pave_backoffice_profile_pending_totp_secret)

          if result.recovery_codes.present?
            session[:pave_backoffice_profile_recovery_codes] = result.recovery_codes
            return redirect_to profile_security_recovery_codes_path
          end

          redirect_to profile_security_path, notice: t("profiles.security.totp.enabled")
        end

        def destroy
          result = Auth::Mfa::DisableTotp.call(user: @user)

          unless result.success?
            return redirect_to profile_security_path, alert: t("profiles.security.errors.#{result.error}")
          end

          redirect_to profile_security_path, notice: t("profiles.security.totp.disabled")
        end

        private

        def prepare_enrollment
          @provisioning_secret = session[:pave_backoffice_profile_pending_totp_secret] || generate_pending_secret!
          @provisioning_uri = @user.totp_provisioning_uri(secret: @provisioning_secret)
          @qr_code_svg = RQRCode::QRCode.new(@provisioning_uri).as_svg(module_size: 4, standalone: true)
        end

        def generate_pending_secret!
          secret = ROTP::Base32.random
          session[:pave_backoffice_profile_pending_totp_secret] = secret
          secret
        end
      end
    end
  end
end

# frozen_string_literal: true

module Pave
  module Backoffice
    module Mfa
      class TotpEnrollmentsController < ActionController::Base
        include Pave::Backoffice::Authentication

        layout "pave/backoffice/auth"
        helper Pave::Backoffice::UiHelper

        before_action :set_pending_admin

        def new
          @provisioning_secret = session[:pave_backoffice_pending_totp_secret] || generate_pending_secret!
          @provisioning_uri = @admin.totp_provisioning_uri(secret: @provisioning_secret)
          @qr_code_svg = RQRCode::QRCode.new(@provisioning_uri).as_svg(module_size: 4, standalone: true)
        end

        def create
          @provisioning_secret = session[:pave_backoffice_pending_totp_secret] || generate_pending_secret!
          result = Auth::Mfa::EnrollTotp.call(user: @admin, secret: @provisioning_secret, code: params[:code])

          unless result.success?
            @provisioning_uri = @admin.totp_provisioning_uri(secret: @provisioning_secret)
            @qr_code_svg = RQRCode::QRCode.new(@provisioning_uri).as_svg(module_size: 4, standalone: true)
            flash.now[:alert] = t("mfa.totp_enrollment.errors.#{result.error}")
            return render :new, status: :unprocessable_entity
          end

          session[:pave_backoffice_recovery_codes] = result.recovery_codes if result.recovery_codes.present?
          session.delete(:pave_backoffice_pending_totp_secret)

          redirect_to mfa_recovery_codes_path
        end

        private

        def set_pending_admin
          admin_id = session[:pave_backoffice_admin_mfa_user_id]
          @admin = User.find_by(id: admin_id) if admin_id
          return if @admin.present?

          redirect_to sign_in_path, alert: t("mfa.challenge.expired")
        end

        def generate_pending_secret!
          secret = ROTP::Base32.random
          session[:pave_backoffice_pending_totp_secret] = secret
          secret
        end
      end
    end
  end
end

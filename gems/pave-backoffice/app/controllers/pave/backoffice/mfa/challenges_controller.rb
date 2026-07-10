# frozen_string_literal: true

module Pave
  module Backoffice
    module Mfa
      class ChallengesController < ActionController::Base
        include Pave::Backoffice::Authentication

        layout "pave/backoffice/auth"
        helper Pave::Backoffice::UiHelper

        before_action :set_pending_admin

        def show
          @passkeys_enabled = @admin.passkeys_enabled?(rp_id: current_webauthn.rp_id)
          redirect_to new_mfa_totp_enrollment_path if @admin.mfa_setup_required?
        end

        def create
          result =
            if params[:otp_attempt].present?
              Auth::Mfa::VerifyTotp.call(user: @admin, code: params[:otp_attempt])
            elsif params[:recovery_code_attempt].present?
              Auth::Mfa::VerifyRecoveryCode.call(user: @admin, code: params[:recovery_code_attempt])
            else
              Struct.new(:success?, :error, keyword_init: true).new(success?: false, error: :blank_code)
            end

          unless result.success?
            @passkeys_enabled = @admin.passkeys_enabled?(rp_id: current_webauthn.rp_id)
            flash.now[:alert] = t("mfa.challenge.errors.#{result.error}")
            return render :show, status: :unprocessable_entity
          end

          @admin.update!(last_mfa_at: Time.current)
          session.delete(:pave_backoffice_admin_mfa_user_id)
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

        def current_webauthn
          @current_webauthn ||= Pave::Identity::Webauthn.relying_party_for(request)
        end
      end
    end
  end
end

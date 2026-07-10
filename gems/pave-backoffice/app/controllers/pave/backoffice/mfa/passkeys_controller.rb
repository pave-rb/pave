# frozen_string_literal: true

module Pave
  module Backoffice
    module Mfa
      class PasskeysController < ActionController::Base
        include Pave::Backoffice::Authentication

        layout "pave/backoffice/auth"
        helper Pave::Backoffice::UiHelper

        before_action :set_pending_admin

        def registration_options
          options = Auth::Mfa::Webauthn::GenerateRegistrationOptions.call(
            user: @admin,
            session: session,
            webauthn: current_webauthn
          )
          render json: options
        end

        def create
          result = Auth::Mfa::CompletePasskeyRegistration.call(
            user: @admin,
            session: session,
            credential: credential_payload,
            label: passkey_label,
            webauthn: current_webauthn
          )

          unless result.success?
            return render json: { error: t("mfa.passkeys.errors.#{result.error}") }, status: :unprocessable_entity
          end

          session[:pave_backoffice_recovery_codes] = result.recovery_codes if result.recovery_codes.present?
          render json: { redirect_url: mfa_recovery_codes_path }
        end

        def authentication_options
          unless @admin.passkeys_enabled?(rp_id: current_webauthn.rp_id)
            return render json: { error: t("mfa.challenge.errors.passkeys_unavailable") }, status: :unprocessable_entity
          end

          options = Auth::Mfa::Webauthn::GenerateAuthenticationOptions.call(
            user: @admin,
            session: session,
            webauthn: current_webauthn
          )
          render json: options
        end

        def authenticate
          result = Auth::Mfa::Webauthn::VerifyAssertion.call(
            user: @admin,
            session: session,
            credential: credential_payload,
            webauthn: current_webauthn
          )

          unless result.success?
            return render json: { error: t("mfa.challenge.errors.#{result.error}") }, status: :unprocessable_entity
          end

          @admin.update!(last_mfa_at: Time.current)
          session.delete(:pave_backoffice_admin_mfa_user_id)
          sign_in_backoffice_admin(@admin)

          render json: { redirect_url: backoffice_return_location }
        end

        private

        def set_pending_admin
          admin_id = session[:pave_backoffice_admin_mfa_user_id]
          @admin = User.find_by(id: admin_id) if admin_id
          return if @admin.present?

          render json: { redirect_url: sign_in_path, error: t("mfa.challenge.expired") }, status: :unprocessable_entity
        end

        def credential_payload
          payload = passkey_payload[:public_key_credential]
          raise ActionController::ParameterMissing, :public_key_credential if payload.blank?

          return payload.permit!.to_h if payload.is_a?(ActionController::Parameters)

          ActionController::Parameters.new(payload).permit!.to_h
        end

        def passkey_label
          passkey_payload[:label].presence
        end

        def passkey_payload
          payload = params[:passkey].presence || params
          payload.is_a?(ActionController::Parameters) ? payload : ActionController::Parameters.new(payload)
        end

        def current_webauthn
          @current_webauthn ||= Pave::Identity::Webauthn.relying_party_for(request)
        end
      end
    end
  end
end

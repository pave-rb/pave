# frozen_string_literal: true

module Pave
  module Backoffice
    module ProfileSecurity
      class PasskeysController < BaseController
        before_action :set_passkey, only: :destroy

        def registration_options
          options = Auth::Mfa::Webauthn::GenerateRegistrationOptions.call(
            user: @user,
            session: session,
            webauthn: current_webauthn
          )
          render json: options
        end

        def create
          result = Auth::Mfa::CompletePasskeyRegistration.call(
            user: @user,
            session: session,
            credential: credential_payload,
            label: passkey_label,
            webauthn: current_webauthn
          )

          unless result.success?
            return render json: { error: t("mfa.passkeys.errors.#{result.error}") }, status: :unprocessable_entity
          end

          redirect_url =
            if result.recovery_codes.present?
              session[:pave_backoffice_profile_recovery_codes] = result.recovery_codes
              profile_security_recovery_codes_path
            else
              flash[:notice] = t("profiles.security.passkeys.created")
              profile_security_path
            end

          render json: { redirect_url: redirect_url }
        end

        def destroy
          result = Auth::Mfa::RemovePasskey.call(user: @user, passkey: @passkey)

          unless result.success?
            return redirect_to profile_security_path, alert: t("profiles.security.errors.#{result.error}")
          end

          redirect_to profile_security_path, notice: t("profiles.security.passkeys.deleted")
        end

        private

        def set_passkey
          @passkey = @user.user_passkeys.where(rp_id: current_webauthn.rp_id).find(params[:id])
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
      end
    end
  end
end

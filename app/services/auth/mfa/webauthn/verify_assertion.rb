# frozen_string_literal: true

module Auth
  module Mfa
    module Webauthn
      class VerifyAssertion
        Result = Struct.new(:success?, :passkey, :error, keyword_init: true)

        def self.call(user:, session:, credential:, webauthn: nil)
          new(user:, session:, credential:, webauthn:).call
        end

        def initialize(user:, session:, credential:, webauthn: nil)
          @user = user
          @session = session
          @credential = credential
          @webauthn = webauthn || global_webauthn_context
        end

        def call
          challenge = Auth::PendingMfaSession.passkey_authentication_challenge(session: @session)
          return Result.new(success?: false, error: :expired) if challenge.blank?
          return Result.new(success?: false, error: :expired) if authentication_rp_mismatch?

          webauthn_credential, passkey = @webauthn.relying_party.verify_authentication(
            @credential,
            challenge,
            user_verification: true
          ) do |credential|
            passkey = @user.user_passkeys.find_by(external_id: credential.id, rp_id: @webauthn.rp_id)
            return Result.new(success?: false, error: :authentication_failed) if passkey.blank?

            passkey
          end

          passkey.update!(
            sign_count: webauthn_credential.sign_count,
            last_used_at: Time.current,
            backup_eligible: webauthn_credential.backup_eligible?,
            backup_state: webauthn_credential.backed_up?
          )

          Auth::PendingMfaSession.clear_passkey_authentication_challenge(session: @session)

          Result.new(success?: true, passkey:)
        rescue WebAuthn::Error
          Result.new(success?: false, error: :authentication_failed)
        end

        private

        def authentication_rp_mismatch?
          expected_rp_id = Auth::PendingMfaSession.passkey_authentication_rp_id(session: @session)
          expected_rp_id.present? && expected_rp_id != @webauthn.rp_id
        end

        def global_webauthn_context
          Struct.new(:rp_id, :relying_party, keyword_init: true).new(
            rp_id: WebAuthn.configuration.rp_id,
            relying_party: WebAuthn.configuration.relying_party
          )
        end
      end
    end
  end
end

# frozen_string_literal: true

module Auth
  module Mfa
    module Webauthn
      class RegisterPasskey
        Result = Struct.new(:success?, :passkey, :error, keyword_init: true)

        def self.call(user:, session:, credential:, label:, webauthn: nil)
          new(user:, session:, credential:, label:, webauthn:).call
        end

        def initialize(user:, session:, credential:, label:, webauthn: nil)
          @user = user
          @session = session
          @credential = credential
          @label = label.to_s.strip
          @webauthn = webauthn || global_webauthn_context
        end

        def call
          return Result.new(success?: false, error: :label_blank) if @label.blank?

          challenge = Auth::PendingMfaSession.passkey_registration_challenge(session: @session)
          return Result.new(success?: false, error: :expired) if challenge.blank?
          return Result.new(success?: false, error: :expired) if registration_rp_mismatch?

          webauthn_credential = @webauthn.relying_party.verify_registration(
            @credential,
            challenge,
            user_verification: true
          )

          passkey = @user.user_passkeys.create!(
            rp_id: @webauthn.rp_id,
            external_id: webauthn_credential.id,
            public_key: webauthn_credential.public_key,
            sign_count: webauthn_credential.sign_count,
            label: @label,
            transports: Array(webauthn_credential.response.transports).compact,
            platform_authenticator: webauthn_credential.authenticator_attachment == "platform",
            backup_eligible: webauthn_credential.backup_eligible?,
            backup_state: webauthn_credential.backed_up?
          )

          Auth::PendingMfaSession.clear_passkey_registration_challenge(session: @session)

          Result.new(success?: true, passkey:)
        rescue WebAuthn::Error, ActiveRecord::RecordInvalid
          Result.new(success?: false, error: :registration_failed)
        end

        private

        def registration_rp_mismatch?
          expected_rp_id = Auth::PendingMfaSession.passkey_registration_rp_id(session: @session)
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

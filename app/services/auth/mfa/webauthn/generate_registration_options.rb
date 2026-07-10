# frozen_string_literal: true

module Auth
  module Mfa
    module Webauthn
      class GenerateRegistrationOptions
        def self.call(user:, session:, webauthn: nil)
          new(user:, session:, webauthn:).call
        end

        def initialize(user:, session:, webauthn: nil)
          @user = user
          @session = session
          @webauthn = webauthn || global_webauthn_context
        end

        def call
          @user.ensure_webauthn_id!

          options = @webauthn.relying_party.options_for_registration(
            user: {
              id: @user.webauthn_id,
              name: @user.email,
              display_name: @user.name.presence || @user.email
            },
            exclude: @user.user_passkeys.where(rp_id: @webauthn.rp_id).pluck(:external_id),
            attestation: "none",
            authenticator_selection: {
              user_verification: "required"
            }
          )

          Auth::PendingMfaSession.store_passkey_registration_challenge(
            session: @session,
            challenge: options.challenge,
            rp_id: @webauthn.rp_id
          )
          options
        end

        private

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

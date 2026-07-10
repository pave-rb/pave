# frozen_string_literal: true

module Auth
  module Mfa
    module Webauthn
      class GenerateAuthenticationOptions
        def self.call(user:, session:, webauthn: nil)
          new(user:, session:, webauthn:).call
        end

        def initialize(user:, session:, webauthn: nil)
          @user = user
          @session = session
          @webauthn = webauthn || global_webauthn_context
        end

        def call
          options = @webauthn.relying_party.options_for_authentication(
            allow: @user.user_passkeys.where(rp_id: @webauthn.rp_id).pluck(:external_id),
            user_verification: "required"
          )

          Auth::PendingMfaSession.store_passkey_authentication_challenge(
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

# frozen_string_literal: true

require "uri"
require "webauthn"

module Pave
  module Identity
    module Webauthn
      Context = Struct.new(:rp_id, :rp_name, :allowed_origins, :relying_party, keyword_init: true)

      class ConfigurationError < StandardError; end

      class << self
        def relying_party_for(request, app_config: ::Rails.application.config, credentials: ::Rails.application.credentials, env: ENV)
          rp_id = rp_id_for(request, app_config:, credentials:, env:)
          rp_name = rp_name_for(app_config:, credentials:, env:)
          allowed_origins = allowed_origins_for(request, rp_id:, app_config:, credentials:, env:)

          Context.new(
            rp_id: rp_id,
            rp_name: rp_name,
            allowed_origins: allowed_origins,
            relying_party: ::WebAuthn::RelyingParty.new(
              id: rp_id,
              name: rp_name,
              allowed_origins: allowed_origins
            )
          )
        end

        def passkeys_for(user, rp_id:)
          user.user_passkeys.where(rp_id: rp_id)
        end

        private

        def rp_id_for(request, app_config:, credentials:, env:)
          host = normalized_host(request.host)
          return configured_backoffice_rp_id(app_config:, credentials:, env:).presence || host if admin_host?(host, app_config:)

          configured_product_rp_id(app_config:, credentials:, env:).presence || host
        end

        def allowed_origins_for(request, rp_id:, app_config:, credentials:, env:)
          host = normalized_host(request.host)
          configured_origins = if admin_host?(host, app_config:)
            configured_backoffice_allowed_origins(app_config:, credentials:, env:)
          else
            configured_product_allowed_origins(app_config:, credentials:, env:)
          end

          normalize_list(configured_origins).presence || [ request.base_url ]
        end

        def rp_name_for(app_config:, credentials:, env:)
          webauthn_config = webauthn_config(app_config)
          webauthn_credentials = credentials.dig(:webauthn) || {}
          app_settings = app_settings(app_config)
          app_credentials = credentials.dig(:app) || {}

          webauthn_config&.rp_name.presence ||
            webauthn_credentials[:rp_name].presence ||
            env["WEBAUTHN_RP_NAME"].presence ||
            app_settings&.authenticator_name.presence ||
            app_credentials[:authenticator_name].presence ||
            app_settings&.name.presence ||
            app_credentials[:name].presence ||
            "Pave"
        end

        def configured_backoffice_rp_id(app_config:, credentials:, env:)
          webauthn_config(app_config)&.backoffice_rp_id.presence ||
            credentials.dig(:webauthn, :backoffice_rp_id).presence ||
            env["WEBAUTHN_BACKOFFICE_RP_ID"].presence
        end

        def configured_product_rp_id(app_config:, credentials:, env:)
          webauthn_config(app_config)&.product_rp_id.presence ||
            credentials.dig(:webauthn, :product_rp_id).presence ||
            env["WEBAUTHN_PRODUCT_RP_ID"].presence
        end

        def configured_backoffice_allowed_origins(app_config:, credentials:, env:)
          webauthn_config(app_config)&.backoffice_allowed_origins.presence ||
            credentials.dig(:webauthn, :backoffice_allowed_origins).presence ||
            env["WEBAUTHN_BACKOFFICE_ALLOWED_ORIGINS"].presence
        end

        def configured_product_allowed_origins(app_config:, credentials:, env:)
          webauthn_config(app_config)&.product_allowed_origins.presence ||
            credentials.dig(:webauthn, :product_allowed_origins).presence ||
            env["WEBAUTHN_PRODUCT_ALLOWED_ORIGINS"].presence
        end

        def admin_host?(host, app_config:)
          admin_hosts = Array(app_settings(app_config)&.admin_hosts).map { |value| normalized_host(value) }
          admin_hosts.include?(host)
        end

        def app_settings(app_config)
          app_config.x.respond_to?(:app) ? app_config.x.app : nil
        end

        def webauthn_config(app_config)
          app_config.x.respond_to?(:webauthn) ? app_config.x.webauthn : nil
        end

        def normalize_list(value)
          case value
          when nil then []
          when String then value.split(",")
          else Array(value)
          end.filter_map { |item| item.to_s.strip.presence }.uniq
        end

        def normalized_host(value)
          value.to_s.split(":").first.to_s.downcase.delete_suffix(".")
        end
      end
    end
  end
end

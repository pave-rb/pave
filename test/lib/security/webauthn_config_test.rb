# frozen_string_literal: true

require "test_helper"

class WebauthnConfigTest < ActiveSupport::TestCase
  test "resolves explicit WebAuthn settings from config and environment" do
    webauthn_config = ordered_options(
      allowed_origins: [ "https://pave.test", "https://staging.pave.test" ],
      rp_id: "pave.test"
    )

    settings = Security::WebauthnConfig.resolved_settings(
      credentials: {},
      webauthn_config:,
      app_config: app_config,
      env: { "WEBAUTHN_RP_NAME" => "Pavê Admin" },
      default_rp_name: "Default App"
    )

    assert_equal [ "https://pave.test", "https://staging.pave.test" ], settings[:allowed_origins]
    assert_equal "pave.test", settings[:rp_id]
    assert_equal "Pavê Admin", settings[:rp_name]
  end

  test "falls back to app base urls when explicit origins are absent" do
    credentials = {
      app: {
        base_urls: [ "https://pave.test", "https://staging.pave.test" ]
      },
      webauthn: {
        rp_id: "pave.test"
      }
    }

    settings = Security::WebauthnConfig.resolved_settings(
      credentials:,
      webauthn_config: ordered_options,
      app_config: app_config,
      env: {},
      default_rp_name: "Pavê"
    )

    assert_equal [ "https://pave.test", "https://staging.pave.test" ], settings[:allowed_origins]
    assert_equal "pave.test", settings[:rp_id]
    assert_equal "Pavê", settings[:rp_name]
  end

  test "derives a single origin from action mailer defaults" do
    settings = Security::WebauthnConfig.resolved_settings(
      credentials: {},
      webauthn_config: ordered_options,
      app_config: app_config(
        force_ssl: false,
        mailer: { host: "localhost", port: 3000, protocol: "http" }
      ),
      env: {},
      default_rp_name: "Pavê"
    )

    assert_equal [ "http://localhost:3000" ], settings[:allowed_origins]
    assert_equal "localhost", settings[:rp_id]
  end

  test "requires an explicit rp_id when multiple origins are configured" do
    error = assert_raises(Security::WebauthnConfig::ConfigurationError) do
      Security::WebauthnConfig.resolved_settings(
        credentials: {
          app: {
            base_urls: [ "https://pave.test", "https://staging.pave.test" ]
          }
        },
        webauthn_config: ordered_options,
        app_config: app_config,
        env: {},
        default_rp_name: "Pavê"
      )
    end

    assert_equal "Configure WebAuthn rp_id explicitly when multiple allowed origins are used.", error.message
  end

  private

  def app_config(force_ssl: true, mailer: { host: "example.com" }, app: nil)
    OpenStruct.new(
      force_ssl: force_ssl,
      action_mailer: OpenStruct.new(default_url_options: mailer),
      x: ordered_options(app:)
    )
  end

  def ordered_options(**values)
    ActiveSupport::OrderedOptions.new.tap do |options|
      values.each do |key, value|
        options[key] = value
      end
    end
  end
end

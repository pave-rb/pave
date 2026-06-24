# frozen_string_literal: true

require "test_helper"

class MailerConfigurationTest < ActiveSupport::TestCase
  test "builds sender and url options from app base url when mailer credentials are absent" do
    credentials = ActiveSupport::InheritableOptions.new(
      app: {
        base_url: "https://staging.pave.test"
      }
    )

    assert_equal "noreply@staging.pave.test", MailerConfiguration.sender(credentials: credentials)
    assert_equal(
      { host: "staging.pave.test", protocol: "https" },
      MailerConfiguration.default_url_options(force_ssl: true, credentials: credentials)
    )
  end

  test "prefers explicit mailer credentials over app base url" do
    credentials = ActiveSupport::InheritableOptions.new(
      app: {
        base_url: "https://staging.pave.test"
      },
      mailer: {
        from: "support@pave.test",
        host: "mail.pave.test",
        protocol: "https",
        port: 8443
      }
    )

    assert_equal "support@pave.test", MailerConfiguration.sender(credentials: credentials)
    assert_equal(
      { host: "mail.pave.test", protocol: "https", port: 8443 },
      MailerConfiguration.default_url_options(force_ssl: true, credentials: credentials)
    )
  end
end

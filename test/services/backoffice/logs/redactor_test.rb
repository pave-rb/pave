# frozen_string_literal: true

require "test_helper"

module Backoffice
  module Logs
    class RedactorTest < ActiveSupport::TestCase
      test "redacts sensitive key value pairs" do
        line = "token=abc123 password: hunter2 api_key=\"secret-key\" status=500"

        redacted = Redactor.call(line)

        assert_includes redacted, "token=[FILTERED]"
        assert_includes redacted, "password: [FILTERED]"
        assert_includes redacted, "api_key=\"[FILTERED]\""
        assert_includes redacted, "status=500"
        refute_includes redacted, "abc123"
        refute_includes redacted, "hunter2"
        refute_includes redacted, "secret-key"
      end

      test "redacts bearer tokens and credential url params" do
        line = "Authorization: Bearer jwt-token callback=https://example.test/path?access_token=tok&state=keep"

        redacted = Redactor.call(line)

        assert_includes redacted, "Authorization: Bearer [FILTERED]"
        assert_includes redacted, "access_token=[FILTERED]"
        assert_includes redacted, "state=keep"
        refute_includes redacted, "jwt-token"
        refute_includes redacted, "access_token=tok"
      end

      test "does not mutate the original line" do
        line = +"secret=do-not-leak"

        Redactor.call(line)

        assert_equal "secret=do-not-leak", line
      end
    end
  end
end

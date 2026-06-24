# frozen_string_literal: true

module Backoffice
  module Logs
    class Redactor
      FILTERED = "[FILTERED]"
      SENSITIVE_KEYS = %w[
        access_token
        api_key
        client_secret
        credential
        password
        refresh_token
        secret
        token
      ].freeze

      KEY_VALUE_PATTERN = /
        (?<key>\b(?:#{SENSITIVE_KEYS.join("|")})\b)
        (?<separator>\s*[:=]\s*)
        (?<quote>["']?)
        (?<value>[^"'\s&]+)
        \k<quote>?
      /ix

      BEARER_PATTERN = /(Authorization\s*:\s*Bearer\s+)[^\s&]+/i

      def self.call(line)
        new(line).call
      end

      def initialize(line)
        @line = line.to_s
      end

      def call
        redact_key_values(redact_bearer_tokens(@line.dup))
      end

      private

      def redact_bearer_tokens(value)
        value.gsub(BEARER_PATTERN, "\\1#{FILTERED}")
      end

      def redact_key_values(value)
        value.gsub(KEY_VALUE_PATTERN) do
          match = Regexp.last_match
          "#{match[:key]}#{match[:separator]}#{match[:quote]}#{FILTERED}#{match[:quote]}"
        end
      end
    end
  end
end

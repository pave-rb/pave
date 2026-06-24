# frozen_string_literal: true

require "test_helper"

module Backoffice
  module Logs
    class QueryTest < ActiveSupport::TestCase
      FakeClient = Struct.new(:response, :error, :requests, keyword_init: true) do
        def query_range(**kwargs)
          self.requests ||= []
          requests << kwargs
          raise error if error

          response
        end
      end

      test "normalizes unsupported filters and caps large limits" do
        query = Query.new(
          params: {
            time_window: "7d",
            limit: "9999",
            signal: "everything"
          },
          client: FakeClient.new(response: loki_response),
          now: Time.zone.parse("2026-06-04 12:00:00")
        )

        assert_equal "1h", query.time_window
        assert_equal 500, query.limit
        assert_equal "all", query.signal
        assert_equal 1.hour, query.duration
      end

      test "escapes search terms before building the log query" do
        query = Query.new(
          params: {
            text: "fatal\" | json | line_format \"{{.secret}}\"",
            request_id: "req-123\" |= \"anything"
          },
          client: FakeClient.new(response: loki_response),
          now: Time.zone.parse("2026-06-04 12:00:00")
        )

        assert_includes query.loki_query, "{container_name=~\"appointment_scheduler-web.*\"}"
        assert_includes query.loki_query, "fatal"
        assert_includes query.loki_query, "req-123"
        refute_match(/\|\s+json/, query.loki_query)
        refute_match(/\|\s+line_format/, query.loki_query)
        refute_match(/\|=\s+\"anything/, query.loki_query)
      end

      test "queries loki with a bounded range and parses redacted entries" do
        now = Time.zone.parse("2026-06-04 12:00:00")
        client = FakeClient.new(response: loki_response(
          values: [
            [ "1780574400000000000", "status=500 token=secret-token" ],
            [ "1780574340000000000", "{\"status\":200,\"message\":\"ok\"}" ]
          ]
        ))
        query = Query.new(
          params: { time_window: "15m", limit: "250", signal: "errors" },
          client:,
          now:
        )

        result = query.call

        assert result.success?
        assert_equal 2, result.entries.size
        assert_equal 250, client.requests.first[:limit]
        assert_equal "backward", client.requests.first[:direction]
        assert_equal (now - 15.minutes).to_i * 1_000_000_000, client.requests.first[:start]
        assert_equal now.to_i * 1_000_000_000, client.requests.first[:end]
        assert_includes client.requests.first[:query], "error|exception|fatal"
        assert_equal "appointment_scheduler-web", result.entries.first.labels["container_name"]
        assert_equal "status=500 token=[FILTERED]", result.entries.first.line
        refute_includes result.entries.first.line, "secret-token"
      end

      test "returns an unavailable result when loki cannot be reached" do
        query = Query.new(
          params: {},
          client: FakeClient.new(error: Timeout::Error.new("execution expired")),
          now: Time.zone.parse("2026-06-04 12:00:00")
        )

        result = query.call

        refute result.success?
        assert_empty result.entries
        assert_equal :unavailable, result.error
      end

      private

      def loki_response(values: [ [ "1780574400000000000", "status=200" ] ])
        {
          "status" => "success",
          "data" => {
            "result" => [
              {
                "stream" => { "container_name" => "appointment_scheduler-web" },
                "values" => values
              }
            ]
          }
        }
      end
    end
  end
end

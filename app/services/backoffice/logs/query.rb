# frozen_string_literal: true

require "json"
require "net/http"
require "timeout"
require "uri"

module Backoffice
  module Logs
    class Query
      Entry = Struct.new(:timestamp, :line, :labels, keyword_init: true)
      Result = Struct.new(:entries, :error, keyword_init: true) do
        def success?
          error.blank?
        end
      end

      TIME_WINDOWS = {
        "15m" => 15.minutes,
        "1h" => 1.hour,
        "6h" => 6.hours,
        "24h" => 24.hours
      }.freeze
      LIMITS = [ 100, 250, 500 ].freeze
      SIGNALS = %w[all errors warnings 4xx 5xx].freeze
      DEFAULT_TIME_WINDOW = "1h"
      DEFAULT_LIMIT = 100
      DEFAULT_SIGNAL = "all"
      NANOSECONDS_PER_SECOND = 1_000_000_000
      STREAM_SELECTOR = "{container_name=~\"appointment_scheduler-web.*\"}"
      SIGNAL_FILTERS = {
        "all" => nil,
        "errors" => '|~ "(?i)(error|exception|fatal|status=5[0-9]{2}|\\\"status\\\":5[0-9]{2})"',
        "warnings" => '|~ "(?i)(warn|warning)"',
        "4xx" => '|~ "(status=4[0-9]{2}|\\\"status\\\":4[0-9]{2})"',
        "5xx" => '|~ "(status=5[0-9]{2}|\\\"status\\\":5[0-9]{2})"'
      }.freeze

      attr_reader :time_window, :limit, :signal, :text, :request_id, :now

      def initialize(params:, client: Client.new, now: Time.current)
        @params = normalize_params(params)
        @client = client
        @now = now
        @time_window = normalize_time_window(@params[:time_window])
        @limit = normalize_limit(@params[:limit])
        @signal = normalize_signal(@params[:signal])
        @text = normalize_search(@params[:text], max_length: 120)
        @request_id = normalize_search(@params[:request_id], max_length: 80)
      end

      def call
        payload = @client.query_range(
          query: loki_query,
          start: start_nanoseconds,
          end: end_nanoseconds,
          limit:,
          direction: "backward"
        )

        return Result.new(entries: [], error: :unavailable) unless payload["status"] == "success"

        Result.new(entries: entries_from(payload), error: nil)
      rescue Client::Error, JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, Timeout::Error,
             SocketError, Errno::ECONNREFUSED
        Result.new(entries: [], error: :unavailable)
      end

      def duration
        TIME_WINDOWS.fetch(time_window)
      end

      def filters
        {
          time_window:,
          limit:,
          signal:,
          text:,
          request_id:
        }.compact
      end

      def loki_query
        parts = [ STREAM_SELECTOR ]
        parts << SIGNAL_FILTERS.fetch(signal)
        parts << %( |~ "#{escape_logql_regex(text)}") if text.present?
        parts << %( |= "#{escape_logql_literal(request_id)}") if request_id.present?
        parts.compact.join
      end

      private

      def normalize_params(params)
        source = params.respond_to?(:to_h) ? params.to_h : params
        source.with_indifferent_access
      end

      def normalize_time_window(value)
        TIME_WINDOWS.key?(value.to_s) ? value.to_s : DEFAULT_TIME_WINDOW
      end

      def normalize_limit(value)
        integer = Integer(value, exception: false)
        return DEFAULT_LIMIT unless integer
        return LIMITS.max if integer > LIMITS.max

        LIMITS.include?(integer) ? integer : DEFAULT_LIMIT
      end

      def normalize_signal(value)
        SIGNALS.include?(value.to_s) ? value.to_s : DEFAULT_SIGNAL
      end

      def normalize_search(value, max_length:)
        normalized = value.to_s.strip
        return if normalized.blank?

        normalized.first(max_length)
      end

      def start_nanoseconds
        (now - duration).to_i * NANOSECONDS_PER_SECOND
      end

      def end_nanoseconds
        now.to_i * NANOSECONDS_PER_SECOND
      end

      def entries_from(payload)
        Array(payload.dig("data", "result")).flat_map do |stream|
          labels = stream.fetch("stream", {})
          Array(stream["values"]).map do |timestamp, line|
            Entry.new(
              timestamp: parse_timestamp(timestamp),
              line: Redactor.call(line),
              labels:
            )
          end
        end
      end

      def parse_timestamp(timestamp)
        Time.zone.at(timestamp.to_i / NANOSECONDS_PER_SECOND.to_f)
      end

      def escape_logql_regex(value)
        escape_logql_literal(Regexp.escape(value.to_s))
      end

      def escape_logql_literal(value)
        value.to_s.gsub("\\") { "\\\\" }.gsub('"') { '\"' }.delete("\n")
      end

      class Client
        Error = Class.new(StandardError)

        def initialize(base_url: self.class.default_base_url)
          @base_url = base_url.to_s
        end

        def query_range(query:, start:, end:, limit:, direction:)
          uri = query_range_uri(query:, start:, end:, limit:, direction:)
          response = request(uri)
          raise Error, "Loki returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

          JSON.parse(response.body)
        end

        def self.default_base_url
          Rails.application.credentials.dig(:observability, :loki_url).presence ||
            ENV["LOKI_URL"].presence ||
            "http://loki:3100"
        end

        private

        def query_range_uri(query:, start:, end:, limit:, direction:)
          uri = URI.join(@base_url.chomp("/") + "/", "loki/api/v1/query_range")
          uri.query = URI.encode_www_form(query:, start:, end:, limit:, direction:)
          uri
        end

        def request(uri)
          Net::HTTP.start(
            uri.hostname,
            uri.port,
            use_ssl: uri.scheme == "https",
            open_timeout: 2,
            read_timeout: 5
          ) do |http|
            http.get(uri.request_uri, "Accept" => "application/json")
          end
        end
      end
    end
  end
end

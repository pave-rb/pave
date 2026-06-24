# frozen_string_literal: true

require "test_helper"

module Backoffice
  class LogsControllerTest < ActionDispatch::IntegrationTest
    FakeEntry = Struct.new(:timestamp, :line, :labels, keyword_init: true)

    FakeResult = Struct.new(:entries, :error, keyword_init: true) do
      def success?
        error.blank?
      end
    end

    FakeQuery = Struct.new(:filters, :result, keyword_init: true) do
      def call
        result
      end

      def time_window
        filters[:time_window]
      end

      def limit
        filters[:limit]
      end

      def signal
        filters[:signal]
      end

      def text
        filters[:text]
      end

      def request_id
        filters[:request_id]
      end
    end

    setup do
      @admin = users(:admin)
      @manager = users(:manager)
    end

    test "unauthenticated users are redirected to login" do
      get backoffice_logs_path

      assert_redirected_to new_user_session_path
    end

    test "non-admin users are redirected to root" do
      sign_in @manager

      get backoffice_logs_path

      assert_redirected_to root_path
    end

    test "super admin can view recent operational logs" do
      sign_in @admin
      fake_query = fake_query_with(entries: [
        FakeEntry.new(
          timestamp: Time.zone.parse("2026-06-04 12:00:00"),
          line: "status=500 request_id=req-123",
          labels: { "container_name" => "appointment_scheduler-web" }
        )
      ])

      Backoffice::Logs::Query.stub(:new, ->(params:) { fake_query }) do
        get backoffice_logs_path, params: { time_window: "15m", signal: "errors", limit: "100" }
      end

      assert_response :success
      assert_select "h1", text: I18n.t("backoffice.logs.index.title")
      assert_select "code", text: /status=500 request_id=req-123/
    end

    test "super admin log access is audited with filter metadata" do
      sign_in @admin
      fake_query = fake_query_with(entries: [], request_id: "req-123")

      assert_difference "AuditLog.count", 1 do
        Backoffice::Logs::Query.stub(:new, ->(params:) { fake_query }) do
          get backoffice_logs_path, params: { request_id: "req-123" }
        end
      end

      audit_log = AuditLog.order(:id).last
      assert_equal "operations.logs_viewed", audit_log.event_type
      assert_equal @admin, audit_log.actor
      assert_equal "backoffice_logs", audit_log.metadata["surface"]
      assert_equal "req-123", audit_log.metadata.dig("filters", "request_id")
      refute_includes audit_log.metadata.to_json, "status=500"
    end

    test "only permitted filters are passed to the query service" do
      sign_in @admin
      captured_params = nil
      fake_query = fake_query_with(entries: [])

      Backoffice::Logs::Query.stub(:new, ->(params:) { captured_params = params.to_h; fake_query }) do
        get backoffice_logs_path, params: {
          time_window: "6h",
          limit: "250",
          signal: "warnings",
          text: "webhook",
          request_id: "req-123",
          query: "{free_form=\"bad\"}"
        }
      end

      assert_response :success
      assert_equal(
        {
          "time_window" => "6h",
          "limit" => "250",
          "signal" => "warnings",
          "text" => "webhook",
          "request_id" => "req-123"
        },
        captured_params
      )
    end

    test "loki unavailable state renders without raising" do
      sign_in @admin
      fake_query = fake_query_with(error: :unavailable)

      Backoffice::Logs::Query.stub(:new, ->(params:) { fake_query }) do
        get backoffice_logs_path
      end

      assert_response :success
      assert_select "[data-role='logs-unavailable']"
    end

    private

    def fake_query_with(entries: [], error: nil, request_id: nil)
      FakeQuery.new(
        filters: {
          time_window: "15m",
          limit: 100,
          signal: "all",
          text: nil,
          request_id:
        },
        result: FakeResult.new(entries:, error:)
      )
    end
  end
end

# frozen_string_literal: true

module Backoffice
  class LogsController < BaseController
    def index
      @logs_query = Backoffice::Logs::Query.new(params: logs_params)
      @logs_result = @logs_query.call

      audit_logs_viewed
    end

    private

    def logs_params
      params.permit(:time_window, :limit, :signal, :text, :request_id)
    end

    def audit_logs_viewed
      AuditLogs::EventLogger.call(
        event_type: "operations.logs_viewed",
        actor: real_current_user,
        request:,
        metadata: audit_context_metadata.merge(
          surface: "backoffice_logs",
          filters: @logs_query.filters,
          loki_status: @logs_result.success? ? "available" : "unavailable"
        )
      )
    end
  end
end

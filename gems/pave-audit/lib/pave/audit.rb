# frozen_string_literal: true

require "pave/audit/version"
require "pave/audit/engine"
require "pave/audit/error"
require "pave/audit/event_builder"

module Pave
  module Audit
    class << self
      def log(**attrs)
        event = EventBuilder.new(**attrs).build
        event.save
        if event.persisted?
          Result.success(event)
        else
          Result.failure(event.errors.first&.full_message || "audit event not persisted")
        end
      rescue ActiveRecord::RecordNotUnique => e
        Result.failure(Pave::ConflictError.new("duplicate idempotency_key", context: { idempotency_key: attrs[:idempotency_key] }))
      rescue Pave::Audit::Error => e
        Result.failure(e)
      end

      def log!(**attrs)
        event = EventBuilder.new(**attrs).build
        event.save!
        event
      rescue ActiveRecord::RecordInvalid => e
        raise Pave::ValidationError, e.message
      rescue ActiveRecord::RecordNotUnique => e
        raise Pave::ConflictError, "duplicate idempotency_key"
      rescue Pave::Audit::Error => e
        raise e
      end
    end
  end
end

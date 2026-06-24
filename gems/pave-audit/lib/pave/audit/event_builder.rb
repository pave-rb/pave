# frozen_string_literal: true

module Pave
  module Audit
    class EventBuilder
      attr_reader :attrs

      def initialize(**attrs)
        @attrs = attrs
      end

      def build
        AuditEvent.new(
          space_id: resolve_space_id,
          key: attrs[:key],
          actor_type: resolve_polymorphic_type(attrs[:actor]),
          actor_id: resolve_polymorphic_id(attrs[:actor]),
          actor_label: attrs[:actor_label],
          target_type: resolve_polymorphic_type(attrs[:target]),
          target_id: resolve_polymorphic_id(attrs[:target]),
          target_label: attrs[:target_label],
          metadata: normalize_metadata(attrs[:metadata]),
          request_id: attrs[:request_id] || Pave::Current.request_id,
          idempotency_key: attrs[:idempotency_key],
          source: attrs[:source],
          occurred_at: attrs[:occurred_at] || Time.current
        )
      end

      private

      def resolve_space_id
        space = attrs[:space]
        space ||= Pave::Current.space
        space&.id
      end

      def resolve_polymorphic_type(record)
        record.class.base_class.name if record
      end

      def resolve_polymorphic_id(record)
        record.id if record
      end

      def normalize_metadata(value)
        hash = (value || {}).deep_stringify_keys
        validate_serializable!(hash)
        hash
      end

      def validate_serializable!(hash)
        hash.each_value do |v|
          next if v.nil? || v.is_a?(String) || v.is_a?(Numeric) || v.is_a?(TrueClass) ||
                  v.is_a?(FalseClass) || v.is_a?(Array) || v.is_a?(Hash)

          raise Pave::Audit::Error, "Unserializable metadata value: #{v.class}"
        end
      end
    end
  end
end

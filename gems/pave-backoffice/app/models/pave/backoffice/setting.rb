# frozen_string_literal: true

module Pave
  module Backoffice
    class Setting < ActiveRecord::Base
      self.table_name = "pave_settings"

      encrypts :value

      belongs_to :updated_by,
        class_name: "Pave::Identity::User",
        optional: true

      VALUE_TYPES = %w[string integer boolean].freeze

      validates :namespace, presence: true
      validates :key, presence: true
      validates :value_type, inclusion: { in: VALUE_TYPES }
      validates :key, uniqueness: { scope: :namespace }

      before_validation :normalize_namespace_and_key

      def cast_value
        case value_type
        when "integer"
          value.to_i
        when "boolean"
          ActiveModel::Type::Boolean.new.cast(value)
        else
          value
        end
      end

      private

      def normalize_namespace_and_key
        self.namespace = namespace.to_s.strip if namespace
        self.key = key.to_s.strip if key
      end
    end
  end
end

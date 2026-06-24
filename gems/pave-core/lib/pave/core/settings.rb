# frozen_string_literal: true

module Pave
  module Settings
    Definition = Data.define(:key, :type, :encrypted, :required, :metadata)
    Schema = Data.define(:namespace, :definitions) do
      def keys
        definitions.keys
      end

      def definition_for(key)
        definitions[Settings.normalize_key(key)]
      end
    end

    class MissingSettingError < ConfigurationError
      default_code :missing_setting
    end

    class Builder
      def initialize(namespace)
        @namespace = namespace
        @definitions = {}
      end

      def key(name, type: :string, encrypted: false, required: false, **metadata)
        normalized_key = Settings.normalize_key(name)
        @definitions[normalized_key] = Definition.new(
          normalized_key,
          Settings.normalize_key(type),
          encrypted == true,
          required == true,
          metadata.freeze
        )
      end

      def schema
        Schema.new(@namespace, @definitions.dup.freeze)
      end
    end

    class << self
      attr_writer :adapter

      def define(namespace)
        normalized_namespace = normalize_key(namespace)
        builder = Builder.new(normalized_namespace)
        yield builder
        schemas[normalized_namespace] = builder.schema
      end

      def get(namespace, key)
        adapter_value = read_adapter(namespace, key)
        return adapter_value unless adapter_value.nil?

        read_credentials(namespace, key)
      end

      def get!(namespace, key)
        value = get(namespace, key)
        return value unless value.nil?

        raise MissingSettingError.new(
          "missing setting #{normalize_key(namespace)}.#{normalize_key(key)}",
          context: { namespace: normalize_key(namespace), key: normalize_key(key) }
        )
      end

      def schema_for(namespace)
        schemas[normalize_key(namespace)]
      end

      def namespaces
        schemas.keys
      end

      def adapter
        @adapter
      end

      def reset!
        @schemas = {}
        @adapter = nil
      end

      def normalize_key(value)
        normalized = value.to_s.strip
        raise ConfigurationError.new("setting key cannot be blank", code: :blank_setting_key) if normalized.empty?

        normalized.to_sym
      end

      private

      def schemas
        @schemas ||= {}
      end

      def read_adapter(namespace, key)
        return nil unless adapter

        adapter.get(normalize_key(namespace), normalize_key(key))
      end

      def read_credentials(namespace, key)
        return nil unless defined?(::Rails) && ::Rails.respond_to?(:application)

        credentials = ::Rails.application.credentials
        return nil unless credentials.respond_to?(:dig)

        credentials.dig(normalize_key(namespace), normalize_key(key))
      end
    end
  end
end

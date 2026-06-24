# frozen_string_literal: true

module Pave
  module Backoffice
    class SettingsAdapter
      Status = Data.define(:source, :encrypted, :required, :present, :updated_at) do
        def encrypted? = encrypted
        def required? = required
        def present? = present
      end

      def get(namespace, key)
        setting = find_setting(namespace, key)
        setting&.cast_value
      end

      def status(namespace, key)
        normalized_namespace = normalize(namespace)
        normalized_key = normalize(key)
        definition = Pave::Settings.schema_for(normalized_namespace)&.definition_for(normalized_key)
        setting = find_setting(normalized_namespace, normalized_key)

        if setting
          return Status.new(:database, encrypted?(definition), required?(definition), true, setting.updated_at)
        end

        unless credentials_value(normalized_namespace, normalized_key).nil?
          return Status.new(:credentials, encrypted?(definition), required?(definition), true, nil)
        end

        source = required?(definition) ? :missing : :optional_unset
        Status.new(source, encrypted?(definition), required?(definition), false, nil)
      end

      def write_namespace(namespace, attributes, updated_by: nil)
        normalized_namespace = normalize(namespace)
        schema = Pave::Settings.schema_for(normalized_namespace)
        raise Pave::ConfigurationError, "unknown settings namespace #{normalized_namespace}" unless schema

        Pave::Backoffice::Setting.transaction do
          attributes.each do |key, value|
            normalized_key = normalize(key)
            definition = schema.definition_for(normalized_key)
            raise Pave::ConfigurationError, "unknown setting #{normalized_namespace}.#{normalized_key}" unless definition

            setting = Pave::Backoffice::Setting.find_or_initialize_by(
              namespace: normalized_namespace.to_s,
              key: normalized_key.to_s
            )
            setting.value_type = definition.type.to_s
            setting.value = value
            setting.updated_by = updated_by if updated_by
            setting.save!
          end
        end
      end

      private

      def find_setting(namespace, key)
        Pave::Backoffice::Setting.find_by(
          namespace: normalize(namespace).to_s,
          key: normalize(key).to_s
        )
      end

      def normalize(value)
        Pave::Settings.normalize_key(value)
      end

      def credentials_value(namespace, key)
        return nil unless defined?(::Rails) && ::Rails.respond_to?(:application)

        credentials = ::Rails.application.credentials
        return nil unless credentials.respond_to?(:dig)

        credentials.dig(namespace, key)
      end

      def encrypted?(definition)
        definition&.encrypted == true
      end

      def required?(definition)
        definition&.required == true
      end
    end
  end
end

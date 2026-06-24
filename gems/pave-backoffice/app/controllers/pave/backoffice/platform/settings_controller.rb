# frozen_string_literal: true

module Pave
  module Backoffice
    module Platform
      class SettingsController < Pave::Backoffice::BaseController
        Field = Data.define(:definition, :status, :value)
        Namespace = Data.define(:key, :schema, :fields, :required_count, :missing_count, :last_updated)

        def index
          load_namespaces
        end

        def update
          @namespace_key = Pave::Settings.normalize_key(params.require(:namespace))
          @schema = Pave::Settings.schema_for(@namespace_key)

          raise Pave::ConfigurationError, "unknown settings namespace #{@namespace_key}" unless @schema

          attributes = permitted_settings.to_h.symbolize_keys
          clear_keys = Array(params[:clear_settings]).map { |key| Pave::Settings.normalize_key(key) }
          writes, cleared = validate_namespace_attributes(attributes, clear_keys)

          if @errors.any?
            load_namespaces
            flash.now[:alert] = "Some settings need attention before they can be saved."
            render :index, status: :unprocessable_entity
            return
          end

          Pave::Backoffice::Setting.transaction do
            clear_namespace_keys(cleared)
            Pave::Settings.adapter.write_namespace(@namespace_key, writes, updated_by: identity_current_admin) if writes.any?
          end

          audit_admin(
            "backoffice.settings.updated",
            metadata: {
              namespace: @namespace_key.to_s,
              changed_keys: writes.keys.map(&:to_s).sort,
              cleared_keys: cleared.map(&:to_s).sort
            }
          )

          redirect_to settings_path(namespace: @namespace_key), notice: "Settings saved. A backoffice audit event was recorded."
        end

        private

        def load_namespaces
          @selected_namespace = params[:namespace].presence&.then { |value| Pave::Settings.normalize_key(value) }
          @errors ||= {}
          @namespaces = Pave::Settings.namespaces.sort.map { |namespace| build_namespace(namespace) }
          @selected_namespace ||= @namespaces.first&.key
        end

        def build_namespace(namespace)
          schema = Pave::Settings.schema_for(namespace)
          fields = schema.definitions.values.map do |definition|
            status = Pave::Settings.adapter.status(namespace, definition.key)
            value = definition.encrypted ? nil : Pave::Settings.get(namespace, definition.key)
            Field.new(definition, status, value)
          end

          Namespace.new(
            namespace,
            schema,
            fields,
            fields.count { |field| field.definition.required },
            fields.count { |field| field.status.source == :missing },
            fields.filter_map { |field| field.status.updated_at }.max
          )
        end

        def permitted_settings
          params.fetch(:settings, {}).permit(*@schema.keys.map(&:to_s))
        end

        def validate_namespace_attributes(attributes, clear_keys)
          @errors = {}
          writes = {}
          cleared = []

          @schema.definitions.each_value do |definition|
            clear_requested = clear_keys.include?(definition.key)
            raw_value = attributes[definition.key]
            status = Pave::Settings.adapter.status(@namespace_key, definition.key)

            if clear_requested
              if credentials_present_after_clear?(definition.key)
                cleared << definition.key
              elsif definition.required
                add_error(definition.key, "cannot be cleared without a credentials fallback")
              else
                cleared << definition.key
              end
              next
            end

            if definition.encrypted && raw_value.blank?
              add_error(definition.key, "is required") if definition.required && !status.present?
              next
            end

            if raw_value.blank?
              add_error(definition.key, "is required") if definition.required
              writes[definition.key] = raw_value unless definition.encrypted
              next
            end

            writes[definition.key] = cast_form_value(definition, raw_value)
          end

          [writes, cleared]
        end

        def cast_form_value(definition, raw_value)
          case definition.type
          when :integer
            unless raw_value.to_s.match?(/\A-?\d+\z/)
              add_error(definition.key, "must be an integer")
              return raw_value
            end
            raw_value
          when :boolean
            unless %w[0 1 true false].include?(raw_value.to_s)
              add_error(definition.key, "must be true or false")
              return raw_value
            end
            raw_value
          else
            raw_value
          end
        end

        def clear_namespace_keys(keys)
          return if keys.empty?

          Pave::Backoffice::Setting.where(namespace: @namespace_key.to_s, key: keys.map(&:to_s)).delete_all
        end

        def credentials_present_after_clear?(key)
          previous_adapter = Pave::Settings.adapter
          Pave::Settings.adapter = nil
          !Pave::Settings.get(@namespace_key, key).nil?
        ensure
          Pave::Settings.adapter = previous_adapter
        end

        def add_error(key, message)
          @errors[key] ||= []
          @errors[key] << message
        end

        def identity_current_admin
          Pave::Identity::User.find(current_admin.id)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Pave
  class Plugin
    Metadata = Data.define(:name, :dependencies, :capabilities, :events, :metadata)

    class << self
      def plugin_name(name = nil)
        @plugin_name = normalize_key(name) if name
        @plugin_name
      end

      def depends_on(*names)
        dependencies.concat(names.flatten.map { |name| normalize_key(name) })
      end

      def capability(key, **metadata)
        capabilities << [ normalize_key(key), metadata.freeze ]
      end

      def event(key, **metadata)
        events << [ normalize_key(key), metadata.freeze ]
      end

      def register(registry = Pave.registry)
        raise ConfigurationError, "plugin_name is required" unless plugin_name

        registry.register_plugin(plugin_name, dependencies: dependencies, **plugin_metadata)
        capabilities.each { |key, metadata| registry.register_capability(key, plugin: plugin_name, **metadata) }
        events.each { |key, metadata| registry.register_event(key, plugin: plugin_name, **metadata) }
        metadata
      end

      def metadata(**metadata)
        @plugin_metadata = plugin_metadata.merge(metadata).freeze if metadata.any?
        Metadata.new(plugin_name, dependencies.dup.freeze, capabilities.to_h.freeze, events.to_h.freeze, plugin_metadata)
      end

      private

      def dependencies
        @dependencies ||= []
      end

      def capabilities
        @capabilities ||= []
      end

      def events
        @events ||= []
      end

      def plugin_metadata
        @plugin_metadata ||= {}.freeze
      end

      def normalize_key(key)
        key.to_s.strip.to_sym
      end
    end
  end
end

# frozen_string_literal: true

module Pave
  class Registry
    Entry = Data.define(:key, :metadata)
    PluginEntry = Data.define(:name, :metadata)

    def initialize
      @plugins = {}
      @capabilities = {}
      @events = {}
    end

    def register_plugin(name, **metadata)
      key = normalize_key(name, "plugin name")
      raise RegistryError.new("plugin already registered", code: :duplicate_plugin, context: { plugin: key }) if @plugins.key?(key)

      @plugins[key] = PluginEntry.new(key, metadata.freeze)
    end

    def register_capability(key, **metadata)
      register_entry(@capabilities, key, "capability", metadata)
    end

    def register_event(key, **metadata)
      register_entry(@events, key, "event", metadata)
    end

    def plugin(name)
      @plugins[normalize_key(name, "plugin name")]
    end

    def capability(key)
      @capabilities[normalize_key(key, "capability")]
    end

    def event(key)
      @events[normalize_key(key, "event")]
    end

    def plugins
      @plugins.values
    end

    def capabilities
      @capabilities.values
    end

    def events
      @events.values
    end

    private

    def register_entry(collection, key, label, metadata)
      normalized_key = normalize_key(key, label)
      raise RegistryError.new("#{label} already registered", code: :duplicate_entry, context: { key: normalized_key }) if collection.key?(normalized_key)

      collection[normalized_key] = Entry.new(normalized_key, metadata.freeze)
    end

    def normalize_key(key, label)
      normalized_key = key.to_s.strip
      raise RegistryError.new("#{label} cannot be blank", code: :blank_key, context: { label: label }) if normalized_key.empty?

      normalized_key.to_sym
    end
  end
end

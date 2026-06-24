# pave-core

Internal Pavê runtime package for core runtime primitives.

## Public APIs

### Configuration

```ruby
Pave.configure do |config|
  root = Pathname.pwd
  config.runtime_root = root.join("runtime")
  config.products_root = root.join("products")
  config.plugins_root = root.join("plugins")
end
```

### Current Context

`Pave::Current` exposes only runtime context slots: `user`, `actor`, `space`, `request_id`, and `impersonator`.

### Services And Results

```ruby
class ExampleService < Pave::Service
  def call(value)
    return failure(Pave::ValidationError.new("value is blank")) if value.blank?

    success(value)
  end
end
```

### Registry And Plugins

```ruby
class ExamplePlugin < Pave::Plugin
  plugin_name :example
  depends_on :core
  capability :example_capability
  event :example_happened
end

ExamplePlugin.register(Pave.registry)
```

The registry stores metadata only. Runtime packages should not constantize product classes from registry entries.

### Settings

```ruby
Pave::Settings.define(:billing) do |settings|
  settings.key :webhook_secret, type: :string, encrypted: true
end

Pave::Settings.get(:billing, :webhook_secret)
Pave::Settings.get!(:billing, :webhook_secret)
Pave::Settings.schema_for(:billing)
Pave::Settings.namespaces
```

`Pave::Settings` reads from an installed adapter first and falls back to `Rails.application.credentials.dig(namespace, key)` when no adapter value exists.

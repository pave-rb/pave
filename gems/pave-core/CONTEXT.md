# pave-core — Pure Ruby Runtime Contracts

## Purpose

Core runtime primitives that must not depend on Rails.
Provides the foundation for all other Pavê gems.

## Public API

```ruby
Pave.configure { |config| ... }  # Runtime configuration
Pave.registry                     # Product/plugin/resource registry
Pave::Current                     # Per-request context (space, user)
Pave::Service                     # Base class for service objects
Pave::Result                      # Service result wrapper
Pave::Registry                    # Declarative registry
Pave::Plugin                      # Plugin manifest base
Pave::Error                       # Error hierarchy base
Pave::Configuration               # Runtime configuration store
```

## Example (using a DummyProduct)

```ruby
Pave.configure do |config|
  config.product :demo_scheduling, path: "test/dummy/products/demo_scheduling"
end
```

## Dependencies

- None (pure Ruby, no Rails dependency)

## Testing

Tests are in `test/` and run via `bundle exec rake test`.

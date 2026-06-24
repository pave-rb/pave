# pave-rails — Rails Integration

## Purpose

Rails integration gem. Provides the Railtie, engine, install generators, product boot, and Rails-aware CLI commands.

## Public API

```ruby
Pave::Rails::Engine     # Rails engine
Pave::Rails::Railtie    # Railtie for boot hooks
```

## Generators

```bash
bin/rails generate pave:install          # Install Pavê in a host app
bin/rails generate pave:product <name>   # Generate a product scaffold
```

## Example

```ruby
# In a host app after running the install generator:
# config/pave.rb is created for product registration
# products/ directory is created for product packages
```

## Dependencies

- pave-core
- rails (>= 8.0)

## Testing

Tests are in `test/` and run via `bundle exec rake test`.

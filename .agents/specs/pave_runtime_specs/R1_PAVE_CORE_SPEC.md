# R1 — pave-core Specification

## Intent

Create the foundational runtime primitives that every later Pavê package and product writes against.

R1 is critical because mistakes here propagate into tenancy, audit, identity, billing, backoffice, plugins, and future products.

R1 produces no visible behavior change in Anella.

## Dependencies

- R0 complete.
- Runtime packages load.
- CI green.

`pave-core` must not depend on any other Pavê runtime package.

## Outcome

`pave-core` defines the core namespace, configuration, current context, service pattern, error hierarchy, registry, and plugin DSL skeleton.

## Scope

Implement from scratch:

```text
Pave
Pave.configure
Pave.config
Pave::Configuration
Pave::Current
Pave::Service
Pave::Result
Pave::Error hierarchy
Pave::Registry
Pave::Plugin DSL skeleton
```

### `Pave.configure`

Expected use:

```ruby
Pave.configure do |config|
  config.runtime_root = Rails.root.join("runtime")
  config.products_root = Rails.root.join("products")
  config.plugins_root = Rails.root.join("plugins")
end
```

Configuration must be explicit, inspectable, and safe to access after boot.

### `Pave::Current`

Implement as an `ActiveSupport::CurrentAttributes` wrapper.

Allowed attributes at R1:

```ruby
attribute :user
attribute :actor
attribute :space
attribute :request_id
attribute :impersonator
```

`space` is only a contextual slot in R1. R2 owns `Space` and tenancy wiring.

Do not reference Anella user classes, Devise, controllers, or `Space` constants from R1.

### `Pave::Service`

Provide a minimal service base that supports explicit inputs and consistent result/error handling.

Expected use:

```ruby
class SomeService < Pave::Service
  def call
    success(value: ...)
  rescue Pave::Error => error
    failure(error)
  end
end

SomeService.call(...)
```

Required behavior:

- `.call(**kwargs)` class method
- instance initialization with keyword args
- `success(value: nil, **metadata)` helper
- `failure(error, **metadata)` helper
- returns `Pave::Result`
- does not swallow unexpected exceptions unless a subclass explicitly handles them

### `Pave::Result`

Minimal immutable-ish object:

```ruby
result.success?
result.failure?
result.value
result.error
result.metadata
```

Do not introduce monadic dependency gems at R1.

### Error hierarchy

Create a small hierarchy:

```text
Pave::Error
Pave::ConfigurationError
Pave::RegistryError
Pave::ValidationError
Pave::AuthorizationError
Pave::NotFoundError
Pave::ConflictError
Pave::DependencyError
Pave::TenantScopeError
Pave::IntegrationError
```

Each error should support:

```ruby
message
code
context
```

`context` must be a hash and safe to serialize.

### `Pave::Registry`

Implement a runtime registry for metadata, not a service locator for arbitrary objects.

R1 registry can support:

```ruby
register(:plugin, key, metadata)
register(:capability, key, metadata)
register(:event, key, metadata)
fetch(type, key)
all(type)
clear!
validate!
```

Validation rules:

- keys are symbols or strings normalized to strings
- keys must be namespace-safe: lowercase, numbers, `_`, `.`, `-`
- duplicate registrations fail unless explicit `replace: true`
- metadata is duplicated/frozen where practical

Do not let registry invoke application constants dynamically on request paths.

### `Pave::Plugin` DSL skeleton

R1 only defines the DSL shape. Later phases and the WhatsApp plugin will prove it.

Expected shape:

```ruby
class SomePlugin < Pave::Plugin
  plugin_name "some_plugin"
  depends_on "pave-core"

  capability "some_plugin.manage"
  event "some_plugin.installed"

  register do |registry|
    # no-op or metadata registration
  end
end
```

Allowed DSL declarations at R1:

- `plugin_name`
- `depends_on`
- `capability`
- `event`
- `register`

Do not implement install/uninstall hooks, migrations, backoffice panels, billing hooks, or route mounting in R1.

## Non-goals

- Do not move any Anella code.
- Do not implement tenancy, audit, identity, billing, or backoffice.
- Do not implement `Pave::Resource` yet unless it already exists and only needs namespacing; resource/action DSL belongs after runtime extraction hardens.
- Do not add database tables.
- Do not add UI.
- Do not add product manifests beyond what R0 already needs.

## Expected files touched

```text
runtime/pave-core/lib/pave/core.rb
runtime/pave-core/lib/pave.rb          # only if needed as umbrella require
runtime/pave-core/lib/pave/core/*
runtime/pave-core/test/**/* or spec/**/*
runtime/pave-core/package.yml
bin/pave                               # only to use core configuration/registry if safe
```

## Tests

Add focused unit tests for:

- configuration defaults and overrides
- `Pave::Current` attributes reset between examples
- service `.call` behavior
- result success/failure behavior
- error code/context behavior
- registry duplicate handling
- registry validation
- plugin DSL metadata capture

## Acceptance criteria

- R0 checks remain green.
- `pave-core` can load without loading Anella.
- `Pave.configure` is documented and tested.
- `Pave::Current` has no app-specific dependencies.
- `Pave::Service` is small and boring.
- Registry stores metadata only.
- Plugin DSL is declared but not overbuilt.
- No database migrations.
- No Anella files are moved.

## Contamination checks

Search runtime code for these terms and justify any hit:

```bash
grep -R "Anella\|Appointment\|Whatsapp\|Asaas\|booking\|clinic\|salon" runtime/pave-core || true
```

Expected result: no product-domain hits.

## Handoff note

The R1 handoff must include:

- final public API list
- explicit non-goals deferred to later phases
- any changes to `bin/pave doctor`
- tests added
- proof that Anella behavior did not change

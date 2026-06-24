# pave-tenancy — Multi-Tenancy

## Purpose

Provides tenant (Space) model, request lifecycle, and scoped base controllers.

## Public API

```ruby
Pave::Tenancy.with_space(space) { ... }   # Execute block in space context
Pave::Tenancy.current_space               # Current request's space
Pave::Tenancy.space_required!             # Guard: ensure space is set
Pave::Tenancy.assert_same_space!(scope)   # Guard: ensure scope matches space
Pave::Tenancy::Space                      # Tenant model
Pave::Tenancy::SpaceMembership            # User-space membership
Pave::Tenancy::BaseController             # Space-scoped base controller
```

## Example

```ruby
Pave::Tenancy.with_space(space) do
  Pave::Tenancy.current_space # => space
end
```

## Dependencies

- pave-core

## Testing

Tests use `DemoScheduling` as a dummy product for integration tests.

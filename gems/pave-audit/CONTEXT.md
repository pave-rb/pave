# pave-audit — Immutable Audit Log

## Purpose

Immutable append-only event log for auditing domain events.

## Public API

```ruby
Pave::Audit.log(event_type, space:, actor:, target:, metadata:)
Pave::Audit.log!(...)         # Raises on failure
Pave::Audit::AuditEvent       # Immutable event record
Pave::Audit::Error            # Audit-specific errors
```

## Example

```ruby
Pave::Audit.log("user.updated",
  space: current_space,
  actor: current_user,
  target: user,
  metadata: { changes: user.previous_changes })
```

## Dependencies

- pave-core
- pave-tenancy

## Testing

Tests use `DemoScheduling` as a dummy product context.

# pave-identity — Users, Sessions, Roles

## Purpose

Provides user identity, session management, role-based access, and impersonation.

## Public API

```ruby
Pave::Identity.current_user          # Current authenticated user
Pave::Identity.current_actor         # Current acting user (or impersonator)
Pave::Identity.current_impersonator  # Original user during impersonation
Pave::Identity::User                 # User model
Pave::Identity::Impersonation.start!(admin, target)
Pave::Identity::Impersonation.stop!
Pave::Identity::Impersonation.denied!
Pave::Identity::Impersonation.authorized?
```

## Dependencies

- pave-core
- pave-tenancy
- pave-audit

## Testing

Tests are in `test/` and run via `bundle exec rake test`.

# Pavê Runtime — Repository Context

## Identity

This repository is the **Pavê runtime source monorepo**.

It produces Pavê gems and runtime tooling.
It is **not** a Pavê host app.
It does **not** contain product-specific application code.

## Repository Map

```
pave/
  gems/               — Pavê runtime gems (10 packages)
    pave/             — Meta-gem, CLI entrypoint
    pave-core/        — Pure Ruby runtime contracts
    pave-rails/       — Rails integration, generators
    pave-tenancy/     — Tenant model, request lifecycle
    pave-identity/    — Users, sessions, roles
    pave-billing/     — Provider-neutral billing primitives
    pave-audit/       — Immutable audit event log
    pave-backoffice/  — Super-admin UI chrome
    pave-hotwire/     — Hotwire helpers (planned)
    pave-agent/       — Agent context (planned)
  bin/pave            — CLI entrypoint
  products/           — Dummy products only (never real apps)
  plugins/            — Optional plugin gems
  test/               — Minitest test suite
    dummy/            — Dummy host app for engine tests
      products/
        demo_scheduling/ — Neutral dummy test product
```

## Package Responsibilities

| Gem | Owns |
|---|---|
| pave | Meta-gem, CLI, depends on default gems |
| pave-core | Registry, errors, Service, Result, Configuration, Current, Plugin |
| pave-rails | Railtie, Engine, generators, product boot |
| pave-tenancy | Space, SpaceMembership, request lifecycle |
| pave-identity | User, session, roles, impersonation |
| pave-billing | Plan, Subscription, BillingEvent, PlanEnforcer |
| pave-audit | AuditEvent, immutable event log |
| pave-backoffice | Panel registration, navigation, admin UI chrome |
| pave-hotwire | (planned) Hotwire-native helpers |
| pave-agent | (planned) Agent context generation |

## Testing

```bash
bundle exec rake test      # Run all tests
bundle exec rubocop        # Lint
bundle exec packwerk check # Boundary enforcement
bin/pave doctor            # Runtime health checks
```

Test fixtures use **DemoScheduling** as a neutral dummy product.

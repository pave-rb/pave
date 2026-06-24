# R1 — pave-core Implementation Plan

## 1. Purpose

Define the smallest stable runtime core APIs that all later Pavê packages, products, and plugins can depend on without loading Anella.

## 2. Preconditions

- R0 is complete and committed.
- Runtime packages load through the chosen R0 mechanism.
- `bin/pave doctor`, `bundle exec rails zeitwerk:check`, and tests are green.
- `pave-core` has no Pavê runtime package dependencies.

## 3. Non-goals

- Do not move Anella, tenancy, audit, identity, billing, or backoffice behavior.
- Do not add database tables or migrations.
- Do not add UI or routes.
- Do not implement install/uninstall hooks, billing hooks, backoffice panels, or plugin route mounting.
- Do not make `pave-core` depend on Rails app constants such as `User`, `Space`, or Devise.

## 4. Repo observations

- Existing `lib/pave.rb` defines `Pave.configure`, product registration, tenant chrome/settings hooks, redirect hooks, and `Pave.backoffice`.
- Existing `lib/pave/product_registry.rb` and `lib/pave/backoffice_registry.rb` are generic metadata registries but live in root `lib/`.
- `config/application.rb`, `config/products.rb`, and `config/routes.rb` already depend on `Pave` during boot.
- Current `Current` is `app/models/current.rb` with only `space` and `subscription`; R1 must introduce `Pave::Current` without taking over tenancy yet.

## 5. Planned changes

### Runtime/package structure

- Implement core files under `runtime/pave-core/lib/pave/core/`.
- Provide `runtime/pave-core/lib/pave/core.rb` as the package require.
- Keep or convert root `lib/pave.rb` into a compatibility shim that requires `pave/core` and preserves current product boot APIs until later phases move them fully.

### Rails integration

- Define `Pave::Core::Engine` only for load integration; do not add routes or migrations.
- Ensure `Pave::Current` loads without requiring app models.
- Keep existing product boot order working for `config/products.rb`.

### Services/commands

- Implement `Pave.configure`, `Pave.config`, and `Pave::Configuration` with explicit roots for runtime, products, and plugins.
- Implement `Pave::Current` as `ActiveSupport::CurrentAttributes` with `user`, `actor`, `space`, `request_id`, and `impersonator` only.
- Implement `Pave::Service`, `Pave::Result`, and the specified `Pave::Error` hierarchy.
- Implement `Pave::Registry` for metadata only: plugins, capabilities, and events.
- Implement `Pave::Plugin` DSL skeleton: `plugin_name`, `depends_on`, `capability`, `event`, and `register`.
- Optionally update `bin/pave doctor` to report core API availability.

### Tests

- Add focused Minitest coverage inside `runtime/pave-core/test` or the repo's chosen R0 test location.
- Cover configuration, current attribute reset, service call/result behavior, error code/context, registry validation/duplicates, and plugin DSL metadata.

### Documentation/agent context

- Document public core APIs in `runtime/pave-core/README.md` with short examples only.

## 6. Public contracts introduced or changed

- `Pave.configure`.
- `Pave.config`.
- `Pave::Configuration`.
- `Pave::Current`.
- `Pave::Service`.
- `Pave::Result`.
- `Pave::Error`, `Pave::ConfigurationError`, `Pave::RegistryError`, `Pave::ValidationError`, `Pave::AuthorizationError`, `Pave::NotFoundError`, `Pave::ConflictError`, `Pave::DependencyError`, `Pave::TenantScopeError`, and `Pave::IntegrationError`.
- `Pave::Registry`.
- `Pave::Plugin` DSL skeleton.
- Existing `Pave.products` and `Pave.backoffice` remain available through compatibility until R6 finalizes ownership.

## 7. Migration strategy

R1 is additive with a small compatibility move if safe.

- Source location: existing root `lib/pave.rb` and `lib/pave/*` for namespace compatibility only.
- Target location: `runtime/pave-core/lib/pave/core*`.
- Compatibility shim: root `lib/pave.rb` must continue to satisfy current boot code and route drawing.
- Deletion timing: do not delete root shims until R6/R7 confirms all imports use runtime public APIs.

## 8. Anti-contamination checks

- `pave-core` must not reference `Anella`, `Appointment`, `Customer`, `Whatsapp`, `WhatsApp`, `Asaas`, `booking`, `clinic`, `salon`, `Space`, `User`, Devise, or product route helpers.
- Registry entries are metadata only and must not dynamically constantize application classes on request paths.
- `Pave::Current.space` is only a slot in R1; no tenancy behavior belongs here.
- Plugin DSL must not include WhatsApp, billing, backoffice, install hooks, or route mounting.

## 9. Validation commands

```bash
git status --short
bundle exec rails zeitwerk:check
bin/pave doctor
bin/rails test test products/anella/test
bundle exec packwerk check
grep -R "Anella\|Appointment\|Whatsapp\|WhatsApp\|Asaas\|booking\|clinic\|salon" runtime/pave-core || true
```

## 10. Commit plan

```txt
1. R1: add pave-core configuration and current context
2. R1: add core service result and error contracts
3. R1: add registry and plugin DSL skeleton
4. R1: cover pave-core contracts with tests
```

## 11. Handoff criteria

- `pave-core` loads without loading Anella.
- Public API list is documented and tested.
- Existing `Pave` product boot still works.
- No migrations or UI were added.
- Validation commands are green and contamination search has no unapproved hits.

# Pavê Runtime Roadmap Specifications

These specs convert the post-Phase-12 Pavê roadmap into agent-ready implementation inputs. Each phase remains a separate gate. Do not merge phases during implementation.

---

# Pavê Runtime Roadmap — Agent Operating Contract

## Purpose

These specs are implementation inputs for a local coding agent. They are not implementation plans yet. Before coding each phase, the agent must inspect the repository, identify the existing structure, and produce a short phase-specific implementation plan grounded in the current codebase.

## Current state assumption

Anella product extraction Phase 12 has completed.

Before starting R0, the agent must verify:

```bash
git status --short
bundle exec rails zeitwerk:check
bundle exec packwerk check
bin/pave doctor
bin/rails test
```

If the project uses RSpec instead of, or in addition to, Rails test, run the existing test command used by CI. If one of these commands is not present yet, explain why and use the nearest existing equivalent. Do not silently skip checks.

## Hard sequencing rule

Do not start the next phase until the current phase boots cleanly and the validation suite is green.

The critical gate is R0:

> R0 proves that the runtime scaffold can hold Anella. R1 must not start until R0 boots cleanly and CI is green.

## Dependency graph

```text
pave-core       <- no Pavê runtime deps
  ↑
pave-tenancy    <- pave-core
  ↑
pave-audit      <- pave-core + pave-tenancy
  ↑
pave-identity   <- pave-core + pave-tenancy + pave-audit
pave-billing    <- pave-core + pave-tenancy + pave-audit
  ↑
pave-backoffice <- pave-core + tenancy + audit + identity + billing
  ↑
Packwerk ON     <- zero violations, CI enforced
```

R3 intentionally precedes R4 and R5 because impersonation and billing transitions must write to a stable audit interface.

## Anti-contamination rule

Runtime packages may only contain generic runtime concepts.

Do not let Anella domain concerns leak into runtime models, controllers, services, commands, routes, views, migrations, docs, or naming.

Examples:

- `Space` must not grow `booking_page_slug`, appointment defaults, CRM fields, WhatsApp settings, or calendar-specific preferences.
- `User` must not grow Anella-specific profile or professional fields.
- `pave-billing` must not know Asaas, Brazilian invoice details, Anella pricing copy, WhatsApp template semantics, or salon/clinic packages.
- `pave-backoffice` must own shell, chrome, navigation contracts, and panel registration only; module panel content belongs to the module or product.

When a moved object has mixed generic and Anella-specific fields, split it:

```text
Pave runtime model     -> generic identity/tenancy/billing/audit fields
Anella profile model   -> product-specific fields, preferences, and behavior
```

## Runtime package format

Use engine-shaped internal path gems under `runtime/` so the structure can later become distributed gems without another rewrite.

Preferred shape:

```text
runtime/
  pave-core/
    pave-core.gemspec
    lib/pave/core.rb
    lib/pave/core/engine.rb
    app/
    config/
    package.yml
  pave-tenancy/
  pave-audit/
  pave-identity/
  pave-billing/
  pave-backoffice/
products/
  anella/
plugins/
bin/pave
```

Use Ruby namespace `Pave`, not `Pavê`, in code.

Use gem/package names with hyphens, for example `pave-core`, while mapping Ruby requires to `pave/core`.

## Public API policy

Every runtime package must have a small public surface. Cross-package calls should go through public APIs, not concrete internals.

Public examples:

- `Pave.configure`
- `Pave.config`
- `Pave::Current`
- `Pave::Registry`
- `Pave::Audit.log`
- `Pave::Tenancy.with_space`
- `Pave::Billing.enforce!`
- `Pave::Backoffice.register_panel`

Private examples:

- Internal Active Record implementation details.
- Adapter normalization classes.
- Controller concerns not declared as extension points.
- View partial internals.

## Commit policy

Work in small checkpoints. At minimum, each phase must end with one commit whose message starts with the phase number.

Examples:

```text
R0: scaffold runtime packages
R1: add pave-core primitives
R3: extract generic audit runtime
```

If the local workflow is direct-to-main, commit locally to `main`. If the repository has shifted to branch-based work, create a phase branch. Do not mix multiple runtime phases in one commit.

## Required phase handoff

At the end of each phase, write a concise handoff note in the commit body or a phase summary file:

```text
Completed:
- ...

Moved:
- ...

Added:
- ...

Deferred:
- ...

Validation:
- command -> result

Contamination checks:
- ...

Known follow-up:
- ...
```

## Non-negotiables

- Do not introduce speculative features.
- Do not publish gems.
- Do not build marketplace behavior.
- Do not rewrite Rails conventions.
- Do not generate full UI pages from declarations yet.
- Do not make the runtime depend on Anella.
- Do not make Anella tests pass by weakening runtime boundaries.
- Do not use `Current.space` implicitly in jobs; jobs must receive explicit IDs and resolve context intentionally.

---

# R0 — Monorepo Scaffold Specification

## Intent

Create the runtime scaffold that can hold Pavê without changing Anella behavior.

R0 proves the host application can boot with runtime packages present. It does not extract business logic yet.

## Preconditions

- Anella extraction Phase 12 is complete.
- Current app boots.
- CI is green or local equivalent checks are green.
- Working tree is clean.

## Outcome

The repository has a `runtime/` directory with internal path-gem / engine-shaped packages, a minimal `bin/pave` command, updated CI checks, and no visible behavior change in Anella.

## Scope

Create:

```text
runtime/
  pave-core/
  pave-tenancy/
  pave-audit/
  pave-identity/
  pave-billing/
  pave-backoffice/
plugins/
```

Each `runtime/pave-*` package should include:

```text
<pkg>.gemspec
lib/pave/<name>.rb
lib/pave/<name>/version.rb
lib/pave/<name>/engine.rb
package.yml
README.md
```

Add path gem entries to the root `Gemfile` only if they can load safely in development, test, and CI.

Add package declarations for Packwerk without enabling strict dependency/privacy enforcement yet unless already supported by the current repository.

Create or preserve:

```text
bin/pave
```

`bin/pave` must expose command names now, even if most commands are not fully implemented yet.

Required R0 commands:

```bash
bin/pave help
bin/pave doctor
bin/pave version
```

`bin/pave doctor` must be minimally implemented. It should verify:

- runtime directory exists
- expected runtime packages exist
- runtime packages can be loaded
- Rails environment can boot
- Packwerk command is available if configured

Checks that belong to later phases must be reported as `skipped`, not as failures.

## Non-goals

- Do not move `Space`, `User`, billing, audit, or backoffice code.
- Do not introduce `Pave::Service` yet unless required for CLI internals; R1 owns that abstraction.
- Do not change Anella routes, views, controllers, models, or migrations except for mechanical load-path wiring.
- Do not publish gems.
- Do not convert products/plugins into Rails engines.

## Design constraints

Runtime packages are internal but should be shaped as future distributable gems.

Use this dependency direction only:

```text
host app -> runtime packages -> no Anella dependency
products/anella -> runtime packages
runtime packages -/-> products/anella
```

R0 should be additive. If deleting or moving application files is necessary, stop and produce a revised plan.

## Expected files touched

Likely files:

```text
Gemfile
bin/pave
config/application.rb
packwerk.yml
runtime/*
.github/workflows/* or existing CI config
docs/runtime/R0_MONOREPO_SCAFFOLD.md
```

Do not assume GitHub Actions. Inspect the existing CI mechanism first.

## CI integration

CI should run, or be prepared to run:

```bash
bundle exec rails zeitwerk:check
bundle exec packwerk check
bin/pave doctor
bin/rails test
```

Use the repository's existing test command if different.

## Acceptance criteria

- `bundle install` succeeds.
- `bundle exec rails zeitwerk:check` succeeds.
- `bin/pave help` succeeds.
- `bin/pave doctor` succeeds with only explicitly marked skipped checks for later phases.
- Test suite remains green.
- Packwerk check remains green or unchanged from pre-R0 baseline.
- No Anella behavior changes.
- No product-specific code appears under `runtime/`.

## Handoff note

The R0 handoff must explicitly state:

- whether runtime packages are loaded through Gemfile path gems or application autoload paths
- whether any CI file changed
- which `bin/pave doctor` checks are active vs skipped
- whether Packwerk is advisory or enforcing at this stage

---

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

---

# R2 — pave-tenancy Specification

## Intent

Extract generic tenancy primitives into `pave-tenancy` while keeping Anella-specific space/profile concerns in Anella.

This is the first move-based runtime extraction phase.

## Dependencies

- R0 complete.
- R1 complete.
- `pave-core` public APIs stable.

`pave-tenancy` depends on `pave-core` only.

## Outcome

Generic space and membership concepts live in `pave-tenancy`. Products can resolve and scope tenant-owned data through a stable runtime interface.

## Scope

Move or create generic equivalents for:

```text
Pave::Tenancy::Space
Pave::Tenancy::SpaceMembership
Pave::Tenancy::BaseController
Pave::Tenancy.with_space
Pave::Tenancy.current_space
Pave::Tenancy.space_required!
Pave::Current.space wiring
```

The roadmap names `Space` and `SpaceMembership`. Prefer canonical runtime classes under `Pave::Tenancy::*`. If existing application code requires top-level `Space` / `SpaceMembership` during migration, provide temporary compatibility aliases and mark them as transitional.

## Data model contract

`Space` may include only generic tenancy fields.

Allowed examples:

```text
id
name
slug
status
created_at
updated_at
```

`SpaceMembership` may include only generic membership fields.

Allowed examples:

```text
id
space_id
user_id
role
status
created_at
updated_at
```

Use existing tables when possible to avoid destructive migrations. If table names are currently generic (`spaces`, `space_memberships`), keep them. If names are product-specific, introduce compatibility carefully and preserve data.

## Required split

Before moving `Space`, audit all current `spaces` columns and methods.

Move Anella-specific fields and methods into:

```text
products/anella/app/models/anella/space_profile.rb
```

or an equivalent existing Anella namespace.

Examples of fields/methods that must not stay in runtime `Space`:

- booking page slug or public booking configuration
- appointment defaults
- WhatsApp settings
- clinic/salon/business vertical fields
- Anella onboarding state
- CRM preferences
- notification copy or templates

The runtime can expose a generic extension association if needed:

```ruby
has_one :profile, class_name: "Anella::SpaceProfile"
```

But prefer defining product associations from the product side when possible, so runtime does not reference Anella constants.

## Controller contract

`Pave::Tenancy::BaseController` may provide:

- current space lookup hook
- `require_space!`
- assignment to `Pave::Current.space`
- tenant mismatch guard

It must not assume Devise or a specific authentication package yet. R4 owns identity.

Use overridable methods:

```ruby
def resolve_current_space
  # host/product override
end

def current_actor
  Pave::Current.actor || Pave::Current.user
end
```

## Tenant scoping contract

Provide an explicit API:

```ruby
Pave::Tenancy.with_space(space) { ... }
Pave::Tenancy.current_space
Pave::Tenancy.space_required!
Pave::Tenancy.assert_same_space!(record, space)
```

Do not make background jobs depend on implicit `Current.space`. Jobs must pass explicit IDs and establish context inside `perform` when required.

## Non-goals

- Do not implement identity extraction.
- Do not implement billing plans per space.
- Do not implement audit events beyond any generic tenant lifecycle events absolutely required.
- Do not implement product-specific profiles inside runtime.
- Do not introduce organization/team complexity beyond what current app already needs.

## Expected files touched

Likely files:

```text
runtime/pave-tenancy/app/models/pave/tenancy/space.rb
runtime/pave-tenancy/app/models/pave/tenancy/space_membership.rb
runtime/pave-tenancy/app/controllers/pave/tenancy/base_controller.rb
runtime/pave-tenancy/lib/pave/tenancy.rb
runtime/pave-tenancy/lib/pave/tenancy/*
products/anella/app/models/anella/space_profile.rb
products/anella/db/migrate/*create_or_backfill_space_profiles*.rb
app/models/space.rb                         # compatibility shim only if required
app/models/space_membership.rb              # compatibility shim only if required
```

## Tests

Add or preserve tests for:

- current space assignment
- tenant mismatch protection
- membership lookup
- compatibility aliases, if added
- Anella profile split
- no loss of existing Anella behavior
- no product-specific columns expected by runtime model

## Data migration safety

If profile split requires migration:

1. Create Anella profile table.
2. Backfill from existing `spaces` columns.
3. Update code to read from profile.
4. Keep old columns temporarily only if needed for safe deploy.
5. Drop old product-specific columns only in a later cleanup after validation.

Do not drop data in the same phase unless the field is proven unused and covered by tests.

## Acceptance criteria

- Runtime owns generic space/membership behavior.
- Anella-specific space concerns live under `products/anella`.
- `Pave::Current.space` is wired through tenancy.
- Existing Anella tenant flows still work.
- Tests remain green.
- No runtime file references `Anella::SpaceProfile` directly unless explicitly isolated in a compatibility adapter outside the runtime package.

## Contamination checks

Run:

```bash
grep -R "booking_page\|appointment\|whatsapp\|clinic\|salon\|Anella" runtime/pave-tenancy || true
```

Expected result: no product-domain hits.

## Handoff note

The R2 handoff must include:

- list of moved tenancy files
- list of fields left on runtime `Space`
- list of fields moved to Anella profile
- compatibility shims added, if any
- migration/backfill status
- tenant safety tests added

---

# R3 — pave-audit Specification

## Intent

Extract a generic audit trail module before identity and billing so impersonation and billing state transitions can write to a stable runtime audit interface.

## Dependencies

- R0 complete.
- R1 complete.
- R2 complete.

`pave-audit` depends on:

```text
pave-core
pave-tenancy
```

## Outcome

Runtime has a generic `AuditEvent` model and a stable `Pave::Audit.log` API.

## Scope

Implement:

```text
Pave::Audit
Pave::Audit::AuditEvent
Pave::Audit.log
Pave::Audit.log!
Pave::Audit::EventBuilder or equivalent small internal object
```

## Public API

Expected use:

```ruby
Pave::Audit.log(
  key: "identity.impersonation.started",
  actor: current_user,
  target: target_user,
  space: Pave::Current.space,
  metadata: { reason: "support" },
  idempotency_key: request.uuid
)
```

`log` should return a result object or audit event without raising for validation failures if that matches current service conventions.

`log!` should raise `Pave::ValidationError` or a domain-specific audit error on failure.

## Data model contract

`AuditEvent` should store generic references only.

Suggested columns:

```text
id
space_id
key
actor_type
actor_id
actor_label
target_type
target_id
target_label
metadata json/jsonb
request_id
idempotency_key
source
occurred_at
created_at
updated_at
```

Indexes:

```text
space_id, occurred_at
key, occurred_at
actor_type, actor_id, occurred_at
target_type, target_id, occurred_at
idempotency_key unique where present, if supported
```

Do not store Anella-specific fields.

## Event naming

Use namespaced event keys:

```text
tenancy.space.created
identity.impersonation.started
billing.subscription.changed
billing.credit.debited
```

Do not use human copy as event keys.

## Metadata rules

`metadata` must be JSON-serializable and safe.

Do not store:

- raw access tokens
- webhook secrets
- full payment payloads unless redacted
- full message bodies unless explicitly required by a product module
- personally unnecessary sensitive fields

## Controller/job usage

Audit logging must accept explicit `actor`, `target`, and `space`. It may default from `Pave::Current`, but the public API should not require implicit context.

Background jobs must pass explicit IDs or prebuilt safe metadata.

## Non-goals

- Do not build audit UI yet. R6 owns shell; module panels later own content.
- Do not implement event bus or notifications.
- Do not make audit a replacement for application logs.
- Do not add billing or identity behavior.
- Do not add product-specific event schemas.

## Expected files touched

```text
runtime/pave-audit/app/models/pave/audit/audit_event.rb
runtime/pave-audit/db/migrate/*create_pave_audit_events*.rb
runtime/pave-audit/lib/pave/audit.rb
runtime/pave-audit/lib/pave/audit/*
runtime/pave-audit/package.yml
```

If there is an existing audit model in Anella, move only generic behavior and leave product-specific presentation/content under Anella.

## Tests

Add tests for:

- successful generic audit write
- system actor logging
- nil space behavior if platform-level event is allowed
- idempotency behavior
- metadata serialization
- no Anella dependencies
- audit events scoped by space

## Acceptance criteria

- `Pave::Audit.log` works from app code.
- Audit event table exists and is indexed.
- No Anella-specific fields or constants in `pave-audit`.
- R4 and R5 can depend on audit without defining their own audit interfaces.
- Existing test suite remains green.

## Contamination checks

Run:

```bash
grep -R "Anella\|Appointment\|Whatsapp\|Asaas\|booking\|clinic\|salon" runtime/pave-audit || true
```

Expected result: no product-domain hits.

## Handoff note

The R3 handoff must include:

- final audit event schema
- public audit API examples
- redaction/idempotency behavior
- tests added
- known future UI hooks for R6/modules

---

# R4 — pave-identity Specification

## Intent

Extract generic identity, session, role resolution, and impersonation primitives into `pave-identity`, using `pave-audit` for security-relevant events.

## Dependencies

- R0 complete.
- R1 complete.
- R2 complete.
- R3 complete.

`pave-identity` depends on:

```text
pave-core
pave-tenancy
pave-audit
```

## Outcome

Runtime owns generic user/session/impersonation behavior. Products own profile fields and product-specific roles or capabilities.

## Scope

Move or create generic equivalents for:

```text
Pave::Identity::User
Pave::Identity::Session or session abstraction
Pave::Identity::Impersonation
Pave::Identity::ImpersonationsController
Pave::Identity.current_user / current_actor helpers
Role resolution through Pave::Tenancy::SpaceMembership
```

If current auth is Devise-based, preserve behavior. Do not rewrite authentication unless the current implementation already requires it.

## User model contract

Runtime `User` may include only generic identity fields.

Allowed examples:

```text
id
email
name
status
time_zone
locale
admin/platform_admin flag only if already generic
created_at
updated_at
```

Product-specific user fields must move to:

```text
products/anella/app/models/anella/user_profile.rb
```

or equivalent existing Anella namespace.

Examples that must not live in runtime `User`:

- professional biography
- booking display name
- service provider settings
- WhatsApp signature
- appointment color preferences
- clinic/salon role details
- Anella onboarding preferences

## Role/capability contract

Role resolution should flow through memberships:

```ruby
membership = Pave::Tenancy::SpaceMembership.find_by(user:, space:)
membership.role
```

Do not hard-code Anella roles in runtime.

Allowed generic roles only if already present and truly cross-product:

```text
owner
admin
member
```

Prefer capabilities for runtime checks:

```text
platform.manage
spaces.manage
identity.impersonate
billing.manage
backoffice.access
```

## Impersonation contract

Implement impersonation as a generic security feature.

Required behavior:

- start impersonation only from authorized platform actor
- store original actor separately from impersonated user
- expose `Pave::Current.impersonator`
- expose `Pave::Current.actor` as effective actor if needed
- stop impersonation and restore original actor
- write audit events through `Pave::Audit.log!`

Audit keys:

```text
identity.impersonation.started
identity.impersonation.stopped
identity.impersonation.denied
```

Do not make impersonation depend on Anella support flows or copy.

## Session contract

If the current app uses Devise or Rails auth generator, keep integration minimal:

- runtime may own generic current-user helpers
- runtime should not force a new auth stack
- runtime should not break existing login/logout/password flows

R4 is extraction, not auth product redesign.

## Non-goals

- Do not build full RBAC/ABAC DSL yet.
- Do not build identity provider integrations.
- Do not build user management UI beyond what already exists generically.
- Do not move Anella user profile fields into runtime.
- Do not define product-specific roles.

## Expected files touched

```text
runtime/pave-identity/app/models/pave/identity/user.rb
runtime/pave-identity/app/models/pave/identity/impersonation.rb       # if persistence needed
runtime/pave-identity/app/controllers/pave/identity/impersonations_controller.rb
runtime/pave-identity/lib/pave/identity.rb
runtime/pave-identity/lib/pave/identity/*
products/anella/app/models/anella/user_profile.rb
app/models/user.rb                                                    # compatibility shim only if required
```

## Tests

Add tests for:

- current user/current actor wiring
- role lookup through memberships
- impersonation start success
- impersonation stop success
- unauthorized impersonation denied
- audit events written for impersonation
- user profile split
- no Anella constants in runtime identity

## Acceptance criteria

- Existing login/session behavior still works.
- Generic user behavior lives in runtime.
- Anella profile behavior lives in product code.
- Impersonation writes to audit.
- R5 can use identity actor context for billing audit events.
- Tests and Packwerk remain green.

## Contamination checks

Run:

```bash
grep -R "Anella\|Appointment\|booking\|professional\|Whatsapp\|clinic\|salon" runtime/pave-identity || true
```

Expected result: no product-domain hits except generic words that are justified in comments/tests.

## Handoff note

The R4 handoff must include:

- final user field split
- auth integration approach retained
- impersonation audit proof
- compatibility aliases/shims added, if any
- tests added

---

# R5 — pave-billing Specification

## Intent

Extract generic billing primitives into `pave-billing` without coupling the runtime to Anella pricing, Asaas, WhatsApp, Brazilian tax specifics, or any single payment provider.

## Dependencies

- R0 complete.
- R1 complete.
- R2 complete.
- R3 complete.

`pave-billing` depends on:

```text
pave-core
pave-tenancy
pave-audit
```

It may read identity actor context through `Pave::Current`, but should avoid hard dependency on identity internals unless required.

## Outcome

Runtime owns generic plan, subscription, billing event, entitlement, usage-credit, adapter, and webhook contracts. Anella owns provider adapters and product-specific plan definitions.

## Scope

Implement or move generic equivalents for:

```text
Pave::Billing::Plan
Pave::Billing::Subscription
Pave::Billing::BillingEvent
Pave::Billing::PlanEnforcer
Pave::Billing::ProviderAdapter
Pave::Billing::WebhookHandler
Pave::Billing::CreditLedger or UsageCredit
```

The roadmap names `MessageCredit`. Treat this carefully: runtime may support a generic credit ledger with a meter key such as `messages`. Do not encode WhatsApp semantics in `pave-billing`.

Preferred naming:

```text
Pave::Billing::UsageCredit
Pave::Billing::CreditLedger
Pave::Billing::CreditTransaction
```

Only expose `MessageCredit` as a compatibility facade if current Anella code requires it. If added, it must mean generic billable message credits, not WhatsApp template credits.

## Plan contract

A plan is a generic product entitlement bundle.

Allowed fields/examples:

```text
id
key
name
status
price_cents
currency
interval
metadata json/jsonb
created_at
updated_at
```

Do not put Anella marketing copy or vertical-specific plan descriptions into runtime records unless stored as generic metadata owned by product seed data.

## Subscription contract

A subscription connects a tenant to a plan and provider state.

Suggested fields:

```text
id
space_id
plan_id
status
provider
provider_customer_id
provider_subscription_id
current_period_start
current_period_end
trial_ends_at
cancel_at
canceled_at
metadata json/jsonb
created_at
updated_at
```

Allowed generic statuses:

```text
trialing
active
past_due
paused
canceled
expired
```

## Billing event contract

`BillingEvent` stores normalized provider/runtime events, not raw provider payloads as primary behavior.

Suggested fields:

```text
id
space_id
subscription_id
provider
provider_event_id
event_key
status
payload_digest
metadata json/jsonb
occurred_at
processed_at
created_at
updated_at
```

Raw payload storage must be redacted or isolated if kept.

Billing state transitions must write audit events through `Pave::Audit`.

Audit keys:

```text
billing.subscription.created
billing.subscription.changed
billing.subscription.canceled
billing.plan.enforced
billing.credit.granted
billing.credit.debited
billing.webhook.processed
billing.webhook.rejected
```

## Provider adapter interface

Define an abstract adapter contract:

```ruby
class Pave::Billing::ProviderAdapter
  def create_checkout(space:, plan:, success_url:, cancel_url:); end
  def cancel_subscription(subscription:); end
  def sync_subscription(subscription:); end
  def verify_webhook!(request:); end
  def parse_webhook(request:); end
end
```

`pave-billing` may include a fake/null adapter for tests.

Do not implement Asaas inside runtime.

Anella provider adapters must live under:

```text
products/anella/app/services/anella/billing/asaas_adapter.rb
```

or equivalent product namespace.

## Plan enforcement contract

Provide:

```ruby
Pave::Billing.enforce!(space:, capability:, actor: nil, metadata: {})
Pave::Billing.allowed?(space:, capability:)
```

This should check plan entitlements without knowing product domain behavior.

Capabilities are string/symbol keys, for example:

```text
appointments.manage
messages.send
backoffice.access
```

The meaning of a product capability belongs to the product/module.

## Usage credit contract

Runtime should support generic credit debits:

```ruby
Pave::Billing.debit_credit!(space:, meter: "messages", amount: 1, source: "whatsapp.outbound_message", idempotency_key: ...)
```

Rules:

- use idempotency keys for external events
- write audit events for grants/debits
- never let credits go negative unless plan explicitly allows overdraft
- do not know WhatsApp template categories or phone numbers

## Non-goals

- Do not implement Asaas adapter in runtime.
- Do not implement Stripe/Asaas full checkout unless already present and generic.
- Do not implement invoices/NFe in runtime.
- Do not implement Anella pricing tiers in runtime code.
- Do not implement WhatsApp-specific billing in runtime.
- Do not build billing UI beyond generic surfaces needed for R6 registration.

## Expected files touched

```text
runtime/pave-billing/app/models/pave/billing/plan.rb
runtime/pave-billing/app/models/pave/billing/subscription.rb
runtime/pave-billing/app/models/pave/billing/billing_event.rb
runtime/pave-billing/app/models/pave/billing/credit_transaction.rb
runtime/pave-billing/lib/pave/billing.rb
runtime/pave-billing/lib/pave/billing/*
products/anella/app/services/anella/billing/asaas_adapter.rb
products/anella/config/billing_plans.yml or equivalent product-owned plan seed
```

## Tests

Add tests for:

- plan lookup
- subscription state transition
- plan enforcement allowed/denied
- billing audit event writes
- generic credit grant/debit
- idempotent credit debit
- provider adapter abstract contract
- webhook handler normalization
- no Asaas reference in runtime

## Acceptance criteria

- Billing state transitions write audit events.
- Anella can still enforce billing gates.
- Provider-specific adapter lives in Anella.
- Runtime billing does not mention Asaas, WhatsApp, salons, clinics, appointments, or Anella pricing.
- Tests and Packwerk remain green.

## Contamination checks

Run:

```bash
grep -R "Asaas\|Whatsapp\|WhatsApp\|Anella\|Appointment\|clinic\|salon\|booking" runtime/pave-billing || true
```

Expected result: no product/provider hits.

## Handoff note

The R5 handoff must include:

- billing public API
- provider adapter interface
- where Anella provider code now lives
- plan/entitlement storage strategy
- credit ledger naming decision
- audit events emitted
- tests added

---

# R6 — pave-backoffice Specification

## Intent

Extract the generic backoffice shell into `pave-backoffice` while leaving all product/module panel content in the product or module that owns it.

## Dependencies

- R0 complete.
- R1 complete.
- R2 complete.
- R3 complete.
- R4 complete.
- R5 complete.

`pave-backoffice` depends on:

```text
pave-core
pave-tenancy
pave-audit
pave-identity
pave-billing
```

## Outcome

Runtime owns platform backoffice chrome, base controller, navigation contract, breadcrumb contract, panel registration, and layout surfaces.

Products/modules register panels. Runtime does not own their content.

## Scope

Implement or move generic equivalents for:

```text
Pave::Backoffice
Pave::Backoffice::BaseController
Pave::Backoffice::Panel
Pave::Backoffice::Navigation
Pave::Backoffice::Breadcrumbs
Pave::Backoffice.register_panel
Pave::Backoffice.panels
Generic layout/chrome partials
```

Panel classes or metadata should define:

```text
key
title
namespace
route/helper
required_capability
position/group
icon optional
owner package/product/module
```

## Shell surfaces

Runtime may own shells for:

```text
Platform backoffice
Product backoffice
Module panel container
```

Runtime may render:

- outer layout
- sidebar/nav container
- breadcrumb container
- page heading slot
- panel slot
- empty/unauthorized state

Runtime must not render Anella-specific dashboards, appointment charts, WhatsApp data, customer lists, schedules, or billing copy.

## Controller contract

`Pave::Backoffice::BaseController` should provide:

- authentication hook
- authorization hook
- current space requirement where relevant
- layout selection
- breadcrumb helper
- panel lookup

Identity integration must use runtime identity/capability APIs, not Anella role checks.

Example hooks:

```ruby
def require_backoffice_access!
  # generic capability check
end

def current_backoffice_space
  Pave::Current.space
end
```

## Panel registration contract

Expected use from product/module code:

```ruby
Pave::Backoffice.register_panel(
  key: "anella.appointments",
  title: "Appointments",
  owner: "products/anella",
  route: :anella_backoffice_appointments_path,
  capability: "appointments.manage",
  group: "Operations"
)
```

R6 should validate metadata but not invoke route helpers at boot if that creates load-order problems. Store route references safely.

## Non-goals

- Do not build a full admin framework.
- Do not implement CRUD generation.
- Do not move Anella panel content into runtime.
- Do not implement Avo-like resource screens.
- Do not build public marketplace/module browser.
- Do not implement Hotwire UI derivation from resources yet.

## Expected files touched

```text
runtime/pave-backoffice/app/controllers/pave/backoffice/base_controller.rb
runtime/pave-backoffice/app/controllers/pave/backoffice/*
runtime/pave-backoffice/app/views/layouts/pave/backoffice.html.erb
runtime/pave-backoffice/app/views/pave/backoffice/shared/*
runtime/pave-backoffice/lib/pave/backoffice.rb
runtime/pave-backoffice/lib/pave/backoffice/*
products/anella/app/controllers/anella/backoffice/*
products/anella/app/views/anella/backoffice/*
```

## Tests

Add tests for:

- panel registration validation
- duplicate panel keys rejected
- panel ordering/grouping
- unauthorized access denied
- breadcrumb rendering contract
- Anella panel remains product-owned
- runtime shell renders without product content

## Acceptance criteria

- Backoffice shell loads from runtime.
- Anella panels register into shell from Anella code.
- Runtime backoffice does not reference Anella constants.
- Existing backoffice user flows still work.
- Tests and Packwerk remain green.

## Contamination checks

Run:

```bash
grep -R "Anella\|Appointment\|Whatsapp\|Asaas\|booking\|clinic\|salon\|customer" runtime/pave-backoffice || true
```

Expected result: no product-domain hits except generic fixture strings if explicitly justified.

## Handoff note

The R6 handoff must include:

- final shell/panel API
- list of Anella panels and where they register
- authorization model used
- views/layouts moved
- tests added

---

# R7 — Packwerk Enforcement ON Specification

## Intent

Turn runtime package boundaries from advisory structure into enforced architecture.

R7 is the hardening phase. It should not add product behavior. It should close leaks.

## Dependencies

- R0 through R6 complete.
- All runtime modules boot.
- Anella behavior remains green.

## Outcome

All packages have explicit dependency and privacy rules. CI fails on new boundary violations.

## Scope

Update every relevant `package.yml` to enable:

```yaml
enforce_dependencies: true
enforce_privacy: true
```

Where supported by current Packwerk version and repo conventions.

Runtime packages must declare only allowed dependencies:

```yaml
runtime/pave-core:
  dependencies: []

runtime/pave-tenancy:
  dependencies:
    - runtime/pave-core

runtime/pave-audit:
  dependencies:
    - runtime/pave-core
    - runtime/pave-tenancy

runtime/pave-identity:
  dependencies:
    - runtime/pave-core
    - runtime/pave-tenancy
    - runtime/pave-audit

runtime/pave-billing:
  dependencies:
    - runtime/pave-core
    - runtime/pave-tenancy
    - runtime/pave-audit

runtime/pave-backoffice:
  dependencies:
    - runtime/pave-core
    - runtime/pave-tenancy
    - runtime/pave-audit
    - runtime/pave-identity
    - runtime/pave-billing

products/anella:
  dependencies:
    - runtime/pave-core
    - runtime/pave-tenancy
    - runtime/pave-audit
    - runtime/pave-identity
    - runtime/pave-billing
    - runtime/pave-backoffice
```

Adjust exact package names to match repository convention.

## Public API boundaries

Each runtime package should expose a deliberate public API.

If using Packwerk public folders, create and maintain them. If using another convention, document it.

Examples:

```text
runtime/pave-core/app/public/pave/current.rb
runtime/pave-audit/app/public/pave/audit.rb
runtime/pave-billing/app/public/pave/billing.rb
```

Do not expose entire models/controllers just to silence Packwerk.

## Violation handling

For each violation:

1. Decide whether the dependency direction is valid.
2. If valid, expose a public API or add an explicit dependency.
3. If invalid, invert the dependency or move code to the owning package.
4. If product-specific, move to Anella.
5. If truly temporary, document with a cleanup issue/comment and do not normalize the leak.

The violation list may become an Anella internal cleanup backlog, but CI must not allow new runtime violations.

## CI contract

CI must fail on:

```bash
bundle exec packwerk check
bin/pave doctor
bundle exec rails zeitwerk:check
bin/rails test
```

`bin/pave doctor` should gain boundary checks:

- runtime packages present
- dependency graph valid
- no forbidden reverse dependencies
- no forbidden product references inside runtime
- Packwerk configured/enforced

## Non-goals

- Do not refactor application behavior for aesthetics.
- Do not add new runtime features.
- Do not widen APIs just to make violations disappear.
- Do not disable tests or Packwerk checks.

## Tests/checks

Add or update checks for:

- no Anella constants under runtime packages
- no product dependencies from runtime packages
- dependency graph matches roadmap
- CI fails on Packwerk violation
- doctor reports boundary status

## Acceptance criteria

- Packwerk check is green.
- Dependency enforcement is on.
- Privacy enforcement is on.
- CI fails on violations.
- Runtime packages do not depend on Anella.
- Anella depends on runtime through public APIs.
- All tests green.

## Handoff note

The R7 handoff must include:

- final package dependency graph
- public API surfaces by package
- remaining cleanup backlog, if any
- proof CI enforces Packwerk
- final validation command output summary

---

# Later L1 — WhatsApp Plugin Specification

## Intent

Use WhatsApp as the first adversarial plugin to validate Pavê runtime contracts end-to-end before external adopters rely on them.

This plugin must exercise:

- plugin dependency declaration
- backoffice panel registration
- billing credit debit
- audit event emission
- webhook handling
- product/runtime boundary discipline

## Dependencies

- R0 through R7 complete.
- Runtime boundaries enforced.
- `Pave::Plugin` DSL stable enough to register metadata.
- `pave-backoffice`, `pave-billing`, and `pave-audit` available.

## Outcome

WhatsApp integration lives outside core runtime as a plugin. Runtime contracts prove sufficient without hard-coding WhatsApp into `pave-billing`, `pave-audit`, `pave-backoffice`, or Anella core.

## Proposed location

```text
plugins/pave-whatsapp/
```

or, if it remains private/product-bound first:

```text
products/anella/plugins/whatsapp/
```

Prefer `plugins/pave-whatsapp` if it can be generic. Keep Anella-specific copy/configuration in Anella.

## Required declarations

The plugin should declare:

```text
name: whatsapp
dependencies:
  - pave-core
  - pave-audit
  - pave-billing
  - pave-backoffice
capabilities:
  - whatsapp.manage
  - whatsapp.send_message
  - whatsapp.manage_templates
events emitted:
  - whatsapp.webhook.received
  - whatsapp.message.sent
  - whatsapp.message.failed
  - whatsapp.template.synced
billing meters:
  - messages
backoffice panels:
  - whatsapp.settings
  - whatsapp.templates
  - whatsapp.webhooks
```

## Runtime contract tests

The plugin should prove:

- a plugin can declare dependencies and fail boot if missing
- a plugin can register backoffice panels without runtime knowing the panel content
- a plugin can debit billing credits through generic meter keys
- a plugin can emit audit events without audit knowing WhatsApp schema
- webhook handling can be isolated behind plugin routes/controllers

## Anti-contamination rule

Do not move WhatsApp concepts into:

```text
runtime/pave-core
runtime/pave-billing
runtime/pave-audit
runtime/pave-backoffice
products/anella core models unless Anella-specific orchestration is required
```

Billing sees `meter: "messages"`, not WhatsApp.

Audit sees event keys and metadata, not provider-specific behavior.

Backoffice sees panel registration, not WhatsApp UI internals.

## Non-goals

- Do not make WhatsApp required for Anella to boot.
- Do not implement multi-provider messaging abstraction unless another provider exists.
- Do not turn this into a generic communications platform yet.
- Do not publish plugin externally before runtime contracts stabilize.

## Acceptance criteria

- Plugin can be enabled/disabled without breaking core runtime.
- Plugin declares dependencies.
- Plugin panels appear through `pave-backoffice` registration.
- Sending/delivery flows debit generic billing credits.
- Webhook flows write audit events.
- Runtime packages contain no WhatsApp references.
- Tests cover plugin registration, billing debit, audit emission, and panel registration.

---

# Later L2 — Full `bin/pave` CLI Specification

## Intent

Turn `bin/pave` from a scaffold/doctor command into the developer interface for inspecting and maintaining the runtime.

## Dependencies

- R0 through R7 complete.
- Runtime registry stable.
- Package boundaries enforced.

## Outcome

`bin/pave` can explain the runtime, validate architecture, generate bounded artifacts, and export agent context.

## Commands

Required commands:

```bash
bin/pave help
bin/pave version
bin/pave doctor
bin/pave context
bin/pave explain
bin/pave packages
bin/pave products
bin/pave plugins
bin/pave routes
bin/pave audit boundaries
bin/pave generate workflow <name>
```

Future commands:

```bash
bin/pave generate module <name>
bin/pave generate resource <name> --tenant-scoped
bin/pave generate backoffice-panel <name>
bin/pave deploy doctor
```

## Design rules

- CLI must load Rails only when required.
- Pure metadata commands should be fast.
- Output should support human-readable and machine-readable formats where useful.
- Do not mutate files unless command name implies generation.
- Every mutating command must print changed file list.

## Acceptance criteria

- `bin/pave doctor` is the canonical local architecture validation command.
- `bin/pave context` produces agent-readable context.
- `bin/pave explain` gives package/product/plugin map.
- Commands fail with clear `Pave::Error` codes.

---

# Later L3 — Observability Stack Specification

## Intent

Add a reusable production observability template for Pavê deployments without making observability required for local development.

## Dependencies

- R0 through R7 complete.
- Runtime package boundaries stable.

## Outcome

Repository has optional observability configuration under `ops/observability/`.

## Scope

Create templates for:

```text
OpenTelemetry Collector
Prometheus
Loki
Tempo
Grafana
```

Suggested location:

```text
ops/observability/
  otel-collector/
  prometheus/
  loki/
  tempo/
  grafana/
  README.md
```

## Runtime contracts

Pavê should define generic instrumentation points for:

- request lifecycle
- service execution
- audit writes
- billing transitions
- plugin webhook handling
- background jobs

Do not make every runtime action emit expensive traces by default. Sampling and production toggles must exist.

## Non-goals

- Do not require Grafana stack to run Anella.
- Do not block deploy on observability if disabled.
- Do not add vendor-specific SaaS observability lock-in.

## Acceptance criteria

- Optional stack can be started from documented commands.
- Pavê emits useful generic spans/log fields when enabled.
- Disabled observability has negligible overhead.

---

# Later L4 — Agent Context Files Specification

## Intent

Generate and maintain concise architecture context files so AI coding agents can work inside Pavê without hallucinating boundaries.

## Dependencies

- R0 through R7 complete.
- `bin/pave context` available or planned.
- Runtime registry can inspect packages/plugins/panels/capabilities/events.

## Outcome

Each module/package has a concise `CONTEXT.md`; root has an `AGENT_CONTEXT.md` that explains the system map and active constraints.

## Files

```text
AGENT_CONTEXT.md
runtime/pave-core/CONTEXT.md
runtime/pave-tenancy/CONTEXT.md
runtime/pave-audit/CONTEXT.md
runtime/pave-identity/CONTEXT.md
runtime/pave-billing/CONTEXT.md
runtime/pave-backoffice/CONTEXT.md
products/anella/CONTEXT.md
plugins/*/CONTEXT.md
```

Each file should be 100–200 lines maximum.

## Required sections

Each context file should include:

```text
Purpose
Public APIs
Owned models/controllers/services
Forbidden dependencies
Common extension points
Validation commands
Known traps
```

## Generation strategy

Use `bin/pave context` to generate or refresh context. Generated sections must be marked. Hand-written constraints may be preserved.

## Acceptance criteria

- Context files exist and are accurate.
- Agent can identify where code belongs before implementing.
- Context does not duplicate huge docs.
- Context is grounded in actual registry/package data.

---

# Later L5 — Agent Workflow Templates Specification

## Intent

Create repeatable local-agent workflows for common Pavê changes so implementation remains bounded and contract-aware.

## Dependencies

- R0 through R7 complete.
- Agent context files available or planned.
- `bin/pave generate workflow` available or planned.

## Outcome

Pavê ships workflow templates that agents can execute with fewer boundary mistakes.

## Initial templates

```text
add-billing-gate
new-job
extract-service
new-module-panel
add-plan-feature
add-audit-event
add-plugin-capability
```

## Template format

Each template should include:

```text
Goal
Inputs required
Files likely touched
Forbidden files/packages
Validation commands
Commit message format
Handoff checklist
```

## Non-goals

- Do not make natural language executable architecture.
- Do not let templates bypass specs or tests.
- Do not generate broad features from vague prompts.

## Acceptance criteria

- Templates are short and practical.
- Each template references package boundaries.
- Each template tells the agent what not to touch.
- Templates can be listed by `bin/pave generate workflow --list` or equivalent.

---

# Later L6 — External Distribution Specification

## Intent

Prepare Pavê runtime packages for external use only after Anella proves the design in production.

## Dependencies

- R0 through R7 complete.
- At least one adversarial plugin implemented.
- Documentation and examples stable.
- Anella benefits from runtime extraction rather than being delayed by it.

## Outcome

Runtime packages can be versioned, released, and consumed outside the monorepo.

## Scope

Define:

```text
gemspec quality
semantic version strategy
compatibility matrix
plugin dependency declaration
migration/version policy
generator stability policy
public API documentation
upgrade guide
```

## Packages

Candidate external packages:

```text
pave-core
pave-tenancy
pave-audit
pave-identity
pave-billing
pave-backoffice
pave-hotwire later
pave-agent later
pave-template later
```

## Non-goals

- Do not build a marketplace first.
- Do not promise compatibility before APIs stabilize.
- Do not publish private Anella code.
- Do not chase broad adoption before concrete examples exist.

## Acceptance criteria

- Gems build locally.
- Versioning policy documented.
- Public API docs exist.
- Example app or template exists.
- Plugin compatibility declaration works.

---

# Later L7 — Second Product Specification

## Intent

Validate that Pavê is a runtime, not a renamed Anella.

## Dependencies

- R0 through R7 complete.
- Anella stable on runtime.
- At least core/tenancy/audit/identity/backoffice contracts are usable by a product that is not scheduling-first.

## Outcome

A second product package runs in the same runtime using shared Pavê modules without importing Anella domain assumptions.

## Candidate products

Choose one small but meaningfully different product:

```text
content/pages/blog
education/courses
lightweight CRM
artist portfolio/store backoffice
```

Avoid another scheduling product as the first proof, because it will not stress Anella contamination enough.

## Validation targets

The second product should prove:

- product package registration works
- tenant scoping works without appointment assumptions
- backoffice panels register independently
- audit events are generic
- identity/membership roles are reusable
- billing gates are reusable if needed
- Packwerk prevents cross-product leakage

## Non-goals

- Do not build a large second SaaS.
- Do not distract from Anella revenue.
- Do not copy Anella patterns blindly.

## Acceptance criteria

- Second product boots and has at least one useful backoffice panel.
- It has at least one tenant-owned model.
- It writes at least one audit event.
- It has no dependency on `products/anella`.
- Anella has no dependency on the second product.

---

# Later L8 — Kamal Deploy Templates Specification

## Intent

Provide reusable deployment templates for Pavê apps while preserving project-specific deploy control.

## Dependencies

- R0 through R7 complete.
- Runtime layout stable.
- Existing Anella deployment remains working.

## Outcome

Pavê has deploy templates and validation commands for Kamal-based deployments.

## Scope

Create:

```text
ops/deploy/kamal/config/deploy.yml.example
ops/deploy/kamal/secrets.example
ops/deploy/kamal/hooks/*
bin/pave deploy doctor
```

`bin/pave deploy doctor` should validate:

- required env vars exist
- image registry config present
- database accessory config present if used
- secrets file references expected keys
- app boots in production-like mode where feasible
- runtime packages are eager-loadable

## Non-goals

- Do not replace Kamal.
- Do not force one hosting provider.
- Do not expose secrets.
- Do not break existing Anella deploy.

## Acceptance criteria

- Templates are usable but opt-in.
- Existing deploy remains unchanged unless explicitly migrated.
- Deploy doctor catches missing credentials/config early.
- Docs explain how product packages and runtime packages are loaded in production.

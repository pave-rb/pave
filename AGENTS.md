# AGENTS.md — Pavê Runtime Repository

## 1. Repository Identity

This repository is the **Pavê runtime source monorepo**.

It produces Pavê gems and runtime tooling.
It is **not** a Pavê host app.
It must **not** contain product-specific application code.

## 2. Distribution Model

Pavê is distributed as gems installed through Bundler.

Developers create or maintain Pavê host apps that consume Pavê like:

```ruby
gem "pave"
```

or, during internal/private development, through local path or Git-tag gem dependencies:

```ruby
gem "pave-core", path: "../pave/gems/pave-core"
```

Existing host apps upgrade Pavê through:

```bash
bundle update pave
bin/pave upgrade
bin/pave doctor
```

All Pavê gems are versioned in lockstep (e.g., all at `0.4.0`).

## 3. Core Concepts

| Term | Definition |
|---|---|
| Runtime | The Pavê gem family providing reusable business-layer capabilities. |
| Host App | The deployable Rails application that consumes Pavê gems via Bundler. |
| Product Package | A first-class Pavê runtime node containing domain application code. Loaded by the runtime, not a Rails engine. |
| Plugin Package | An optional installable gem extending Pavê, registered at boot, declaring a `Pave::Plugin` manifest. |
| Runtime Module | A versioned Pavê gem (e.g., `pave-tenancy`, `pave-billing`) providing reusable business primitives. |
| Resource | A declarative runtime primitive representing a domain entity. |
| Action | A declarative runtime primitive representing a write operation. |
| Capability | A named entitlement string checked by `PlanEnforcer` at action boundaries. |
| Event | An immutable domain event emitted through the runtime. |
| Manifest | A YAML/ruby declaration that describes a product, plugin, or module. |
| Backoffice | The super-admin UI chrome provided by Pavê; products register panels into it. |
| Agent Context | A structured text snapshot emitted by `bin/pave context` for AI coding agents. |

**Key rules:**
- A host app is the deployable unit.
- Products are installed into host apps.
- Pavê does not independently deploy products.
- If products need separate infrastructure, create separate host apps.

## 4. Target Repo Shape

```
pave/
├── gems/
│   ├── pave/              (meta-gem, CLI entrypoint)
│   ├── pave-core/         (pure Ruby runtime contracts)
│   ├── pave-rails/        (Rails integration, Railtie, generators)
│   ├── pave-tenancy/      (tenant model, request lifecycle)
│   ├── pave-identity/     (users, sessions, roles, impersonation)
│   ├── pave-billing/      (provider-neutral billing primitives)
│   ├── pave-audit/        (immutable audit interface)
│   ├── pave-backoffice/   (platform/product backoffice chrome)
│   ├── pave-hotwire/      (Hotwire-native helpers — target)
│   └── pave-agent/        (agent context generation — target)
├── template/
│   └── host_app/          (blank host app template — target)
├── test/
│   ├── dummy/             (dummy host app for engine tests)
│   └── integration/       (cross-package integration tests)
├── docs/
├── scripts/
│   ├── build-gems
│   ├── release
│   ├── smoke-install
│   └── repo-check-clean
├── gemfiles/
│   ├── rails_8_0.gemfile
│   └── rails_8_1.gemfile
├── products/              (only dummy/test products, never real apps)
├── plugins/               (optional installable plugin gems)
├── Gemfile
├── Rakefile
├── README.md
├── CHANGELOG.md
├── LICENSE.txt
└── AGENTS.md
```

**Current state:** The repo is under active extraction. Gems live under `gems/`. Anella-specific code has been removed or externalized from the runtime. Do not introduce new code in `products/` directories. Do not create new code in the host `app/` directory. Place new runtime code inside the appropriate `gems/pave-*` package.

## 5. Package Responsibilities

### `pave` (meta-gem — target)
Depends on default Pavê runtime gems. Exposes the CLI executable (`bin/pave`). Provides the install generator entrypoint.

### `pave-core` (exists — `gems/pave-core`)
Pure Ruby gem. Must not depend on Rails.
Owns: runtime registry, error hierarchy, product/plugin/resource/action declarations, `Pave::Current`, `Pave::Service`, `Pave::Result`, `Pave::Registry`, `Pave::Plugin`, `Pave.configure`, version/compatibility primitives.

### `pave-rails` (exists — `gems/pave-rails`)
Rails integration gem/engine.
Owns: Railtie/engine integration, install generator, upgrade tasks, product boot, route/view/migration path wiring, host app config integration, Rails-aware CLI commands. Currently a stub — implement planned features.

### `pave-tenancy` (exists — `gems/pave-tenancy`)
Rails engine gem.
Owns: `Pave::Tenancy::Space`, `SpaceMembership`, tenant request lifecycle, `Current.space` wiring, `Pave::Tenancy::BaseController`.

### `pave-identity` (exists — `gems/pave-identity`)
Rails engine gem.
Owns: `Pave::Identity::User`, session management, roles, impersonation, super admin concept.

### `pave-billing` (exists — `gems/pave-billing`)
Rails engine gem. Provider-agnostic.
Owns: `Plan`, `Subscription`, `BillingEvent`, `PlanEnforcer`, `CreditTransaction`, provider adapter interface, webhook handler base.

### `pave-audit` (exists — `gems/pave-audit`)
Rails engine gem.
Owns: `Pave::Audit::AuditEvent`, `Pave::Audit.log` / `log!`, immutable append-only event log.

### `pave-backoffice` (exists — `gems/pave-backoffice`)
Rails engine gem.
Owns: Platform/Product/Module panel chrome, `Pave::Backoffice::BaseController`, panel registration API, breadcrumb/nav chrome, super admin auth contract.

### `pave-hotwire` (target)
Hotwire-native helpers and UI derivation.

### `pave-agent` (target)
Agent context generation, workflow templates, `bin/pave context` output.

## 6. Dependency Rules

```
pave-core must not depend on Rails.
Runtime packages must not depend on products.
Runtime packages must not reference Anella.
Plugins must not access product internals.
Products are external to this repo except dummy/test products.
Shared runtime behavior belongs in gems.
Product-specific behavior belongs in host apps or product packages.
```

**Dependency graph (acyclic):**

```
pave-core
    ↑
pave-tenancy ←── pave-identity
    ↑                  ↑
pave-audit         pave-billing
    ↑                  ↑
pave-backoffice ────────┘
    ↑
products/* and plugins/*
```

No module depends on a product. No module depends on a plugin. Products may depend on runtime module public APIs.

## 7. Anella Contamination Rule

Anella is **external** to this repo.

- Do not implement Anella features here.
- Do not preserve Anella-specific code here.
- Do not reference Anella constants, domains, pricing, onboarding, WhatsApp assumptions, or billing provider adapters.
- If unsure whether code belongs to Pavê or Anella, **assume it belongs outside Pavê**.

**Test fixtures must use neutral names:**

| Correct | Wrong |
|---|---|
| `DemoScheduling` | `Anella` |
| `SampleProduct` | `Anella::Appointment` |
| `Acme` | `Anella::Customer` |
| `DummyProduct` | `Anella::Whatsapp` |

Prefer `DemoScheduling` for realistic runtime contract tests.

## 8. Coding Rules

- Use idiomatic Ruby and Rails.
- Keep runtime APIs explicit.
- Avoid magic unless it removes more repeated work than it adds.
- Prefer generators, contracts, and checks over hidden behavior.
- Keep generated code readable.
- Do not replace Rails conventions unnecessarily.
- Runtime declarations should compile/cache at boot, not scan per request.
- `Pave::Service` is the base class for all service objects.
- Controllers orchestrate — they do not implement business logic.
- Background jobs must be tenant-aware, idempotent, and receive explicit `space_id`.

## 9. Testing Rules

**Required commands (when available in the repo):**

```bash
bundle exec rake test
bundle exec rubocop
bundle exec packwerk check
bin/pave doctor
```

**Target commands (not yet implemented; do not require them):**

```bash
scripts/build-gems
scripts/repo-check-clean
scripts/smoke-install
```

**Testing conventions:**
- Test-driven development.
- Every service object: happy path, failure path, edge case.
- Background jobs: idempotency and retry safety.
- Prefer request specs over controller specs.
- Avoid over-mocking domain logic.

## 10. CLI Surface

`bin/pave` is the agent-facing and developer-facing command surface.

**Implemented:**

```
bin/pave help              — Show this help
bin/pave version           — Print the Pavê runtime version
bin/pave doctor            — Run runtime health checks
bin/pave doctor --upgrade  — Print planned upgrade checks
bin/pave context           — Generate an agent context snapshot
bin/pave new product <name> — Generate a new product scaffold
bin/pave list products     — List registered products
bin/pave install:migrations — (stub) Copy engine migrations
bin/pave upgrade           — (stub) Upgrade plan
bin/pave app:update        — (stub) Host app config update
bin/pave repo:check-clean  — Check for private operator material and forbidden references
```

Commands must not assume Anella. CLI output must refer to host app, product, plugin, runtime, module.

## 11. Agent Behavior

- Before changing code, identify which package owns the responsibility.
- Do not edit multiple packages unless the integration requires it.
- Do not add product-specific examples to runtime code.
- Do not silently create new architecture concepts.
- Do not widen scope beyond the requested task.
- Update tests and context docs when public runtime contracts change.
- Prefer deletion over speculative generalization during cleanup.
- If the spec says "target" or "planned" for a package or command, do not implement it unless explicitly instructed.
- Do not introduce new Anella references.
- Test fixture names must be neutral (prefer `DemoScheduling` or `DummyProduct`).
- Run existing checks before and after changes — do not skip validation.

## 12. Known Follow-Up Work

The following cleanup tasks are out of scope for this document but should be performed separately:

- (Completed) Convert `runtime/` → `gems/` directory layout.
- (Completed) Add neutral dummy product (`test/dummy/products/demo_scheduling/`).
- (Completed) Create `gems/pave` meta-gem.
- (Completed) Add install generator (`pave:install`) with templates.
- (Completed) Add product generator (`pave:product`) with templates.
- (Completed) Add `bin/pave repo:check-clean` command.
- (Completed) External consumer validation — local path and Git tag consumption validated.
- Add `scripts/build-gems` and `scripts/repo-check-clean` scripts.
- Create `template/host_app/` for blank Pavê host app generation.

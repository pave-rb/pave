# SPEC: Clean Pavê Runtime Repository Split

## 1. Purpose

This spec guides the cleanup of a copied Pavê/Anella repository into a clean Pavê runtime repository.

Assumption:

```txt
The current repo has already been copied/forked into two places:

1. Anella repo
   - Lives outside the `pave-rb` organization.
   - Continues as the deployable Anella Pavê host app.
   - Owns Anella product code, Anella credentials, Anella deployment, Anella branding, and Anella-specific integrations.

2. Pavê repo
   - Lives under `pave-rb/pave`.
   - Becomes the clean runtime source monorepo.
   - Produces Pavê gems and tooling.
   - Must ignore Anella completely from this point forward.
```

The goal of this cleanup is to turn the Pavê repo into a runtime producer, not a deployable Anella app and not a forked product host.

---

## 2. Final Repository Identity

Target repository:

```txt
pave-rb/pave
```

Repository role:

```txt
Pavê runtime source monorepo.
```

It produces:

```txt
- Pavê runtime gems
- Pavê Rails engines
- Pavê CLI
- Pavê generators
- Pavê upgrade tasks
- Pavê host app template
- test/dummy host apps for runtime validation
```

It does not contain:

```txt
- Anella product code
- Anella deployment config
- Anella credentials or credential names
- Anella routes
- Anella views
- Anella models
- Anella services
- Anella jobs
- Anella assets
- Anella branding
- Anella WhatsApp/product-specific integrations
```

---

## 3. Core Decision

Pavê is a runtime distributed through gems.

A developer installs Pavê into a host app through Bundler:

```ruby
gem "pave"
```

A developer upgrades Pavê in an existing host app through Bundler plus Pavê upgrade tooling:

```bash
bundle update pave
bin/pave upgrade
bin/pave doctor
```

The Pavê repo must therefore be shaped like a gem/engine runtime repository, not like a Rails product application.

---

## 4. Hard Cleanup Rule

Anella must be treated as external after this split.

The clean Pavê repo must not know about Anella.

### Forbidden references

The following strings must not appear in runtime code, generators, tests, docs, fixtures, config, or examples:

```txt
Anella
anella
ANELLA
anella.app
Asaas adapter names tied only to Anella
Anella-specific WhatsApp assumptions
Anella-specific pricing copy
Anella-specific onboarding copy
Anella-specific salon/clinic defaults unless moved into neutral examples
```

Exception:

```txt
A temporary migration note may mention that Pavê was extracted from an application,
but it must not name or depend on Anella.
```

Preferred stricter rule:

```txt
No Anella references anywhere in the clean Pavê repo after cleanup.
```

Add CI check:

```bash
bin/pave repo:check-clean
```

or initially:

```bash
grep -R "Anella\|anella\|ANELLA" .   --exclude-dir=.git   --exclude=SPEC_CLEAN_PAVE_REPO.md
```

This check should fail if any accidental Anella reference remains.

---

## 5. Target Top-Level Structure

Target shape:

```txt
pave/
├── gems/
│   ├── pave/
│   ├── pave-core/
│   ├── pave-rails/
│   ├── pave-tenancy/
│   ├── pave-identity/
│   ├── pave-billing/
│   ├── pave-audit/
│   ├── pave-backoffice/
│   ├── pave-hotwire/
│   └── pave-agent/
├── template/
│   └── host_app/
├── test/
│   ├── dummy/
│   └── integration/
├── spec/
├── docs/
├── scripts/
│   ├── build-gems
│   ├── release
│   ├── smoke-install
│   └── repo-check-clean
├── gemfiles/
│   ├── rails_8_0.gemfile
│   └── rails_8_1.gemfile
├── Gemfile
├── Rakefile
├── README.md
├── CHANGELOG.md
├── LICENSE.txt
└── AGENTS.md
```

Use `gems/` instead of `runtime/` in the clean Pavê repo because this repo is now explicitly a distribution source.

If the current code still uses `runtime/`, migrate it to `gems/` during cleanup.

---

## 6. Gem Packages

### 6.1 `pave`

Meta-gem.

Purpose:

```txt
The gem most users install.
```

Responsibilities:

```txt
- Depends on default Pavê runtime gems.
- Exposes CLI executable.
- Requires core integration.
- Provides install generator entrypoint if appropriate.
```

Example dependency direction:

```ruby
spec.add_dependency "pave-core", version
spec.add_dependency "pave-rails", version
spec.add_dependency "pave-tenancy", version
spec.add_dependency "pave-identity", version
spec.add_dependency "pave-audit", version
spec.add_dependency "pave-backoffice", version
```

### 6.2 `pave-core`

Pure Ruby gem.

Owns:

```txt
- Runtime registry
- Error hierarchy
- Product/plugin/resource/action declarations
- Capability/event contracts
- Manifest parsing
- Version/compatibility primitives
- Minimal CLI primitives that do not require Rails
```

Must not depend on Rails.

### 6.3 `pave-rails`

Rails integration gem/engine.

Owns:

```txt
- Railtie/engine integration
- Install generator
- Upgrade tasks
- Product boot
- Route/view/migration path wiring
- Host app config integration
- `bin/pave` Rails-aware commands
```

### 6.4 Runtime module gems

```txt
pave-tenancy
pave-identity
pave-billing
pave-audit
pave-backoffice
```

These are Rails-integrated runtime modules.

Each should have:

```txt
lib/pave/<module>.rb
lib/pave/<module>/engine.rb
lib/pave/<module>/version.rb
app/
db/migrate/
package.yml
CONTEXT.md
<gem-name>.gemspec
test or spec
```

### 6.5 Optional/later gems

```txt
pave-hotwire
pave-agent
```

Keep these if there is already useful code.

If not implemented, create only placeholders or defer entirely.

Do not overbuild.

---

## 7. Lockstep Versioning

All Pavê gems are versioned in lockstep for now.

Example:

```txt
pave 0.4.0
pave-core 0.4.0
pave-rails 0.4.0
pave-tenancy 0.4.0
pave-identity 0.4.0
pave-billing 0.4.0
pave-audit 0.4.0
pave-backoffice 0.4.0
```

Do not create independent release cadences yet.

Do not split gems into separate repos yet.

---

## 8. Distribution Model

### Internal phase

An external host app, such as Anella, consumes Pavê by path or Git tag.

Path development:

```ruby
gem "pave", path: "../pave/gems/pave"
gem "pave-core", path: "../pave/gems/pave-core"
gem "pave-rails", path: "../pave/gems/pave-rails"
```

Tagged internal release:

```ruby
git "git@github.com:pave-rb/pave.git", tag: "v0.4.0-internal" do
  gem "pave", glob: "gems/pave/*.gemspec"
  gem "pave-core", glob: "gems/pave-core/*.gemspec"
  gem "pave-rails", glob: "gems/pave-rails/*.gemspec"
  gem "pave-backoffice", glob: "gems/pave-backoffice/*.gemspec"
end
```

### Public phase

Eventually:

```ruby
gem "pave", "~> 0.5"
```

Public RubyGems distribution is not required for this cleanup.

---

## 9. What to Delete

Delete from the clean Pavê repo:

```txt
products/anella/
app/models/anella-specific files
app/controllers/anella-specific files
app/views/anella-specific files
app/services/anella-specific files
app/jobs/anella-specific files
config/routes that mount Anella
config/deploy.yml for Anella
config/credentials examples that reference Anella providers
public/Anella assets
app/assets Anella brand assets
test/spec files that assert Anella behavior
fixtures/factories named after Anella entities
documentation written as if Anella is the installed product
```

Also delete or neutralize:

```txt
WhatsApp code that is only valid for Anella
Asaas adapter if it lives in runtime
product-specific onboarding templates
salon/clinic seed data
Anella billing plan defaults
Anella landing-page/frontend assets
```

If something is reusable, move it into a neutral runtime module or plugin.

If it is domain-specific, it belongs in the external Anella repo.

---

## 10. What to Keep

Keep runtime code that is genuinely generic:

```txt
Pave::Current
Pave::Service
Pave::Registry
Pave.configure
Product registry
Plugin registry
Product boot/loading
Runtime engine shells
Tenancy primitives
Identity primitives
Billing abstractions
Audit abstractions
Backoffice shell/chrome/registration API
Settings interface if generic
CLI skeleton
Doctor checks
Agent context generation
Generators
Packwerk boundary tooling
```

Keep docs only if they are generalized.

Rewrite examples to use neutral names.

---

## 11. Neutral Test Product

Replace Anella in tests with a neutral dummy product.

Use one of:

```txt
DummyProduct
Acme
SampleProduct
DemoScheduling
```

Recommended:

```txt
DemoScheduling
```

Because Pavê needs a real-ish workflow to test product boot, routes, migrations, and backoffice panels.

Target test fixture:

```txt
test/dummy/products/demo_scheduling/
  app/
    controllers/
    models/
    services/
    views/
  config/
    routes.rb
    product.rb
    backoffice.rb
  db/
    migrate/
  product.yml
  package.yml
  CONTEXT.md
```

Rules:

```txt
- DemoScheduling exists only for tests and examples.
- It must not contain Anella code copied with names changed unless the behavior is generic.
- It should be minimal.
- It should test Pavê runtime contracts, not product business depth.
```

---

## 12. Host App Template

The clean Pavê repo should include a host app template, but keep it minimal.

```txt
template/host_app/
  Gemfile.tt
  config/pave.rb.tt
  config/routes.rb.tt
  config/initializers/pave.rb.tt
  products/.keep
  AGENTS.md.tt
  PAVE_MANIFEST.yml.tt
  pave.lock.tt
```

This template is not the same as Anella.

It should generate a blank Pavê host app.

Install flow:

```bash
bundle add pave
bin/rails generate pave:install
```

or later:

```bash
rails new my_platform -m https://...
```

---

## 13. CLI Scope

The clean Pavê repo should provide the CLI executable through the gem.

Target commands for first cleanup:

```txt
bin/pave version
bin/pave doctor
bin/pave context
bin/pave new product <name>
bin/pave list products
bin/pave install:migrations
bin/pave upgrade
```

Commands may be stubs if behavior is not implemented yet, but they must not assume Anella.

All CLI output must refer to:

```txt
host app
product
plugin
runtime
module
```

Never to Anella.

---

## 14. Upgrade Tooling Scope

Do not implement full upgrade behavior during cleanup unless already close.

But define the surfaces:

```txt
bin/pave upgrade
bin/pave app:update
bin/pave install:migrations
bin/pave doctor --upgrade
```

Upgrade must eventually handle:

```txt
- Bundler runtime version bump
- Generated config reconciliation
- Runtime migrations
- Product/plugin compatibility
- AGENTS.md/context regeneration
- pave.lock update
- Upgrade report
```

For cleanup, it is enough that the command exists and does not reference Anella.

---

## 15. Backoffice Cleanup

`pave-backoffice` must remain generic.

Keep:

```txt
Platform dashboard
Product dashboard shell
Panel registration
Super admin auth contract
Audit helper contract
Settings shell if generic
Navigation/breadcrumb chrome
```

Delete:

```txt
Anella billing panels
Anella spaces panels
Anella WhatsApp panels
Anella support/customer panels
Anella-specific menu labels
Anella product assumptions
```

Replace product panel tests with `DemoScheduling`.

Backoffice must be usable with zero products installed.

---

## 16. Billing Cleanup

`pave-billing` must be provider-agnostic.

Keep:

```txt
Plan
Subscription
BillingEvent
PlanEnforcer
Provider adapter interface
Webhook handler base
Metered resource abstractions
```

Move out/delete:

```txt
Anella::Billing::AsaasAdapter
Anella-specific plan defaults
Anella pricing tiers
Anella message credit assumptions that are not generic
```

If Asaas is useful, extract later as:

```txt
pave-asaas
```

or:

```txt
plugins/asaas_billing
```

Do not keep it in core billing.

---

## 17. Identity Cleanup

`pave-identity` must remain platform/product neutral.

Keep:

```txt
User
Session
Super admin concept
Membership/role contracts
Impersonation if generic
```

Delete:

```txt
Anella user profile fields
Anella onboarding fields
Anella-specific sign-in copy
Product sign-in assumptions tied to Anella
```

Super admin sign-in may remain as Pavê platform auth.

---

## 18. Tenancy Cleanup

`pave-tenancy` must remain generic.

Keep:

```txt
Space
SpaceMembership
Current.space lifecycle
Tenant-scoped base controller
Tenant table validation rules
```

Delete:

```txt
Anella-specific space profile fields
Business category fields tied to salons/clinics
Anella onboarding state
```

Move product-specific tenant profile data to the external Anella repo.

---

## 19. Agent Context Cleanup

Rewrite agent context to describe Pavê only.

Files to update:

```txt
AGENTS.md
CONTEXT.md files
docs/*
README.md
PAVE_MANIFEST.yml
```

They should say:

```txt
This repository is the Pavê runtime source monorepo.
It produces gems.
It does not contain product application code.
Host apps consume it through Bundler.
Tests use DemoScheduling as a dummy product.
```

They should not instruct agents to implement Anella features.

---

## 20. CI Gates

Add CI jobs:

```txt
bundle install
bundle exec rake test
scripts/build-gems
scripts/repo-check-clean
scripts/smoke-install
```

`repo-check-clean` must fail on Anella references.

`build-gems` must build all gemspecs.

`smoke-install` should eventually create or use a dummy external host app and install Pavê from local path gems.

---

## 21. Smoke Host

Inside the Pavê repo, use `test/dummy` for engine tests.

Separately, create later:

```txt
pave-rb/pave-smoke-host
```

Purpose:

```txt
Validate that an external host app can consume Pavê without having runtime source inside the app.
```

Do not block this cleanup on creating the separate repo.

---

## 22. Migration Sequence

### Phase 1 — Mark split boundary

- Rename repository to `pave`.
- Update README title.
- Add this spec to `.agents/specs/SPEC_CLEAN_PAVE_REPO.md`.
- Add clear notice: this repo is not Anella.

### Phase 2 — Remove Anella product

- Delete `products/anella`.
- Delete Anella-specific app code.
- Delete Anella routes and backoffice panels.
- Delete Anella assets and docs.

### Phase 3 — Move runtime to gems

- Move `runtime/pave-*` to `gems/pave-*`.
- Add or fix gemspecs.
- Add meta-gem `gems/pave`.
- Ensure paths and requires still boot.

### Phase 4 — Add dummy product

- Create `test/dummy/products/demo_scheduling`.
- Update tests to use `DemoScheduling`.
- Remove all Anella expectations.

### Phase 5 — Generalize config/generators

- Ensure `pave:install` creates generic host config.
- Ensure `bin/pave` works in runtime repo and installed host apps.
- Ensure generators produce neutral product names.

### Phase 6 — Release skeleton

- Add `scripts/build-gems`.
- Add `scripts/release`.
- Add `scripts/repo-check-clean`.
- Tag first internal runtime release.

### Phase 7 — External consumer validation

- Update external Anella repo to consume Pavê via local path.
- Then consume via internal Git tag.
- Run Anella tests.
- Run Anella deploy preflight.

---

## 23. Required Exit Criteria

The cleanup is complete when:

```txt
1. `grep -R "Anella\|anella\|ANELLA"` returns no forbidden references.
2. All runtime packages live under `gems/`.
3. Every gem has a valid gemspec.
4. The meta-gem `pave` exists.
5. Runtime tests pass without Anella.
6. Backoffice boots with zero products.
7. DemoScheduling dummy product validates product boot.
8. `scripts/build-gems` builds all gems.
9. `bin/pave doctor` runs without assuming Anella.
10. `bin/pave context` describes Pavê runtime, not Anella.
11. External Anella repo can consume Pavê by local path.
12. External Anella repo can consume Pavê by internal Git tag.
```

---

## 24. Non-Goals

Do not do these during cleanup:

```txt
- Publish to RubyGems.
- Create one repo per gem.
- Build plugin marketplace.
- Build a hosting/launcher/orchestrator.
- Implement full resource/action DSL unless already started.
- Move Anella business logic into Pavê.
- Preserve Anella examples “temporarily.”
- Build public docs site.
```

---

## 25. Agent Instructions

When executing this cleanup:

```txt
Treat Anella as already safely copied elsewhere.
Do not preserve Anella behavior in this repo.
Do not ask whether Anella code should be kept.
Remove or externalize all product-specific code.
Keep only generic runtime abstractions.
Replace product-specific tests with DemoScheduling.
Prefer deletion over speculative generalization.
If unsure whether code belongs in Pavê or Anella, it belongs outside Pavê.
```

The resulting repo should be clean, boring, distributable runtime infrastructure.

Pavê should emerge as a Rails-native runtime gem family, not as an Anella fork.

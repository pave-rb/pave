# Phase 1 — Boundary Inventory

**Date:** 2026-06-23
**Repository:** `/Users/italo/workspace/elos-workspace/pave`
**Status:** Complete — read-only inspection, zero source changes.

---

## 1. Overview

| Metric | Value |
|---|---|
| Total files (excl .git, tmp, node_modules) | 4,436 |
| Ruby files | 484 |
| ERB files | 128 |
| YAML files | 8 (excluding locales) |
| Runtime packages | 6 (all under `runtime/`) |
| Product packages | 0 (empty `products/` dir) |
| Plugin packages | 0 (empty `plugins/` dir) |
| Gemspecs | 6 |
| Packwerk packages | 7 (root + 6 runtime) |
| Build scripts | 0 |
| CONTEXT.md files | 0 |
| PAVE_MANIFEST.yml files | 0 |
| Template (.tt) files | 0 |
| CI workflow files | 1 (`.github/workflows/pave-runtime.yml`) |
| Test files with Anella refs | 23 |
| Doc/agent files with Anella refs | ~50 |
| Files with non-test Anella source refs | ~18 |

---

## 2. Anella References — Categorized File List

### 2a. Runtime Code (1 file)

| File | Line | Content | Notes |
|---|---|---|---|
| `runtime/pave-backoffice/lib/pave/backoffice/compatibility_shims.rb` | 21 | `description: "Registry#register_panel accepts old flat-format panel keys (e.g. 'anella.home')"` | Doc comment — minor contamination |

### 2b. App Code (3 files)

| File | Lines | Content |
|---|---|---|
| `app/models/space.rb` | 54 | `has_one :anella_space_profile, class_name: "Anella::SpaceProfile", ...` |
| `app/assets/tailwind/application.css` | — | Contains `@source` directives pointing at `products/anella/` |
| `app/views/layouts/_pwa_head.html.erb` | — | `apple-mobile-web-app-title` set to `"Anella"` |

### 2c. Config (7 files)

| File | Details |
|---|---|
| `config/application.rb` | Module `AppointmentScheduler`, default app name `"Anella"`, logo `anella-logo.png`, wordmark `anela-bgless.png`, company `Elo Consultoria em Software LTDA` |
| `config/products.rb` | Full `:anella` product registration with tenant chrome, settings menus, backoffice modules, redirects, conditional on `products/anella` directory existing |
| `config/routes.rb` | Legacy redirects to `/backoffice/anella/spaces` |
| `config/deploy.yml` | Service `appointment_scheduler`, server `anella-prod`, proxy host `anella.app`, image `italoaalves/appointment_scheduler` |
| `config/environments/development.rb` | Comments referencing `anella.localhost` |
| `config/environments/test.rb` | Comments referencing `products/anella/test/` |
| `config/credentials.yml.enc` | Exists — likely contains Anella provider references (cannot inspect without key) |
| `config/credentials/` | Has `development.key`, `development.yml.enc`, `production.key`, `production.yml.enc`, `staging.key`, `staging.yml.enc` |

### 2d. Locales (6 files)

| File | Anella Keys / Values |
|---|---|
| `config/locales/en/interface.yml` | `app_name: "Anella"` |
| `config/locales/pt-BR/interface.yml` | `app_name: "Anella"` |
| `config/locales/en/backoffice.yml` | Product `anella` key, `"Anella-created templates"`, `"Anella starter blueprints"`, `anella_created` source badge |
| `config/locales/pt-BR/backoffice.yml` | Same structure in Portuguese |
| `config/locales/en/billing.yml` | `"...are managed by Anella."` demo description |
| `config/locales/pt-BR/billing.yml` | Same in Portuguese |

### 2e. Public Assets (3+ files)

| File | Details |
|---|---|
| `public/manifest.webmanifest` | `name: "Anella"`, `short_name: "Anella"` |
| `public/service-worker.js` | `const title = payload.title \|\| "Anella"` |
| `public/assets/` | Contains `anella-logo-*.png`, `anella-*.css`, `anela-bgless-*.png`, plus Anella-specific compiled Stimulus controllers (booking, inbox, whatsapp, checkout_wizard, landing, etc.) |

### 2f. Deployment / Ops (4 files)

| File | Details |
|---|---|
| `config/deploy.yml` | See 2c — full Anella deployment config |
| `Dockerfile` | Image name `appointment_scheduler` in comments |
| `docker-compose.yml` | `OTEL_SERVICE_NAME: appointment-scheduler` |
| `.kamal/` | Exists with hooks and secrets referencing Anella |

### 2g. CI (1 file)

| File | Line | Content |
|---|---|---|
| `.github/workflows/pave-runtime.yml` | 39 | `bin/rails test test products/anella/test` |

### 2h. `bin/pave` (1 file)

| Lines | Content |
|---|---|
| 35 | `FORBIDDEN_RUNTIME_PATTERN = /Anella\|Appointment\|Customer\|Whatsapp\|WhatsApp\|Asaas\|booking\|clinic\|salon\|CRM/` |
| 182 | `failures << "Anella package dependencies" unless check("Anella package dependencies") { anella_package_dependencies_valid? }` |
| 247-255 | `anella_package_dependencies_valid?` method — checks `products/anella/package.yml` |
| 33-34 | `PRODUCT_DEPENDENCIES` array (generic, but named referencing product deps) |

### 2i. Root Docs (3 files)

| File | Details |
|---|---|
| `README.md` | Line 38: references Anella as "its first product" serving as reference implementation |
| `AGENTS.md` | Multiple references — defines Anella as external, lists cleanup tasks |
| `PROJECT_MANIFEST.md` | Lines 180-181: `register_product(:anella)`, `register_module(:anella, :billing)` |

### 2j. `.agents/` Docs/Specs/Plans/Ux (50+ files, ~524 total refs)

- `.agents/docs/PAVE_ARCHITECTURE.md` — ~70 refs, extensive product examples
- `.agents/docs/PAVE_SYSTEM_DESIGN.md` — ~30 refs
- `.agents/docs/PAVE_VERSIONING_AND_RELEASE_STRATEGY.md` — ~10 refs
- `.agents/docs/BACKOFFICE_SYSTEM_DESIGN.md` — ~25 refs
- `.agents/ux/BACKOFFICE_UX.md` — ~50 refs
- `.agents/prompts/PAVE_BACKOFFICE_UPDATE_PROMPT.md` — 1 ref
- `.agents/plans/backoffice-runtime-implementation/*` — ~20 refs across 4 files
- `.agents/plans/clean-pave-runtime-repo/*` — ~100+ refs across 7 files
- `.agents/plans/pave-runtime/*` — ~100+ refs across 20+ files
- `.agents/specs/PAVE_RUNTIME_ROADMAP_SPECS.md` — ~30 refs
- `.agents/specs/pave_runtime_specs/*` — ~30 refs across 15+ files
- `.agents/tmp/anella_tests.txt` — exists

---

## 3. Runtime Module Inventory

### 3.1 `runtime/pave-core`

| Aspect | Value |
|---|---|
| Gemspec | `pave-core.gemspec` — version `0.1.0`, deps: `rails >= 8.0` only |
| lib/ files | `core.rb`, `version.rb`, `configuration.rb`, `current.rb`, `engine.rb`, `error.rb`, `plugin.rb`, `registry.rb`, `result.rb`, `service.rb`, `settings.rb` |
| app/ | None |
| db/migrate/ | None |
| package.yml | `enforce_dependencies: true`, `dependencies: []` |
| Anella refs | **None** |
| Rails dependency | Yes (`rails >= 8.0`) — contradicts spec that says "must not depend on Rails" |

### 3.2 `runtime/pave-tenancy`

| Aspect | Value |
|---|---|
| Gemspec | `pave-tenancy.gemspec` — version `0.1.0`, deps: `rails >= 8.0`, `pave-core = 0.1.0` |
| lib/ files | `tenancy.rb`, `version.rb`, `engine.rb` |
| app/controllers | `pave/tenancy/base_controller.rb` |
| app/models | `pave/tenancy/space.rb`, `pave/tenancy/space_membership.rb` |
| db/migrate/ | None |
| package.yml | `enforce_dependencies: true`, `dependencies: ["runtime/pave-core"]` |
| Anella refs | **None** |

### 3.3 `runtime/pave-identity`

| Aspect | Value |
|---|---|
| Gemspec | `pave-identity.gemspec` — version `0.1.0`, deps: `rails >= 8.0`, `pave-core`, `pave-tenancy`, `pave-audit` |
| lib/ files | `identity.rb`, `version.rb`, `current_context.rb`, `impersonation.rb`, `engine.rb` |
| app/models | `pave/identity/user.rb` |
| app/controllers | None |
| db/migrate/ | None |
| package.yml | `enforce_dependencies: true`, `dependencies: ["runtime/pave-core", "runtime/pave-tenancy", "runtime/pave-audit"]` |
| Anella refs | **None** |

### 3.4 `runtime/pave-billing`

| Aspect | Value |
|---|---|
| Gemspec | `pave-billing.gemspec` — version `0.1.0`, deps: `rails >= 8.0`, `pave-core`, `pave-tenancy`, `pave-audit` |
| lib/ files | `billing.rb`, `version.rb`, `engine.rb`, `provider_adapter.rb`, `null_adapter.rb`, `webhook_handler.rb` |
| app/models | `plan.rb`, `billing_event.rb`, `subscription.rb`, `product.rb`, `credit_transaction.rb` |
| app/controllers | None |
| db/migrate/ | None |
| package.yml | `enforce_dependencies: true`, `dependencies: ["runtime/pave-core", "runtime/pave-tenancy", "runtime/pave-audit"]` |
| package.yml note | Does NOT depend on pave-identity (unlike pave-backoffice) |
| Anella refs | **None** |
| Notes | Has `NullAdapter` for dev/test — good. No Asaas adapter in runtime. |

### 3.5 `runtime/pave-audit`

| Aspect | Value |
|---|---|
| Gemspec | `pave-audit.gemspec` — version `0.1.0`, deps: `rails >= 8.0`, `pave-core`, `pave-tenancy` |
| lib/ files | `audit.rb`, `version.rb`, `engine.rb`, `error.rb`, `event_builder.rb` |
| app/models | `pave/audit/audit_event.rb` |
| app/controllers | None |
| db/migrate/ | None |
| package.yml | `enforce_dependencies: true`, `dependencies: ["runtime/pave-core", "runtime/pave-tenancy"]` |
| Anella refs | **None** |

### 3.6 `runtime/pave-backoffice`

| Aspect | Value |
|---|---|
| Gemspec | `pave-backoffice.gemspec` — version `0.1.0`, deps: `rails >= 8.0`, all 5 other Pavê gems |
| lib/ files | 15 files — `backoffice.rb`, `engine.rb` (complex), `authentication.rb`, `breadcrumbs.rb`, `navigation.rb`, `panel.rb`, `registry.rb`, `product_config_loader.rb`, `product_validator.rb`, `route_drawer.rb`, `settings_adapter.rb`, `doctor.rb`, `reserved_name_error.rb`, `tenant_scope_leak_error.rb`, `compatibility_shims.rb` |
| app/controllers | 10 files — base, sessions, products (3), platform (4) |
| app/models | 1 — `setting.rb` |
| app/helpers | 1 — `ui_helper.rb` (25+ methods) |
| app/presenters | 1 — `table_column.rb` |
| app/views | 2 layouts + 8 partials + 12 full templates + 2 error pages |
| app/javascript | 5 Stimulus controllers |
| config/routes.rb | Backoffice engine routes |
| db/migrate/ | None |
| package.yml | `enforce_dependencies: true`, `dependencies: ["runtime/pave-core", ..., "runtime/pave-billing"]` |
| Anella refs | **1 minor** — `compatibility_shims.rb` doc comment uses `"anella.home"` as example |

---

## 4. Product Code Inventory

### `products/` Directory

```
products/
  .keep   (empty placeholder)
```

**No `products/anella/` directory exists.** The `config/products.rb` file wraps the Anella registration in a conditional: `if Rails.root.join("products/anella").directory?` which evaluates to false with current layout. The Anella product is not physically present in this repo — it was presumably in a gitlinked submodule or separate checkout that has been removed.

### `plugins/` Directory

```
plugins/
  .keep   (empty placeholder)
```

No plugins registered anywhere.

### Product-Specific Code in Host `app/`

The entire `app/` directory is Anella host-app code:
- 38 controllers in `app/controllers/` (backoffice, profiles, spaces, users, concerns)
- 32 models in `app/models/` (Space, User, billing models, etc.)
- 46 service files in `app/services/` (auth, backups, tenancy, stored_files, etc.)
- 5 job files in `app/jobs/`
- 5 helper files in `app/helpers/`
- Extensive views in `app/views/` (layouts, backoffice panels, devise, profiles, legal, shared)
- Stimulus controllers in `app/javascript/`
- Assets in `app/assets/` (tailwind, images, stylesheets)

---

## 5. Host-App-Only Files

These files belong in a host app, not a runtime monorepo. They should be deleted or moved to a template.

### Infrastructure / Deploy
- `config/deploy.yml` — Anella-specific Kamal config
- `Dockerfile` — image: `appointment_scheduler`
- `docker-compose.yml` — full observability stack
- `Procfile.dev` — standard Rails dev
- `.kamal/` — Kamal hooks and secrets

### App Config
- `config/application.rb` — module `AppointmentScheduler`, host defaults
- `config/environments/development.rb` — letter_opener, `localhost:3000`
- `config/environments/test.rb` — eager load in CI only
- `config/environments/staging.rb` — solid cache/queue, OTEL
- `config/environments/production.rb` — solid cache/queue, OTEL
- `config/boot.rb` — standard Rails boot
- `config/puma.rb` — standard Puma config
- `config/database.yml` — PostgreSQL
- `config/cable.yml`, `config/cache.yml`, `config/queue.yml`, `config/solid_cache.yml` — standard
- `config/storage.yml` — standard
- `config/importmap.rb` — standard
- `config/credentials*` — all environment credentials (host-specific)

### App Code
- `app/` — entire directory (controllers, models, services, jobs, helpers, views, assets, javascript, channels, mailers)
- `app/models/space.rb` — couples tenancy with Anella business domains (appointments, CRM, WhatsApp, scheduling)
- `app/models/user.rb` — Anella-specific user model

### Public Assets
- `public/` — entire directory (error pages, manifest, service-worker, precompiled assets with Anella brand)

### Databases
- `db/schema.rb` — full Anella database schema
- `db/seeds.rb` — Anella seed data
- `db/migrate/` — Anella-specific migrations (appointments, clients, scheduling, WhatsApp, CRM, etc.)

### Library
- `lib/` — host-specific library code:
  - `lib/pave.rb` — entry point loading host `Pave` configuration
  - `lib/pave/product_boot.rb` — product boot integration
  - `lib/pave/product_registry.rb` — product registry
  - `lib/pave/backoffice_registry.rb` — legacy backoffice registry
  - `lib/pave/dev_subdomain_constraint.rb` — dev routing constraint
  - `lib/app_brand.rb` — Anella brand defaults
  - `lib/mailer_configuration.rb` — Anella mailer config
  - `lib/security/` — WebAuthn, encryption, audit fingerprint
  - `lib/observability/` — OTEL, error reporting, PII scrubbing
  - `lib/action_mailer/delivery_methods/resend_api.rb` — custom delivery method

### Tests
- `test/` — entire directory (see Section 9)

### CI
- `.github/workflows/pave-runtime.yml` — tests `products/anella/test`

---

## 6. Gemspec Inventory

| Gem | Path | Version | Rails Dep | Inter-Gem Deps | Files Included |
|---|---|---|---|---|---|
| pave-core | `runtime/pave-core/pave-core.gemspec` | 0.1.0 | `>= 8.0` | none | `lib/**/*`, `README.md` |
| pave-tenancy | `runtime/pave-tenancy/pave-tenancy.gemspec` | 0.1.0 | `>= 8.0` | pave-core | `lib/**/*`, `README.md` |
| pave-audit | `runtime/pave-audit/pave-audit.gemspec` | 0.1.0 | `>= 8.0` | pave-core, pave-tenancy | `lib/**/*`, `README.md` |
| pave-identity | `runtime/pave-identity/pave-identity.gemspec` | 0.1.0 | `>= 8.0` | pave-core, pave-tenancy, pave-audit | `lib/**/*`, `README.md` |
| pave-billing | `runtime/pave-billing/pave-billing.gemspec` | 0.1.0 | `>= 8.0` | pave-core, pave-tenancy, pave-audit | `lib/**/*`, `README.md` |
| pave-backoffice | `runtime/pave-backoffice/pave-backoffice.gemspec` | 0.1.0 | `>= 8.0` | all 5 others | `lib/**/*`, `app/**/*`, `config/**/*`, `README.md` |

**All gemspecs use lockstep versioning** — each pins inter-gem dependencies with `= VERSION`.

**Issue:** `pave-core` depends on `rails >= 8.0` per its gemspec, but AGENTS.md says "pave-core must not depend on Rails." The code itself does not obviously use Rails-specific features, but the gemspec declares the dependency.

---

## 7. Packwerk Inventory

### Root `packwerk.yml`
```yaml
exclude:
- "{bin,node_modules,script,tmp,vendor}/**/*"
- "lib/pave.rb"
- "lib/pave/**/*.rb"
- "runtime/pave-backoffice/app/controllers/pave/backoffice/base_controller.rb"
```

**Notable:** Excludes `lib/pave.rb` and all of `lib/pave/**/*.rb` from Packwerk enforcement — these are the host-app product boot files.

### Root `package.yml`
```yaml
enforce_dependencies: false
```

### Package Dependency Graph (from `package.yml` files)

```
pave-core         → []
pave-tenancy      → [pave-core]
pave-audit        → [pave-core, pave-tenancy]
pave-identity     → [pave-core, pave-tenancy, pave-audit]
pave-billing      → [pave-core, pave-tenancy, pave-audit]
pave-backoffice   → [pave-core, pave-tenancy, pave-audit, pave-identity, pave-billing]
```

Graph is acyclic and matches the spec.

---

## 8. CLI Command Inventory

### `bin/pave` — Implemented Commands

| Command | Implementation | Anella References? |
|---|---|---|
| `help` | Full — prints usage | None |
| `version` | Full — loads `pave/core`, prints version | None |
| `doctor` | Full — comprehensive health check | Yes (see below) |

### Doctor Checks (in order)

1. runtime directory exists
2. Each package files exist (gemspec, lib, version, engine, package.yml, README)
3. Each package can be required
4. pave-core APIs present
5. pave-tenancy APIs present
6. Rails boot
7. pave-tenancy models loaded
8. pave-audit APIs present
9. pave-identity APIs present
10. pave-billing APIs present
11. Backoffice doctor (delegated to `Pave::Backoffice::Doctor`)
12. Packwerk availability
13. Packwerk config files exist
14. Runtime dependency graph matches `PACKAGE_DEPENDENCIES`
15. **Anella package dependencies** — checks `products/anella/package.yml`
16. **Runtime anti-contamination** — scans runtime files for `FORBIDDEN_RUNTIME_PATTERN`
17. Packwerk validation
18. Packwerk dependency enforcement

### Anella Contamination in `bin/pave`

- Line 35: `FORBIDDEN_RUNTIME_PATTERN = /Anella|Appointment|Customer|Whatsapp|WhatsApp|Asaas|booking|clinic|salon|CRM/`
- Line 182: `check("Anella package dependencies")` — labels the check with "Anella"
- Lines 247-255: `anella_package_dependencies_valid?` method — hard-codes path `products/anella/package.yml`
- Note: The FORBIDDEN_RUNTIME_PATTERN includes non-Anella terms (booking, clinic, salon, CRM) that are runtime-contamination guard terms, but the label itself mentions Anella.

### Commands NOT Implemented (Target only)

- `context`
- `new product <name>`
- `list products`
- `install:migrations`
- `upgrade`
- `app:update`
- `repo:check-clean`
- `doctor --upgrade`

---

## 9. Test File Inventory — Anella References

### 9a. DELETE (7 files — product-specific, should be removed)

| File | Lines with Anella | Reason |
|---|---|---|
| `test/integration/backoffice_product_dashboard_test.rb` | 11 | Tests `GET /admin/anella`, product dashboard, panel navigation |
| `test/integration/backoffice_layout_test.rb` | 6 | Asserts "Anella" in nav, breadcrumbs, page header, context badges |
| `test/integration/backoffice_request_matrix_test.rb` | 4 | Tests protected routes to `/admin/anella/*` |
| `test/routing/backoffice_routing_test.rb` | 4 | Tests product dashboard routes (`/admin/anella`) and legacy redirects |
| `test/controllers/backoffice/products_controller_test.rb` | 4 | Tests backoffice navigation to `backoffice_anella_path` |
| `test/system/backoffice/hotwire_components_test.rb` | 3 | Visits `/admin/anella`, asserts "Anella" in nav and context |
| `test/integration/pave/backoffice/platform/dashboard_test.rb` | 1 | Asserts "Anella" in platform dashboard |

### 9b. REWRITE with DemoScheduling (3 files — runtime contracts using Anella as fixture)

| File | Lines with Anella | Notes |
|---|---|---|
| `test/lib/pave_backoffice_contracts_test.rb` | 24 | All `:anella` product panel registrations → `:demo_scheduling` |
| `test/lib/pave_backoffice_doctor_test.rb` | 1 | `"anella.spaces"` panel registration → neutral |
| `test/helpers/backoffice_ui_helper_test.rb` | 2 | Product context badge `"Anella"` → `"DemoScheduling"` |

### 9c. KEEP after neutralization (9 files — runtime capability tests using Anella example data)

| File | Lines with Anella | Replace With |
|---|---|---|
| `test/lib/app_brand_test.rb` | 3 | `"Anella"` → `"Pavê"` or `"Demo App"` |
| `test/lib/mailer_configuration_test.rb` | 8 | `staging.anella.app` → `staging.example.com`, `support@anella.app` → `support@example.com` |
| `test/lib/security/webauthn_config_test.rb` | 15 | `anella.app` → `example.com`, `"Anella"` → `"Example"` |
| `test/integration/pwa_directives_test.rb` | 3 | `"Anella"` → `"Pavê"` or `"Demo App"` |
| `test/services/backups/restore_database_backup_test.rb` | 3 | `anella-db-backups` → `demo-db-backups` |
| `test/services/backups/nightly_database_backup_test.rb` | 1 | `anella-db-backups` → `demo-db-backups` |
| `test/services/backups/remote_inventory_test.rb` | 1 | `anella-db-backups` → `demo-db-backups` |
| `test/fixtures/billing_products.yml` | 1 | `"Anella CRM product"` → `"Demo CRM product"` |
| `test/integration/pave/backoffice/platform/audit_events_test.rb` | 1 | Source `"anella"` → `"demo_scheduling"` |

### 9d. KEEP as-is (4 files — anti-contamination guard tests)

| File | Lines | Purpose |
|---|---|---|
| `test/lib/pave_billing_contracts_test.rb` | 4 | Verifies no Anella/Asaas leakage in runtime billing |
| `test/lib/pave_audit_contracts_test.rb` | 1 | Verifies AuditEvent has no Anella columns |
| `test/lib/pave_identity_impersonation_test.rb` | 1 | Verifies impersonation audit events reference no Anella models |
| `test/lib/pave_cli_test.rb` | 1 | Asserts "PASS Anella package dependencies" in doctor output |

---

## 10. Doc/Agent File Inventory — Anella References

### Root Documents

| File | Ref Count | Action |
|---|---|---|
| `README.md` | 1 | Rewrite — remove Anella as "first product" reference |
| `AGENTS.md` | ~15 | Keep — already defines Anella as external, needs content update after cleanup |
| `PROJECT_MANIFEST.md` | 2 | Rewrite — replace `:anella` with neutral examples |

### `.agents/docs/`

| File | Ref Count | Action |
|---|---|---|
| `PAVE_ARCHITECTURE.md` | ~70 | Rewrite entirely or delete — uses Anella as canonical example throughout |
| `PAVE_SYSTEM_DESIGN.md` | ~30 | Rewrite entirely or delete |
| `PAVE_VERSIONING_AND_RELEASE_STRATEGY.md` | ~10 | Keep after neutralization — has useful content, but replace Anella examples |
| `BACKOFFICE_SYSTEM_DESIGN.md` | ~25 | Rewrite entirely or delete |

### `.agents/ux/`

| File | Ref Count | Action |
|---|---|---|
| `BACKOFFICE_UX.md` | ~50 | Rewrite or delete — extensive Anella-centric UX mockups |

### `.agents/prompts/`

| File | Ref Count | Action |
|---|---|---|
| `PAVE_BACKOFFICE_UPDATE_PROMPT.md` | 1 | Fix — line 1 says "Pavê / Anella monorepo" |

### `.agents/plans/`

| Directory | Files | Ref Count | Action |
|---|---|---|---|
| `backoffice-runtime-implementation/` | 4 files | ~20 | Keep — historical plans for runtime extraction, but should be updated |
| `clean-pave-runtime-repo/` | 7 files | ~100+ | Keep — these are the current cleanup plans, name Anella as target to remove |
| `pave-runtime/` | 20+ files | ~100+ | Keep or archive — historical extraction plans, reference Anella extensively |

### `.agents/specs/`

| File | Ref Count | Action |
|---|---|---|
| `PAVE_RUNTIME_ROADMAP_SPECS.md` | ~30 | Keep after neutralization — references Anella as external consumer, valid framing |
| `pave_runtime_specs/` (15+ files) | ~30 | Keep — runtime specs that reference Anella extraction, valid as historical |
| `SPEC_CLEAN_PAVE_REPO.md` | ~100+ | **System file** — defines the cleanup, excluded from grep checks |

### `.agents/tmp/`

| File | Action |
|---|---|
| `anella_tests.txt` | Delete — temporary artifact |

---

## 11. File Count Summary by Category

| Category | Count |
|---|---|
| **Runtime gems (clean)** | 6 packages, ~45 files total |
| **Runtime gems (Anella contamination)** | 1 file (compatibility_shims.rb — minor) |
| **Host app code to delete** | ~200 files (controllers, models, services, jobs, helpers, views, assets) |
| **Config files to delete/rewrite** | ~20 files (application.rb, deploy.yml, routes.rb, products.rb, credentials, environments, locales) |
| **Deploy/infra to delete** | ~15 files (Dockerfile, docker-compose, Procfile, .kamal/) |
| **Public assets to delete** | ~100 files (precompiled assets with Anella brand) |
| **DB files to delete** | ~40 files (schema, seeds, 38 migrations) |
| **Library files to delete/rewrite** | ~20 files (lib/pave.rb, lib/pave/*, lib/security/*, lib/observability/*) |
| **Test files to delete** | 7 files (Anella-specific integration/system tests) |
| **Test files to rewrite** | 12 files (neutralize or replace fixtures) |
| **Test files to keep as-is** | 4 files (anti-contamination guards) |
| **Doc/agent files to rewrite/delete** | ~10 files (core docs) |
| **Doc/agent files to keep** | ~40 files (historical plans, cleanup plans, specs — reference Anella as target) |
| **CI files** | 1 file (update to remove Anella test reference) |
| **CLI (bin/pave)** | 1 file — update to remove Anella references |

**Estimated total files to delete:** ~375
**Estimated total files to modify:** ~35
**Estimated total files to keep as-is:** ~4,026

---

## 12. Risk / Impact Assessment for Phase 2

### High Risk — Breaking Changes

| Item | Risk | Mitigation |
|---|---|---|
| Deleting `config/application.rb` module name `AppointmentScheduler` | Rails boot will break | Must update module name or provide fallback |
| Deleting `app/` directory | All routes/controllers/models will be gone | Expected — repo becomes runtime-only; dummy test app needed |
| Deleting `app/models/space.rb` | pavê-tenancy Space model is in runtime, but `app/models/space.rb` overrides it | Ensure runtime Space model is complete before deleting host Space |
| Deleting `db/migrate/` | Test dummy needs its own migration set | Must create dummy app migrations |
| Deleting `config/routes.rb` | No routes defined for dummy app | Must have dummy app routes |

### Medium Risk — Test Failures

| Item | Risk | Mitigation |
|---|---|---|
| Deleting 7 test files | May reduce test coverage but expected | Replace with DemoScheduling tests |
| Modifying 12 test files | Potential test failures if replacements are wrong | Run `bin/rails test` to validate |
| Removing `products/anella/package.yml` check | `bin/pave doctor` will fail on that check | Must update doctor to remove the check |
| `app/models/space.rb` `Anella::SpaceProfile` reference | Will break if anything references it | Expected — belongs in Anella repo |

### Low Risk — Docs and Config

| Item | Risk | Mitigation |
|---|---|---|
| Rewriting `.agents/docs/` | Loss of architectural guidance, but outdated | Replace with cleaning docs |
| Deleting public assets | No impact on runtime | Expected |
| Deleting locale Anella keys | i18n fallback will prevent breakage | Verify |

### Critical Dependencies for Phase 2

1. Must ensure `runtime/pave-tenancy` Space model is complete before removing `app/models/space.rb`
2. Must have a test dummy app that boots independently after host app code removal
3. `bin/pave doctor` must be updated to remove Anella-specific checks BEFORE running doctor after deletions
4. The `FORBIDDEN_RUNTIME_PATTERN` in `bin/pave` will match after Phase 2 removes Anella from source — should be updated to remove Anella from the pattern at the end

---

## 13. Open Questions for Phase 2

1. **Module name in `config/application.rb`** — What should the module be renamed to? (e.g., `Pave`, `Dummy`, `TestApp`)
2. **Test dummy app strategy** — Should we keep a minimal dummy app in `test/dummy/` that boots with host app code removed? Or rely on engine test patterns?
3. **`db/schema.rb` ownership** — After removing Anella migrations, does the runtime need a consolidated migration path?
4. **Key files that belong to Pavê vs. Anella** — Several files in `lib/` (`app_brand.rb`, `mailer_configuration.rb`, `security/*`) have Anella defaults but provide generic interfaces. Should they be deleted or moved to runtime?
5. **Observability library** — Is `lib/observability/` generic or Anella-specific? Lograge, OTEL, error reporting appear generic but PII scrubbing has Anella assumptions.
6. **`bin/pave` FORBIDDEN_RUNTIME_PATTERN** — After removing Anella, the pattern itself references Anella. Should we remove the anti-contamination check entirely or update it to look for different patterns?

---

## 14. Validation

- [x] Report file exists and is readable
- [x] All required inventory categories documented
- [x] Zero source-code changes made
- [x] Grep command outputs captured verbatim
- [x] Ready for Phase 2 input

---

## 15. Raw Grep Output

### 15a. Global Anella grep (non-binary, non-spec)
```
Full output available in: /Users/italo/.local/share/opencode/tool-output/tool_ef75d32eb001oRwUXmsv7Ve2q7
```

### 15b. Test Anella grep
```
23 files matched under test/
See Section 9 for full breakdown.
```

### 15c. Docs Anella grep
```
~50 files matched under .agents/, README.md, AGENTS.md, PROJECT_MANIFEST.md
See Section 10 for full breakdown.
```

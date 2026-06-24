# Phase 7 — External Consumer Validation

## Goal

Validate that a Pavê host app can consume the runtime via local path and internal Git tag dependency modes, without embedding runtime source inside the app.

## Approach

1. Document the consumer contract in `docs/host_app_consumption.md`
2. Build a temporary Rails host app at `/Users/italo/workspace/elos-workspace/pave-smoke-host/` (outside the Pavê repo)
3. Fix runtime bugs exposed by external consumption
4. Validate local path mode (`gem "pave", path: "..."`)
5. Validate Git tag mode (`gem "pave", git: "...", tag: "...", glob: "..."`)

## Repository Changes

### Bug Fix: Pave::Product and Pave::ProductRegistry moved into pave-core

These classes were at `lib/pave/product.rb` and `lib/pave/product_registry.rb` — host-app-level files in `lib/pave/`, not inside any gem. External host apps don't have these files. Moved into `gems/pave-core/lib/pave/core/product.rb` and `gems/pave-core/lib/pave/core/product_registry.rb`, and `require`'d from `pave/core.rb`.

### Bug Fix: Missing module-level methods on Pave

`Pave.product`, `Pave.products`, `Pave.backoffice`, and other convenience methods were defined in `lib/pave.rb` (host-app level). Moved into `gems/pave-core/lib/pave/core.rb` so gem consumers can access them.

### Bug Fix: Missing Bundler auto-require entry point files

Ruby gems named `X` must have `lib/X.rb` for Bundler to auto-require. None of the gems had this. Added:
- `gems/pave-core/lib/pave-core.rb`
- `gems/pave-rails/lib/pave-rails.rb`
- `gems/pave-tenancy/lib/pave-tenancy.rb`
- `gems/pave-identity/lib/pave-identity.rb`
- `gems/pave-audit/lib/pave-audit.rb`
- `gems/pave-billing/lib/pave-billing.rb`
- `gems/pave-backoffice/lib/pave-backoffice.rb`

Each file simply does `require "pave/<module>"`.

### Git tag support

- Tag `v0.1.0-internal` updated to point to HEAD for Git tag validation.
- Bundler 4.0.6 does **not** forward `glob` from per-gem declarations inside a `git` block. Workaround: use per-gem `git:` option with `glob:` instead.

## Validation Results

### Local Path Mode

| Test | Result |
|---|---|
| `bundle install` | ✅ |
| `bin/rails runner "puts Pave::VERSION"` | ✅ `0.1.0` |
| `bin/rails runner "puts Pave.products.class"` | ✅ `Pave::ProductRegistry` |
| `bundle exec pave doctor` | ✅ API checks pass |
| `bundle exec pave context` | ✅ |
| `bin/rails db:create db:migrate` | ✅ |
| `bundle exec ruby -e "require 'pave'; puts Pave::VERSION"` | ✅ (Bundler 4.x needs explicit `require`) |

### Git Tag Mode (v0.1.0-internal)

| Test | Result |
|---|---|
| `bundle install` with per-gem `git:` + `glob:` | ✅ |
| `bin/rails runner "puts Pave::VERSION"` | ✅ `0.1.0` |
| `bin/rails runner "puts Pave.products.class"` | ✅ `Pave::ProductRegistry` |
| `bundle exec pave doctor` | ✅ All require + API checks PASS |
| `bundle exec pave context` | ✅ |
| `bundle exec ruby -e "require 'pave'; puts Pave::VERSION"` | ✅ (Bundler 4.x needs explicit `require`) |

### Expected Doctor FAILs

Some `pave doctor` checks are designed for internal development and correctly report FAIL in external consumption:
- `gems directory` — no local `gems/` in host app
- `package files` — no Packwerk `package.yml` files in host app  
- `Rails boot` — tries to load gem's `config/environment` path (not host app's)
- Packwerk-related — `packwerk` not in host app's Gemfile

## Bundler 4.0.6 Observations

- `bundle exec` does **not** auto-require gems. You must explicitly `require "gem_name"`.
- `bin/rails runner` handles the require chain automatically (Rails initializes -> loads `pave-rails` engine -> loads `pave-core` -> etc.)
- Path sources and git sources behave identically in this regard.

## Files Changed

| File | Change |
|---|---|
| `gems/pave-core/lib/pave/core.rb` | Added `require "pave/core/product"`, `require "pave/core/product_registry"`, `Pave.product`, `Pave.products`, `Pave.backoffice`, etc. |
| `gems/pave-core/lib/pave/core/product.rb` | New file (moved from `lib/pave/product.rb`) |
| `gems/pave-core/lib/pave/core/product_registry.rb` | New file (moved from `lib/pave/product_registry.rb`) |
| `lib/pave.rb` | Simplified — removed methods now provided by `pave-core` |
| `gems/pave-core/lib/pave-core.rb` | New — Bundler entry point |
| `gems/pave-rails/lib/pave-rails.rb` | New — Bundler entry point |
| `gems/pave-tenancy/lib/pave-tenancy.rb` | New — Bundler entry point |
| `gems/pave-identity/lib/pave-identity.rb` | New — Bundler entry point |
| `gems/pave-audit/lib/pave-audit.rb` | New — Bundler entry point |
| `gems/pave-billing/lib/pave-billing.rb` | New — Bundler entry point |
| `gems/pave-backoffice/lib/pave-backoffice.rb` | New — Bundler entry point |
| `docs/host_app_consumption.md` | New — consumer contract documentation |

## Open Issues

- Anella sibling repo (`/Users/italo/workspace/elos-workspace/anella/`) was not available for validation. Procedure documented instead.
- `repo-check-clean` script self-matches and also matches `AGENTS.md` and `cli.rb` which contain intentional Anella references. Needs fixing.
- `build-gems` script not yet created.

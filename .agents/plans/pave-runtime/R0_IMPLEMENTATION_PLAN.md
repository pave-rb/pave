# R0 — Monorepo Scaffold Implementation Plan

## 1. Purpose

Establish the internal runtime/package skeleton that can load inside the current Rails app without moving business logic or changing Anella behavior.

## 2. Preconditions

- Anella product extraction is present under `products/anella`.
- Record baseline `git status --short` before editing.
- Current app boot is checked with `bundle exec rails zeitwerk:check`.
- Current test baseline is checked with `bin/rails test test products/anella/test`.
- Note that `bin/pave` and Packwerk do not currently exist before R0.

## 3. Non-goals

- Do not move `Space`, `User`, audit, billing, backoffice, Anella, WhatsApp, or Asaas code.
- Do not change application routes, product routes, migrations, models, controllers, views, or behavior except mechanical runtime load wiring.
- Do not enable strict Packwerk dependency/privacy enforcement.
- Do not convert products/plugins into engines.
- Do not publish gems.

## 4. Repo observations

- Root Rails app uses Rails 8.1, Minitest, Devise, importmap, Turbo, Solid adapters, and product boot from `lib/pave.rb`.
- `products/anella` exists with `product.yml`, `package.yml`, routes, app code, and tests in legacy constants mode.
- Existing `lib/pave/*` already provides product and backoffice registries used by `config/application.rb`, `config/products.rb`, and `config/routes.rb`.
- No `runtime/`, `plugins/`, `bin/pave`, Packwerk config, or `.github/workflows` directory exists.
- `spec/` is empty; tests live under `test/` and `products/anella/test/`.

## 5. Planned changes

### Runtime/package structure

- Add `runtime/pave-core`, `runtime/pave-tenancy`, `runtime/pave-audit`, `runtime/pave-identity`, `runtime/pave-billing`, and `runtime/pave-backoffice`.
- Add `plugins/.keep`.
- In each runtime package, add `<pkg>.gemspec`, `lib/pave/<name>.rb`, `lib/pave/<name>/version.rb`, `lib/pave/<name>/engine.rb`, `package.yml`, and `README.md`.
- Keep each engine empty/minimal: define namespace, version, and `Rails::Engine` isolation/loading only.
- Set each runtime `package.yml` to advisory mode: `enforce_dependencies: false`, `enforce_privacy: false`.

### Rails integration

- Add path gem entries for runtime packages to `Gemfile` only after verifying each package loads in development/test.
- Require runtime packages from the host app without replacing the existing `lib/pave` product registry yet.
- Preserve `config/application.rb` product boot order so `Pave::ProductBoot.apply!(config)` still works.

### Services/commands

- Add executable `bin/pave` with `help`, `doctor`, and `version` commands.
- Implement R0 `doctor` checks for runtime directory, expected packages, package requires, Rails boot, and Packwerk availability.
- Report later-phase checks as `skipped`, not failures.

### Tests

- Add minimal command tests if the repo has a lightweight pattern for executable tests; otherwise add a small Minitest under `test/lib` or `test/commands` for `bin/pave help/version/doctor` behavior.
- Do not add RSpec unless the repo already starts using it.

### CI/tooling

- Inspect existing CI before editing. No `.github/workflows` directory exists now.
- If CI exists elsewhere, add `bundle exec rails zeitwerk:check`, `bin/pave doctor`, `bin/rails test test products/anella/test`, and advisory `bundle exec packwerk check` only if Packwerk is installed.
- If no CI exists, document the local validation command set in the R0 handoff instead of inventing a full workflow.
- Add Packwerk gem/config only in advisory mode if it installs cleanly with the current bundle.

### Documentation/agent context

- Add a short R0 handoff doc only if the implementation workflow needs a phase summary file; otherwise put the required handoff in the commit body.

## 6. Public contracts introduced or changed

- Runtime package directories under `runtime/pave-*`.
- Plugin root directory `plugins/`.
- `bin/pave help`.
- `bin/pave doctor`.
- `bin/pave version`.
- Advisory `package.yml` files for runtime packages and `products/anella`.
- Existing `Pave.products` and `Pave.backoffice` contracts remain unchanged in R0.

## 7. Migration strategy

R0 is additive only.

- Source location: none; no runtime/domain code moves.
- Target location: new `runtime/` packages and `plugins/` root.
- Compatibility shim: keep existing `lib/pave.rb` and `lib/pave/*` behavior intact.
- Deletion timing: no deletions in R0.

## 8. Anti-contamination checks

- Runtime package skeletons must not mention Anella, appointments, CRM, WhatsApp, Asaas, salons, clinics, booking, or product pricing.
- `bin/pave doctor` must check package presence, not product behavior.
- `plugins/` must stay empty except `.keep`.
- Any product registration remains in existing product boot/config code, not in runtime package skeletons.

## 9. Validation commands

```bash
git status --short
bundle install
bundle exec rails zeitwerk:check
bin/pave help
bin/pave version
bin/pave doctor
bin/rails test test products/anella/test
bundle exec packwerk check
```

If Packwerk is not installed in R0, `bin/pave doctor` must report Packwerk as skipped/advisory and the handoff must explain why `bundle exec packwerk check` was not run.

## 10. Commit plan

```txt
1. R0: add runtime package skeletons
2. R0: wire runtime path gems safely
3. R0: add bin/pave doctor commands
4. R0: document advisory package checks
```

## 11. Handoff criteria

- App boots with runtime packages present.
- `bin/pave help`, `bin/pave version`, and `bin/pave doctor` run successfully.
- Test suite remains green with Anella product tests included.
- R0 handoff states path-gem versus autoload strategy, CI status, doctor active/skipped checks, and Packwerk advisory/enforcing status.
- No Anella behavior or product code changed.

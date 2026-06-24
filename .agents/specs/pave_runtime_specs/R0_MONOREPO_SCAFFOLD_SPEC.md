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

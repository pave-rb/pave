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

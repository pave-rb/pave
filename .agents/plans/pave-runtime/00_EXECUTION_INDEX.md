# Pavê Runtime Execution Index

## Phase order

1. R0 — Monorepo scaffold
2. R1 — `pave-core`
3. R2 — `pave-tenancy`
4. R3 — `pave-audit`
5. R4 — `pave-identity`
6. R5 — `pave-billing`
7. R6 — `pave-backoffice`
8. R7 — Packwerk enforcement ON

R1 must not start until R0 boots cleanly and CI/local validation is green.

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

## Stop/go gates

- Stop before every phase if `git status --short` shows unrelated changes in files the phase must edit.
- Stop R0 if the app does not boot before scaffolding; record the baseline failure first.
- Stop R1 unless R0 added the runtime skeleton, `bin/pave doctor` exists, and boot/tests are green.
- Stop R4 and R5 unless R3 exposes a stable `Pave::Audit.log!` interface.
- Stop R6 unless R1-R5 public APIs and compatibility shims are available.
- Stop R7 unless all expected package boundaries and cleanup items are identified.

## Expected generated plan files

- `.agents/plans/pave-runtime/00_EXECUTION_INDEX.md`
- `.agents/plans/pave-runtime/R0_IMPLEMENTATION_PLAN.md`
- `.agents/plans/pave-runtime/R1_IMPLEMENTATION_PLAN.md`
- `.agents/plans/pave-runtime/R2_IMPLEMENTATION_PLAN.md`
- `.agents/plans/pave-runtime/R3_IMPLEMENTATION_PLAN.md`
- `.agents/plans/pave-runtime/R4_IMPLEMENTATION_PLAN.md`
- `.agents/plans/pave-runtime/R5_IMPLEMENTATION_PLAN.md`
- `.agents/plans/pave-runtime/R6_IMPLEMENTATION_PLAN.md`
- `.agents/plans/pave-runtime/R7_IMPLEMENTATION_PLAN.md`
- `.agents/plans/pave-runtime/LATER_VALIDATION_PLAN.md`

## Highest-risk decisions

- Whether `runtime/pave-core` owns the existing `lib/pave` product boot/registry immediately or through a temporary root `lib/pave.rb` shim.
- How to split the overloaded `spaces` table without losing Anella booking, scheduling, inbox, CRM, WhatsApp, and onboarding data.
- How to introduce generic audit events while preserving existing `AuditLog` backoffice behavior and fingerprints.
- How much of Devise-backed `User` is generic identity versus Anella/legal/provider profile data.
- How to extract billing without carrying Asaas columns, WhatsApp quota, appointment features, or Anella pricing into `pave-billing`.

## Known cleanup backlog

- `app/models/space.rb` currently mixes generic tenancy with Anella booking, appointment, CRM, inbox, WhatsApp, and vertical fields.
- `app/models/user.rb` currently mixes identity with product associations and Brazilian legal/provider fields such as `cpf_cnpj`.
- `app/services/audit_logs/event_logger.rb` references `Customer`, which is product-owned and must not enter `pave-audit`.
- `app/models/billing/*` and `products/anella/app/services/billing/*` currently share legacy `Billing::*` constants; runtime should introduce `Pave::Billing::*` and compatibility facades deliberately.
- Packwerk is not currently installed/configured; R0 should introduce advisory package files, and R7 should enforce them.
- No `.github/workflows` directory is present; R0 must inspect the actual CI mechanism before adding CI changes.

## Commands to run after each phase

Use the repo-local command set that exists at that phase. Do not silently skip missing commands; explain the replacement or skipped status.

```bash
git status --short
bundle exec rails zeitwerk:check
bin/pave doctor
bin/rails test test products/anella/test
bundle exec packwerk check
```

Before R0, `bin/pave` and Packwerk are absent in the current repo, so the implementation agent should record that baseline and use `bundle exec rails zeitwerk:check` plus `bin/rails test test products/anella/test` as the nearest existing validation.

## Boundary rule

Runtime packages may contain only generic runtime concepts. Anella, appointments, CRM, WhatsApp, Asaas, salons, clinics, booking copy, and product-specific backoffice panels must remain in `products/anella` or later plugin/product packages.

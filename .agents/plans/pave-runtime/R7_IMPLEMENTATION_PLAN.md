# R7 — Packwerk Enforcement ON Implementation Plan

## 1. Purpose

Turn the runtime package structure into enforced architecture by enabling dependency and privacy checks after R0-R6 have identified and cleaned package boundaries.

## 2. Preconditions

- R0 through R6 are complete and green.
- Runtime packages boot and expose deliberate public APIs.
- Anella behavior remains green.
- Packwerk is installed/configured in advisory mode from R0 or is added before enforcement in this phase.

## 3. Non-goals

- Do not add runtime features.
- Do not refactor behavior for aesthetics.
- Do not expose entire models/controllers just to silence violations.
- Do not weaken runtime boundaries to make Anella tests pass.
- Do not disable tests or Packwerk checks.

## 4. Repo observations

- Current repo has `products/anella/package.yml` with `enforce_dependencies: false` and `enforce_privacy: false`.
- Current repo has no root Packwerk config before R0.
- R0-R6 should have created runtime package files and compatibility shims; R7 should remove or isolate invalid dependencies.
- Known high-risk packages are tenancy, identity, billing, and backoffice because their current source code had product/provider references.

## 5. Planned changes

### Runtime/package structure

- Enable dependency/privacy enforcement in every runtime `package.yml` where supported.
- Declare package dependencies exactly according to the roadmap graph.
- Update `products/anella/package.yml` to depend on runtime packages through public APIs.
- Create public API folders/files if the chosen Packwerk convention requires them.

### Rails integration

- Ensure root app package boundaries are explicit if Packwerk requires a root package.
- Keep compatibility shims only where they do not create forbidden reverse dependencies.

### Models/migrations

- Do not add migrations unless required to remove a boundary leak already identified in R2-R6.
- Do not drop compatibility columns as part of enforcement unless a prior phase already made them unused and tested.

### Controllers/routes

- Ensure runtime controllers do not depend on product controllers/routes.
- Ensure product controllers depend on runtime public controllers/services only.

### Services/commands

- Extend `bin/pave doctor` boundary checks: package presence, dependency graph, reverse dependency violations, forbidden product references, and Packwerk enforcement status.
- Add a small boundary validation script only if Packwerk cannot express one of the anti-contamination checks.

### Tests

- Add checks for no Anella constants in runtime, no product dependencies from runtime, dependency graph match, doctor boundary status, and Packwerk green state.

### CI/tooling

- Make CI fail on `bundle exec packwerk check`, `bin/pave doctor`, `bundle exec rails zeitwerk:check`, and `bin/rails test test products/anella/test`.
- Do not allow advisory-only Packwerk after R7.

### Documentation/agent context

- Document public API surfaces by package and any remaining cleanup backlog.

## 6. Public contracts introduced or changed

- Enforced package dependency graph:
  - `runtime/pave-core`: no runtime deps.
  - `runtime/pave-tenancy`: `runtime/pave-core`.
  - `runtime/pave-audit`: `runtime/pave-core`, `runtime/pave-tenancy`.
  - `runtime/pave-identity`: `runtime/pave-core`, `runtime/pave-tenancy`, `runtime/pave-audit`.
  - `runtime/pave-billing`: `runtime/pave-core`, `runtime/pave-tenancy`, `runtime/pave-audit`.
  - `runtime/pave-backoffice`: all previous runtime packages.
  - `products/anella`: runtime packages only through public APIs.
- Packwerk public API folders/files according to the repo convention chosen in R0/R7.
- `bin/pave doctor` boundary checks become part of the public local validation contract.

## 7. Migration strategy

R7 is enforcement-only plus cleanup of boundary violations.

- Source location: all runtime package `package.yml` files, `products/anella/package.yml`, root Packwerk config, CI config, and compatibility shims from R1-R6.
- Target location: enforced package config and public API files.
- Compatibility shim: keep only shims that obey dependency direction and privacy rules.
- Deletion timing: delete invalid shims during R7; defer data/column cleanup to a separate post-R7 cleanup if not required for enforcement.

## 8. Anti-contamination checks

- Runtime packages must have no references to `Anella`, appointments, customers, CRM, WhatsApp, Asaas, booking, salon, clinic, or Anella-specific pricing copy.
- Runtime packages must not depend on `products/anella` or plugin packages.
- Anella may depend on runtime public APIs only.
- Do not make private runtime internals public unless another package genuinely needs a stable public contract.

## 9. Validation commands

```bash
git status --short
bundle exec rails zeitwerk:check
bin/pave doctor
bundle exec packwerk check
bin/rails test test products/anella/test
grep -R "Anella\|Appointment\|Customer\|Whatsapp\|WhatsApp\|Asaas\|booking\|clinic\|salon\|CRM" runtime || true
```

## 10. Commit plan

```txt
1. R7: declare runtime package dependencies
2. R7: expose deliberate public APIs
3. R7: resolve Packwerk boundary violations
4. R7: enforce Packwerk in doctor and CI
5. R7: document final boundary backlog
```

## 11. Handoff criteria

- Packwerk dependency and privacy enforcement are on.
- `bundle exec packwerk check` is green.
- CI/local validation fails on new boundary violations.
- Runtime packages do not depend on Anella or product internals.
- Handoff lists final dependency graph, public API surfaces, cleanup backlog, and validation output summary.

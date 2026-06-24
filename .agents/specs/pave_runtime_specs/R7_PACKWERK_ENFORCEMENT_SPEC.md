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

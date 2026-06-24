# Later L8 — Kamal Deploy Templates Specification

## Intent

Provide reusable deployment templates for Pavê apps while preserving project-specific deploy control.

## Dependencies

- R0 through R7 complete.
- Runtime layout stable.
- Existing Anella deployment remains working.

## Outcome

Pavê has deploy templates and validation commands for Kamal-based deployments.

## Scope

Create:

```text
ops/deploy/kamal/config/deploy.yml.example
ops/deploy/kamal/secrets.example
ops/deploy/kamal/hooks/*
bin/pave deploy doctor
```

`bin/pave deploy doctor` should validate:

- required env vars exist
- image registry config present
- database accessory config present if used
- secrets file references expected keys
- app boots in production-like mode where feasible
- runtime packages are eager-loadable

## Non-goals

- Do not replace Kamal.
- Do not force one hosting provider.
- Do not expose secrets.
- Do not break existing Anella deploy.

## Acceptance criteria

- Templates are usable but opt-in.
- Existing deploy remains unchanged unless explicitly migrated.
- Deploy doctor catches missing credentials/config early.
- Docs explain how product packages and runtime packages are loaded in production.

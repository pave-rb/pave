# Later L4 — Agent Context Files Specification

## Intent

Generate and maintain concise architecture context files so AI coding agents can work inside Pavê without hallucinating boundaries.

## Dependencies

- R0 through R7 complete.
- `bin/pave context` available or planned.
- Runtime registry can inspect packages/plugins/panels/capabilities/events.

## Outcome

Each module/package has a concise `CONTEXT.md`; root has an `AGENT_CONTEXT.md` that explains the system map and active constraints.

## Files

```text
AGENT_CONTEXT.md
runtime/pave-core/CONTEXT.md
runtime/pave-tenancy/CONTEXT.md
runtime/pave-audit/CONTEXT.md
runtime/pave-identity/CONTEXT.md
runtime/pave-billing/CONTEXT.md
runtime/pave-backoffice/CONTEXT.md
products/anella/CONTEXT.md
plugins/*/CONTEXT.md
```

Each file should be 100–200 lines maximum.

## Required sections

Each context file should include:

```text
Purpose
Public APIs
Owned models/controllers/services
Forbidden dependencies
Common extension points
Validation commands
Known traps
```

## Generation strategy

Use `bin/pave context` to generate or refresh context. Generated sections must be marked. Hand-written constraints may be preserved.

## Acceptance criteria

- Context files exist and are accurate.
- Agent can identify where code belongs before implementing.
- Context does not duplicate huge docs.
- Context is grounded in actual registry/package data.

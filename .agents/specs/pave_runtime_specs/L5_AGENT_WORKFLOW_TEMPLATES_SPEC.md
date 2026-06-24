# Later L5 — Agent Workflow Templates Specification

## Intent

Create repeatable local-agent workflows for common Pavê changes so implementation remains bounded and contract-aware.

## Dependencies

- R0 through R7 complete.
- Agent context files available or planned.
- `bin/pave generate workflow` available or planned.

## Outcome

Pavê ships workflow templates that agents can execute with fewer boundary mistakes.

## Initial templates

```text
add-billing-gate
new-job
extract-service
new-module-panel
add-plan-feature
add-audit-event
add-plugin-capability
```

## Template format

Each template should include:

```text
Goal
Inputs required
Files likely touched
Forbidden files/packages
Validation commands
Commit message format
Handoff checklist
```

## Non-goals

- Do not make natural language executable architecture.
- Do not let templates bypass specs or tests.
- Do not generate broad features from vague prompts.

## Acceptance criteria

- Templates are short and practical.
- Each template references package boundaries.
- Each template tells the agent what not to touch.
- Templates can be listed by `bin/pave generate workflow --list` or equivalent.

# Later L2 — Full `bin/pave` CLI Specification

## Intent

Turn `bin/pave` from a scaffold/doctor command into the developer interface for inspecting and maintaining the runtime.

## Dependencies

- R0 through R7 complete.
- Runtime registry stable.
- Package boundaries enforced.

## Outcome

`bin/pave` can explain the runtime, validate architecture, generate bounded artifacts, and export agent context.

## Commands

Required commands:

```bash
bin/pave help
bin/pave version
bin/pave doctor
bin/pave context
bin/pave explain
bin/pave packages
bin/pave products
bin/pave plugins
bin/pave routes
bin/pave audit boundaries
bin/pave generate workflow <name>
```

Future commands:

```bash
bin/pave generate module <name>
bin/pave generate resource <name> --tenant-scoped
bin/pave generate backoffice-panel <name>
bin/pave deploy doctor
```

## Design rules

- CLI must load Rails only when required.
- Pure metadata commands should be fast.
- Output should support human-readable and machine-readable formats where useful.
- Do not mutate files unless command name implies generation.
- Every mutating command must print changed file list.

## Acceptance criteria

- `bin/pave doctor` is the canonical local architecture validation command.
- `bin/pave context` produces agent-readable context.
- `bin/pave explain` gives package/product/plugin map.
- Commands fail with clear `Pave::Error` codes.

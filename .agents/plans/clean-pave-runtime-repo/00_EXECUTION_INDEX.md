# Clean Pavê Runtime Repository — Execution Index

## 1. Objective

Transform the current copied Pavê/Anella repository into the clean **Pavê runtime source monorepo** (`pave-rb/pave`).

The resulting repository must:

- Produce Pavê runtime gems, Rails engines, CLI tooling, generators, and upgrade tasks.
- Contain no Anella product code, credentials, deployment config, routes, views, models, services, jobs, assets, branding, WhatsApp integrations, or billing provider adapters.
- Be shaped as a gem distribution source monorepo, not as a deployable Rails host app.
- Use neutral test fixtures (`DemoScheduling`) where runtime contract tests need a product-shaped example.

## 2. Source spec

The cleanup is driven by:

```txt
.agents/specs/SPEC_CLEAN_PAVE_REPO.md
```

Read that spec fully before starting any phase.

## 3. Non-goals

Do **not** do these during this cleanup:

- Publish gems to RubyGems.
- Create one repository per gem.
- Build a plugin marketplace or hosting/launcher/orchestrator.
- Implement a full resource/action DSL unless it is already close to complete.
- Move Anella business logic into Pavê.
- Preserve Anella examples "temporarily."
- Build a public docs site.
- Deploy the runtime repo independently.

## 4. Phase list

| Phase | File | Purpose |
|---|---|---|
| 1 | [`01-boundary-inventory.md`](01-boundary-inventory.md) | Map what currently exists before deleting or moving anything. |
| 2 | [`02-remove-product-contamination.md`](02-remove-product-contamination.md) | Remove or externalize all product-specific and Anella-specific code. |
| 3 | [`03-runtime-gem-layout.md`](03-runtime-gem-layout.md) | Move runtime code to the target `gems/` layout and fix gem boundaries. |
| 4 | [`04-dummy-product-and-tests.md`](04-dummy-product-and-tests.md) | Replace Anella-dependent tests with neutral `DemoScheduling` fixtures. |
| 5 | [`05-cli-generators-context.md`](05-cli-generators-context.md) | Generalize `bin/pave`, generators, and agent context surfaces. |
| 6 | [`06-release-and-ci-skeleton.md`](06-release-and-ci-skeleton.md) | Add release scripts and CI gates for cleanliness and build validation. |
| 7 | [`07-external-consumer-validation.md`](07-external-consumer-validation.md) | Prove an external host app can consume Pavê by path and by Git tag. |

## 5. Execution order

Phases are ordered and must run sequentially. A future coding agent should implement **exactly one phase at a time**.

Before starting a phase:

1. Read the source spec (`SPEC_CLEAN_PAVE_REPO.md`).
2. Read this execution index.
3. Read the phase file for the phase you are implementing.
4. Read the phase file for the previous phase to understand expected inputs.

After completing a phase:

1. Run the validation commands listed in the phase file.
2. Update this index with a brief status note if desired (optional).
3. Hand off to the next phase.

## 6. Global invariants

The following invariants must hold from the end of Phase 2 onward and remain true for all later phases:

1. **No Anella references in runtime code, tests, docs, generators, templates, or examples.**
   - Use this command to verify:
     ```bash
     grep -R "Anella\\|anella\\|ANELLA" . \
       --exclude-dir=.git \
       --exclude='SPEC_CLEAN_PAVE_REPO.md'
     ```
   - Generated historical reports and the spec file itself may be excluded, but nothing else.
2. **Runtime packages must not depend on products or plugins.**
3. **Pavê-core must not depend on Rails.**
4. **All Pavê gems share the same version (lockstep versioning).**
5. **The repository is not a host app and does not contain product application code.**
6. **All existing tests that are kept must pass after each phase.**
7. **Prefer deletion over speculative generalization.**
8. **When in doubt, code belongs outside Pavê (i.e., in the external Anella repo or a future host app).**

## 7. Final exit criteria

The cleanup is complete when all of the following are true:

1. `grep -R "Anella\\|anella\\|ANELLA" . --exclude-dir=.git --exclude='SPEC_CLEAN_PAVE_REPO.md'` returns no forbidden references.
2. All runtime packages live under `gems/`.
3. Every gem has a valid gemspec.
4. The meta-gem `gems/pave` exists.
5. Runtime tests pass without Anella.
6. Backoffice boots with zero products installed.
7. `test/dummy/products/demo_scheduling/` validates product boot.
8. `scripts/build-gems` builds all gems.
9. `bin/pave doctor` runs without assuming Anella.
10. `bin/pave context` describes Pavê runtime, not Anella.
11. An external host app can consume Pavê by local path.
12. An external host app can consume Pavê by internal Git tag.

## 8. Validation commands

Run these commands after each phase where they are applicable. Missing commands may be skipped until they are implemented.

```bash
# Hard cleanliness check
bin/pave repo:check-clean
# or, until repo:check-clean exists:
grep -R "Anella\\|anella\\|ANELLA" . --exclude-dir=.git --exclude='SPEC_CLEAN_PAVE_REPO.md'

# Test suite
bundle exec rake test

# Static analysis
bundle exec rubocop
bundle exec packwerk check
bundle exec packwerk validate

# Runtime doctor
bin/pave doctor

# Gem build (after Phase 6)
scripts/build-gems

# Smoke install (after Phase 6)
scripts/smoke-install
```

## 9. Notes for future agents

- Implement **exactly one phase at a time**. Do not widen scope.
- Do not modify source code in this planning task. The phase files are the only deliverables here.
- When implementing a phase, keep changes minimal and package-focused.
- Do not add new architecture concepts. Use the concepts already defined in `AGENTS.md` and the source spec.
- Test fixture names must be neutral. Prefer `DemoScheduling` for realistic runtime contract tests. Acceptable alternatives: `SampleProduct`, `Acme`, `DummyProduct`.
- Do not reference Anella in commit messages, comments, variable names, i18n keys, routes, docs, or examples.
- If a file is purely Anella-specific and not reusable, delete it. Do not move it into a runtime module.
- If a runtime module currently contains Anella-shaped but potentially reusable behavior, either delete it or neutrally rename it. Do not keep Anella-specific defaults.
- Update `AGENTS.md` and any `CONTEXT.md` files when public runtime contracts change.
- The external Anella repository is assumed to exist elsewhere. Do not recreate it inside this repo.

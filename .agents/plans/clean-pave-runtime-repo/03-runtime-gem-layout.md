# Phase 3: Runtime gem layout

## Objective

Move the cleaned runtime packages from `runtime/` to the target `gems/` directory layout, add the missing meta-gem and Rails integration gem, and ensure every package has a valid gemspec and a clear gem boundary.

## Scope

- `runtime/pave-core`
- `runtime/pave-tenancy`
- `runtime/pave-identity`
- `runtime/pave-billing`
- `runtime/pave-audit`
- `runtime/pave-backoffice`
- New `gems/pave` meta-gem
- New `gems/pave-rails` Rails integration gem (placeholder or minimal implementation)
- Optional placeholder gems `gems/pave-hotwire` and `gems/pave-agent`
- Root `Gemfile`, `Rakefile`, `packwerk.yml`, and `package.yml`

## Required reading

- `.agents/specs/SPEC_CLEAN_PAVE_REPO.md` sections 5, 6, 7, 8.
- `AGENTS.md` sections 4, 5, 6.
- Results of Phase 2.

## Allowed changes

- Move directories from `runtime/<name>` to `gems/<name>`.
- Update `ROOT` or package path references in `bin/pave`, scripts, and tests.
- Update `packwerk.yml`, `package.yml` files, and gemspec paths.
- Update the root `Gemfile` to use `path:` entries under `gems/`.
- Create new gemspecs for `gems/pave`, `gems/pave-rails`, `gems/pave-hotwire`, and `gems/pave-agent`.
- Create minimal placeholder files (`lib/pave.rb`, `lib/pave/rails.rb`, version files, engine files) where needed.
- Update lockstep version constants so all gems share one version source.

## Forbidden changes

- Do not overbuild `pave-rails`, `pave-hotwire`, or `pave-agent`. If functionality does not exist, create only stubs and mark them as planned.
- Do not change runtime business logic while moving files.
- Do not introduce Anella references.
- Do not create a separate repo per gem.
- Do not publish gems.

## Step-by-step tasks

1. **Define a single version source.**
   - Create `lib/pave/version.rb` or use `gems/pave-core/lib/pave/core/version.rb` as the canonical source.
   - All gems must read the same version constant or file.

2. **Move existing runtime packages.**
   - Move `runtime/pave-core` → `gems/pave-core`
   - Move `runtime/pave-tenancy` → `gems/pave-tenancy`
   - Move `runtime/pave-identity` → `gems/pave-identity`
   - Move `runtime/pave-billing` → `gems/pave-billing`
   - Move `runtime/pave-audit` → `gems/pave-audit`
   - Move `runtime/pave-backoffice` → `gems/pave-backoffice`

3. **Update package manifests.**
   - For each moved package, update `package.yml`:
     - Update `dependencies` entries from `runtime/pave-*` to `gems/pave-*`.
     - Ensure `enforce_dependencies: true`.
   - Update root `package.yml` if it references `runtime/`.
   - Update `packwerk.yml` package paths to include `gems/*` and exclude `runtime/`.

4. **Update gemspecs.**
   - For each moved gem, update the gemspec:
     - Ensure `spec.files` includes the new paths.
     - Update `spec.version` to use the shared version source.
     - Ensure Rails dependencies are only in Rails-integrated gems (`pave-tenancy`, `pave-identity`, `pave-billing`, `pave-audit`, `pave-backoffice`).
   - Ensure `pave-core.gemspec` has **no** Rails dependency.

5. **Create the meta-gem `gems/pave/`.**
   - `gems/pave/pave.gemspec`
     - `spec.add_dependency "pave-core", version`
     - `spec.add_dependency "pave-rails", version`
     - `spec.add_dependency "pave-tenancy", version`
     - `spec.add_dependency "pave-identity", version`
     - `spec.add_dependency "pave-audit", version`
     - `spec.add_dependency "pave-backoffice", version`
     - Optional: `pave-billing` if billing is part of the default runtime.
   - `gems/pave/lib/pave.rb` requires the default gems and exposes the CLI.
   - `gems/pave/exe/pave` or `bin/pave` is wired to the gem entrypoint.

6. **Create `gems/pave-rails/` (minimal or placeholder).**
   - `gems/pave-rails/pave-rails.gemspec`
   - `gems/pave-rails/lib/pave/rails.rb`
   - `gems/pave-rails/lib/pave/rails/version.rb`
   - `gems/pave-rails/lib/pave/rails/engine.rb` (a `Rails::Engine` subclass)
   - `gems/pave-rails/lib/pave/rails/railtie.rb`
   - If an install generator already exists elsewhere, move it here. Otherwise create a stub generator.
   - Mark anything not yet implemented as `TODO(planned)`.

7. **Create placeholder gems for later work.**
   - `gems/pave-hotwire/` with a minimal gemspec, version, and `README.md` stating it is planned.
   - `gems/pave-agent/` with a minimal gemspec, version, and `README.md` stating it is planned.
   - Do not implement Hotwire helpers or agent context generation unless code already exists.

8. **Update the root `Gemfile`.**
   - Replace `runtime/pave-*` path entries with `gems/pave-*` path entries.
   - Add `gems/pave` and `gems/pave-rails` path entries.
   - Run `bundle install` and commit `Gemfile.lock` changes.

9. **Update `bin/pave` paths.**
   - Update `PaveCli::ROOT` references if needed.
   - Update `PACKAGE_DEPENDENCIES` keys from `runtime/pave-*` to `gems/pave-*`.
   - Update runtime glob paths from `runtime/` to `gems/`.

10. **Update `Rakefile`.**
    - Ensure rake tasks reference the new `gems/` paths for testing and packaging.

11. **Validate each gemspec.**
    - For each `*.gemspec` under `gems/`:
      ```bash
      gem build gems/<name>/<name>.gemspec
      ```
    - Clean up built `.gem` files afterward or `.gitignore` them.

12. **Run Packwerk.**
    - Update all `package.yml` dependency paths.
    - Run `bundle exec packwerk validate`.
    - Run `bundle exec packwerk check`.

13. **Run the test suite.**
    - `bundle exec rake test` (or the project's existing test command).
    - Fix any path-related failures. Do not fix product-shaped test failures here; defer to Phase 4.

## Validation

```bash
# All gems exist under gems/
ls gems/
# Expected: pave, pave-core, pave-rails, pave-tenancy, pave-identity, pave-billing, pave-audit, pave-backoffice, pave-hotwire, pave-agent

# Each gemspec is valid
for spec in gems/*/*.gemspec; do gem build "$spec"; done

# Packwerk still passes
bundle exec packwerk validate
bundle exec packwerk check

# Rails boot
bin/rails runner "puts 'boot ok'"

# Doctor runs
bin/pave doctor

# Test suite (product-shaped failures are expected until Phase 4)
bundle exec rake test
```

## Exit criteria

1. All runtime packages live under `gems/`.
2. The `gems/pave` meta-gem exists and depends on the default runtime gems.
3. The `gems/pave-rails` gem exists with at least an engine/railtie stub.
4. Every `*.gemspec` under `gems/` builds successfully.
5. All gems reference the same lockstep version.
6. `bundle exec packwerk validate` and `bundle exec packwerk check` pass.
7. `bin/pave doctor` runs and no longer references `runtime/` paths as the canonical location.
8. The `runtime/` directory is empty or deleted.

## Notes for the next phase

Phase 4 creates the `DemoScheduling` dummy product under `test/dummy/products/demo_scheduling/` and rewrites the remaining product-shaped tests to use it. The `gems/` layout must be stable before adding the dummy product so that tests exercise the new paths.

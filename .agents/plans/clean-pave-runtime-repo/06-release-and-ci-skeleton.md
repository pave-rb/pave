# Phase 6: Release and CI skeleton

## Objective

Prepare the runtime repository to build gems, validate cleanliness, and run a smoke install. Add the required scripts and CI configuration. Do not publish to RubyGems.

## Scope

- `scripts/build-gems`
- `scripts/release`
- `scripts/repo-check-clean`
- `scripts/smoke-install`
- `.github/workflows/ci.yml` (or existing CI files)
- Root `.gitignore` for `.gem` artifacts
- Version bumping mechanics

## Required reading

- `.agents/specs/SPEC_CLEAN_PAVE_REPO.md` sections 8, 20, 21.
- `AGENTS.md` section 9.
- Results of Phase 5.

## Allowed changes

- Create scripts under `scripts/`.
- Update or create CI workflow files.
- Update `.gitignore` to ignore built gems.
- Update `Rakefile` to add packaging/release rake tasks if desired.
- Update `CHANGELOG.md` with a neutral initial entry.

## Forbidden changes

- Do not publish to RubyGems.
- Do not create one repo per gem.
- Do not add marketplace, hosting, or orchestration scripts.
- Do not introduce Anella references.

## Step-by-step tasks

1. **Create `scripts/repo-check-clean`.**
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail

   ROOT="$(cd "$(dirname "$0")/.." && pwd)"
   cd "$ROOT"

   EXCLUDE_DIRS=(".git" "vendor" "tmp")
   EXCLUDE_FILES=("SPEC_CLEAN_PAVE_REPO.md")

   MATCHES=$(grep -R "Anella\\|anella\\|ANELLA" . \
     --exclude-dir=".git" \
     --exclude='SPEC_CLEAN_PAVE_REPO.md' \
     || true)

   if [ -n "$MATCHES" ]; then
     echo "FAIL: Forbidden Anella references found:"
     echo "$MATCHES"
     exit 1
   fi

   echo "PASS: No forbidden Anella references."
   ```
   - Make executable: `chmod +x scripts/repo-check-clean`.
   - Wire it into `bin/pave repo:check-clean` if not already done.

2. **Create `scripts/build-gems`.**
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail

   ROOT="$(cd "$(dirname "$0")/.." && pwd)"
   cd "$ROOT"

   mkdir -p pkg

   for spec in gems/*/*.gemspec; do
     echo "Building $spec..."
     gem build "$spec" --output "pkg/$(basename "$spec" .gemspec)-$(ruby -Ilib -r pave/version -e 'puts Pave::VERSION').gem"
   done

   echo "PASS: All gems built."
   ```
   - Ensure it builds every gemspec under `gems/`.
   - Place built `.gem` files in `pkg/`.
   - Make executable.

3. **Create `scripts/release` (stub).**
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail

   ROOT="$(cd "$(dirname "$0")/.." && pwd)"
   cd "$ROOT"

   echo "Release script is a planned surface."
   echo "Future behavior:"
   echo "  1. Bump lockstep version in lib/pave/version.rb"
   echo "  2. Update CHANGELOG.md"
   echo "  3. Run scripts/build-gems"
   echo "  4. Tag git release"
   echo "  5. Push gems to internal registry (not RubyGems during cleanup)"
   ```
   - Make executable.

4. **Create `scripts/smoke-install` (stub).**
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail

   ROOT="$(cd "$(dirname "$0")/.." && pwd)"
   cd "$ROOT"

   echo "Smoke install is a planned surface."
   echo "Future behavior:"
   echo "  1. Create a temp Rails app"
   echo "  2. Add Pavê gems via local path"
   echo "  3. Run pave:install generator"
   echo "  4. Run migrations and a health check"
   ```
   - Make executable.

5. **Update `.gitignore`.**
   - Add:
     ```
     /pkg/
     *.gem
     ```

6. **Update CI configuration.**
   - Create or update `.github/workflows/ci.yml`.
   - Required CI steps that exist at implementation time:
     ```yaml
     - name: Install dependencies
       run: bundle install
     - name: Run tests
       run: bundle exec rake test
     - name: Build gems
       run: scripts/build-gems
     - name: Check repository cleanliness
       run: scripts/repo-check-clean
     ```
   - Put missing/placeholder steps under a `target:` or `follow-up:` section, not as required gates:
     ```yaml
     # Target/follow-up steps
     # - name: Smoke install
     #   run: scripts/smoke-install
     # - name: Packwerk check
     #   run: bundle exec packwerk check
     # - name: RuboCop
     #   run: bundle exec rubocop
     ```

7. **Update `Rakefile`.**
   - Add a `release:skeleton` or `gems:build` task that delegates to `scripts/build-gems`.
   - Keep the existing test task.

8. **Update `CHANGELOG.md`.**
   - Add an initial entry describing the cleanup split.
   - Do not name Anella.

9. **Validate scripts locally.**
   - `scripts/repo-check-clean` returns 0.
   - `scripts/build-gems` builds all gems successfully.
   - `scripts/release` and `scripts/smoke-install` run without errors (they may print stubs).

10. **Run full CI-like validation.**
    ```bash
    bundle install
    bundle exec rake test
    scripts/build-gems
    scripts/repo-check-clean
    ```

## Validation

```bash
# Scripts are executable
chmod +x scripts/*

# Cleanliness passes
scripts/repo-check-clean

# All gems build
scripts/build-gems
ls pkg/

# Smoke/release stubs run
scripts/release
scripts/smoke-install

# Tests and static analysis
bundle exec rake test
bundle exec packwerk check
bundle exec rubocop

# Doctor still passes
bin/pave doctor
```

## Exit criteria

1. `scripts/repo-check-clean`, `scripts/build-gems`, `scripts/release`, and `scripts/smoke-install` exist and are executable.
2. CI workflow requires only commands that exist at implementation time.
3. `scripts/build-gems` successfully builds every gemspec under `gems/`.
4. `scripts/repo-check-clean` fails if Anella references are present and passes when clean.
5. Built `.gem` files are ignored by git.
6. `bundle exec rake test` passes.
7. `bin/pave doctor` passes.

## Notes for the next phase

Phase 7 validates that an external host app can consume Pavê. The `scripts/smoke-install` stub should be fleshed out or used as a manual procedure to create a temporary external host app, point it at the local `pkg/` or `gems/` paths, and run its tests.

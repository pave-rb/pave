# Phase 7: External consumer validation

## Objective

Prove that a Pavê host app can consume the runtime without embedding runtime source inside the app. Validate both local path dependency mode and internal Git tag dependency mode. Treat Anella as one possible external consumer, not as part of this repo.

## Scope

- Temporary external host app for smoke testing (outside the Pavê repo).
- Local path consumption (`path: "../pave/gems/<name>"`).
- Git tag consumption (`git "...", tag: "..." do ... end`).
- Documentation of the consumer contract.

## Required reading

- `.agents/specs/SPEC_CLEAN_PAVE_REPO.md` sections 8, 21, 22, 23.
- `AGENTS.md` sections 2, 4, 5.
- Results of Phase 6.

## Allowed changes

- Create a temporary external host app in a scratch directory (e.g., `/tmp/pave-smoke-host` or a sibling directory outside the repo).
- Add documentation to `docs/` describing the consumer contract.
- Update `README.md` with quick-start examples for host apps.
- Update `AGENTS.md` with notes about external consumption if public contracts changed.

## Forbidden changes

- Do not commit an external host app into the Pavê repo.
- Do not require Anella to live in the `pave-rb` organization.
- Do not add Anella-specific code, credentials, or config to the Pavê repo.
- Do not publish to RubyGems.

## Step-by-step tasks

1. **Document the consumer contract.**
   - Create or update `docs/host_app_consumption.md` with:
     - How to add Pavê to a host app `Gemfile`.
     - How to run `bin/rails generate pave:install`.
     - How to register a product.
     - How to run `bin/pave doctor` in a host app.

2. **Validate local path consumption.**
   - Create a temporary Rails app outside the Pavê repo:
     ```bash
     cd /tmp
     rails new pave-smoke-host --skip-bundle
     cd pave-smoke-host
     ```
   - Add local path gems to `Gemfile`:
     ```ruby
     gem "pave", path: "../pave/gems/pave"
     gem "pave-core", path: "../pave/gems/pave-core"
     gem "pave-rails", path: "../pave/gems/pave-rails"
     gem "pave-tenancy", path: "../pave/gems/pave-tenancy"
     gem "pave-identity", path: "../pave/gems/pave-identity"
     gem "pave-audit", path: "../pave/gems/pave-audit"
     gem "pave-backoffice", path: "../pave/gems/pave-backoffice"
     ```
   - Run `bundle install`.
   - Run `bin/rails generate pave:install`.
   - Run `bin/rails db:create db:migrate`.
   - Run `bin/pave doctor`.
   - Run a minimal health check (e.g., `bin/rails runner "puts Pave::VERSION"`).

3. **Validate Git tag consumption.**
   - Ensure the Pavê repo has a tag such as `v0.4.0-internal`.
   - In the temporary host app, replace path dependencies with Git tag dependencies:
     ```ruby
     git "git@github.com:pave-rb/pave.git", tag: "v0.4.0-internal" do
       gem "pave", glob: "gems/pave/*.gemspec"
       gem "pave-core", glob: "gems/pave-core/*.gemspec"
       gem "pave-rails", glob: "gems/pave-rails/*.gemspec"
       gem "pave-tenancy", glob: "gems/pave-tenancy/*.gemspec"
       gem "pave-identity", glob: "gems/pave-identity/*.gemspec"
       gem "pave-audit", glob: "gems/pave-audit/*.gemspec"
       gem "pave-backoffice", glob: "gems/pave-backoffice/*.gemspec"
     end
     ```
   - Run `bundle install`.
   - Run `bin/pave doctor`.
   - Document any additional setup required.

4. **Validate with the external Anella repo (optional, documented).**
   - If the external Anella repo is available and has been updated to consume Pavê:
     - Point its `Gemfile` at the local Pavê path.
     - Run Anella tests.
     - Run Anella deploy preflight if available.
   - If the Anella repo is not available, document the procedure instead of performing it.
   - Do not commit any Anella code or configuration into the Pavê repo.

5. **Capture validation results.**
   - Write a short report at `.agents/reports/clean-pave-runtime-repo/07-external-consumer-validation.md` summarizing:
     - Host app creation command
     - Dependency modes tested
     - Commands run
     - Pass/fail status
     - Blockers or follow-ups

6. **Update README and docs.**
   - Add a "Consuming Pavê in a host app" section to `README.md`.
   - Ensure examples use neutral product names.

## Validation

```bash
# Inside the temporary host app
bundle install
bin/rails generate pave:install
bin/rails db:create db:migrate
bin/pave doctor
bin/pave context
bin/rails runner "puts Pave::VERSION"

# Pavê repo cleanliness still holds
cd /path/to/pave
scripts/repo-check-clean
scripts/build-gems
bundle exec rake test
bin/pave doctor
```

## Exit criteria

1. A temporary external host app successfully consumes Pavê by local path.
2. A temporary external host app successfully consumes Pavê by internal Git tag (or the procedure is documented if a tag is not yet available).
3. `bin/pave doctor` runs successfully inside the external host app.
4. No Anella references were added to the Pavê repo during validation.
5. `scripts/repo-check-clean` passes.
6. `scripts/build-gems` builds all gems.
7. `bundle exec rake test` passes in the Pavê repo.
8. The consumer contract is documented in `docs/host_app_consumption.md` and `README.md`.

## Notes for the next phase

There is no next phase in this cleanup plan. After Phase 7:

- The repository is a clean Pavê runtime source monorepo.
- Future work (out of scope here) includes:
  - Implementing full upgrade behavior.
  - Implementing `pave-hotwire` and `pave-agent` gems.
  - Building a public docs site.
  - Publishing to RubyGems when ready.
  - Fleshing out `scripts/smoke-install` to automate the temporary host app validation.

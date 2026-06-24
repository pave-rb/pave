# Phase 5: CLI, generators, and agent context

## Objective

Make all developer-facing and agent-facing surfaces generic. The CLI, generators, and context documents must refer to host app, product, plugin, runtime, and module — never to Anella.

## Scope

- `bin/pave`
- `gems/pave/lib/pave/cli.rb` (if extracted from `bin/pave`)
- `gems/pave-rails/lib/generators/pave/` (install generator, product generator)
- `AGENTS.md`
- `CONTEXT.md` files in each gem
- `PAVE_MANIFEST.yml`
- `README.md`

## Required reading

- `.agents/specs/SPEC_CLEAN_PAVE_REPO.md` sections 12, 13, 14, 19.
- `AGENTS.md` sections 10, 11.
- Results of Phase 4.

## Allowed changes

- Edit `bin/pave` to remove Anella assumptions and add stub commands.
- Create or update `gems/pave/lib/pave/cli.rb` if the CLI is moved into the gem.
- Create or update `gems/pave-rails/lib/generators/pave/install_generator.rb`.
- Create or update `gems/pave-rails/lib/generators/pave/product_generator.rb`.
- Update `AGENTS.md` to reflect the final runtime shape.
- Create/update `CONTEXT.md` files in each gem.
- Create/update `PAVE_MANIFEST.yml`.

## Forbidden changes

- Do not implement full upgrade behavior unless it is already close.
- Do not assume Anella in any command, generator, template, or doc.
- Do not publish gems.

## Step-by-step tasks

1. **Refactor `bin/pave` into the gem structure (if not already done).**
   - Move CLI logic from `bin/pave` into `gems/pave/lib/pave/cli.rb`.
   - Keep `bin/pave` as a thin executable that requires `pave/cli`.
   - Ensure `gems/pave/pave.gemspec` declares the executable.

2. **Implement or stub required CLI commands.**
   - `bin/pave help` — list all commands.
   - `bin/pave version` — print lockstep version.
   - `bin/pave doctor` — run all runtime health checks.
   - `bin/pave doctor --upgrade` — stub that prints planned upgrade checks.
   - `bin/pave context` — generate an agent context snapshot.
   - `bin/pave new product <name>` — generator wrapper that invokes `rails generate pave:product <name>`.
   - `bin/pave list products` — print registered products from `Pave.registry`.
   - `bin/pave install:migrations` — copy runtime engine migrations to the host app (stub if not implemented).
   - `bin/pave upgrade` — print an upgrade plan and run safe reconciliations (stub if not implemented).
   - `bin/pave app:update` — host app config update task (stub if not implemented).
   - `bin/pave repo:check-clean` — run the hard Anella cleanliness check.

3. **Ensure `bin/pave doctor` is generic.**
   - Check for `gems/` directory instead of `runtime/`.
   - Check each gem's files, require, and APIs.
   - Check Packwerk config and dependency graph under `gems/`.
   - Check runtime anti-contamination with a neutral pattern.
   - Remove any remaining Anella-specific checks.

4. **Implement the install generator (`pave:install`).**
   - `gems/pave-rails/lib/generators/pave/install_generator.rb`
   - Creates in the host app:
     - `config/pave.rb`
     - `config/initializers/pave.rb`
     - `config/routes.rb` modifications
     - `products/.keep`
     - `AGENTS.md` (from a template)
     - `PAVE_MANIFEST.yml` (from a template)
     - `pave.lock` placeholder
   - Uses neutral names only.

5. **Implement the product generator (`pave:product`).**
   - `gems/pave-rails/lib/generators/pave/product_generator.rb`
   - Generates a skeleton product under `products/<name>/`.
   - Template files use `DemoScheduling` as an example comment, not as generated output.

6. **Update agent context files.**
   - `AGENTS.md`:
     - Confirm repository identity as Pavê runtime source monorepo.
     - Confirm it is not a host app and not Anella.
     - Confirm distribution through gems.
     - Confirm tests use `DemoScheduling`.
   - `CONTEXT.md` (root):
     - High-level repo map.
     - Package responsibilities.
     - How to run tests and validation.
   - `gems/pave-*/CONTEXT.md`:
     - One per gem summarizing public API and examples.
     - Use `DemoScheduling` as the example product.

7. **Create/update `PAVE_MANIFEST.yml`.**
   ```yaml
   name: Pavê Runtime
   repo: pave-rb/pave
   type: runtime_source_monorepo
   gems:
     - gems/pave
     - gems/pave-core
     - gems/pave-rails
     - gems/pave-tenancy
     - gems/pave-identity
     - gems/pave-billing
     - gems/pave-audit
     - gems/pave-backoffice
   planned_gems:
     - gems/pave-hotwire
     - gems/pave-agent
   dummy_product: test/dummy/products/demo_scheduling
   version_source: lib/pave/version.rb
   ```

8. **Update `README.md`.**
   - Title: "Pavê Runtime"
   - Description: gem family and tooling for Pavê host apps.
   - Installation: `gem "pave"`.
   - Quick start for host apps.
   - Link to `AGENTS.md` for agent context.
   - No Anella references.

9. **Add tests for new CLI commands.**
   - `test/lib/pave_cli_test.rb` should assert:
     - `bin/pave help` lists commands.
     - `bin/pave version` prints version.
     - `bin/pave doctor` passes.
     - `bin/pave list products` includes `:demo_scheduling` in test env.
     - `bin/pave repo:check-clean` returns exit 0.

10. **Run validation.**
    - `bin/pave help`
    - `bin/pave version`
    - `bin/pave doctor`
    - `bin/pave context`
    - `bin/pave list products`
    - `bin/pave repo:check-clean`

## Validation

```bash
# CLI commands work and are generic
bin/pave help
bin/pave version
bin/pave doctor
bin/pave context
bin/pave list products
bin/pave repo:check-clean

# Generator help is available
bin/rails generate pave:install --help
bin/rails generate pave:product --help

# Cleanliness check passes
bin/pave repo:check-clean
# or, until implemented:
grep -R "Anella\\|anella\\|ANELLA" . \
  --exclude-dir=.git \
  --exclude='SPEC_CLEAN_PAVE_REPO.md'

# Tests pass
bundle exec rake test
```

## Exit criteria

1. `bin/pave` exposes all required commands (stubs are acceptable for unimplemented behavior).
2. No CLI output refers to Anella.
3. `bin/pave repo:check-clean` exists and enforces the hard cleanliness invariant.
4. `pave:install` and `pave:product` generators exist and use neutral names.
5. `AGENTS.md`, `CONTEXT.md`, and `PAVE_MANIFEST.yml` describe Pavê runtime, not Anella.
6. `README.md` is rewritten for Pavê runtime.
7. `bundle exec rake test` passes.

## Notes for the next phase

Phase 6 adds release scripts and CI gates. The CLI `repo:check-clean` command is the primary gate. Ensure it returns a non-zero exit code when Anella references are found and zero when clean.

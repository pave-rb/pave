# Phase 1: Boundary inventory

## Objective

Map the current repository contents before any deletion or reorganization. The inventory report is the single source of truth for later phases. It identifies what must be deleted, what must be moved, what must be generalized, and what is already clean.

## Scope

- Entire repository working tree.
- Git history is out of scope; focus on the current HEAD working tree.
- The inventory is read-only with respect to source code.

## Required reading

- `.agents/specs/SPEC_CLEAN_PAVE_REPO.md` sections 4, 5, 6, 9, 10, 22.
- `AGENTS.md` sections 4, 5, 6, 7, 12.

## Allowed changes

- Create the report file `.agents/reports/clean-pave-runtime-repo/01-boundary-inventory.md`.
- Run read-only inspection commands (`grep`, `find`, `ls`, `git ls-tree`, `cat`, `head`, etc.).
- Update this planning document with findings if necessary.

## Forbidden changes

- Do not delete, move, or rename files.
- Do not edit runtime code, tests, config, or docs.
- Do not create new gems, packages, or products.
- Do not run destructive commands.

## Step-by-step tasks

1. **Create the report file** at `.agents/reports/clean-pave-runtime-repo/01-boundary-inventory.md`.

2. **Inventory Anella references.** Run and document the output of:
   ```bash
   grep -R "Anella\\|anella\\|ANELLA" . \
     --exclude-dir=.git \
     --exclude='SPEC_CLEAN_PAVE_REPO.md'
   ```
   Categorize each match by area: `runtime`, `app`, `config`, `db`, `test`, `docs`, `bin`, `locales`, `deploy`, `assets`.

3. **Inventory runtime modules.** List each directory under `runtime/`:
   - `runtime/pave-core`
   - `runtime/pave-tenancy`
   - `runtime/pave-identity`
   - `runtime/pave-billing`
   - `runtime/pave-audit`
   - `runtime/pave-backoffice`
   For each, note:
   - gemspec path and validity
   - `lib/` structure
   - `app/` structure (controllers, models, views, helpers, assets)
   - `db/migrate/` contents
   - `package.yml` dependencies
   - any Anella or product-specific code still inside

4. **Inventory product code.** Check for:
   - `products/anella/` directory or gitlink
   - any other `products/*` directories
   - `config/products.rb`
   - product-specific routes in `config/routes.rb`
   - product-specific views/controllers under `app/`
   - product-specific services/jobs under `app/`

5. **Inventory plugin code.** Check for:
   - `plugins/` directory contents
   - any `Pave::Plugin` manifests
   - plugin references in runtime code

6. **Inventory host-app-only files.** Identify files that belong in a host app rather than the runtime monorepo:
   - `app/assets/tailwind/application.css`
   - `app/views/layouts/*`
   - `app/controllers/application_controller.rb` (if host-specific)
   - `app/models/space.rb` (if it couples runtime to product)
   - `config/deploy.yml`
   - `config/credentials*.yml.enc`
   - `config/application.rb` host defaults
   - `config/environments/*.rb` product comments
   - `Dockerfile`, `docker-compose.yml`, `Procfile.dev`, `.kamal/`
   - `public/` assets

7. **Inventory deployment files.** List:
   - `config/deploy.yml`
   - `.kamal/`
   - `Dockerfile`
   - `docker-compose.yml`
   - `Procfile.dev`
   - any CI files under `.github/workflows/`

8. **Inventory credentials/config assumptions.** Document:
   - `config/credentials*.yml.enc` references to Anella providers
   - `config/application.rb` default app name / logo
   - mailer configuration test references to `anella.app`
   - WebAuthn config test references to `anella.app`
   - backup service references to `anella-db-backups`

9. **Inventory tests that depend on Anella.** Run and document:
   ```bash
   grep -R "Anella\\|anella\\|ANELLA" test/ spec/
   ```
   List each affected test file and whether it should be deleted, rewritten with `DemoScheduling`, or kept after neutralization.

10. **Inventory docs that mention Anella.** Run and document:
    ```bash
    grep -R "Anella\\|anella\\|ANELLA" README.md CHANGELOG.md AGENTS.md docs/ .agents/ --exclude='SPEC_CLEAN_PAVE_REPO.md'
    ```
    Note docs that must be rewritten or deleted.

11. **Inventory current gemspecs.** List all `*.gemspec` files and summarize:
    - gem name
    - version
    - dependencies
    - Rails dependency presence
    - whether the gemspec is valid (`gem build` dry-run)

12. **Inventory current Packwerk packages.** Run and document:
    ```bash
    bundle exec packwerk validate
    bundle exec packwerk check
    cat packwerk.yml
    cat package.yml
    ```
    List each `package.yml` and its declared dependencies.

13. **Inventory current CLI commands.** Read `bin/pave` and document:
    - implemented commands
    - hard-coded Anella references
    - forbidden patterns that include non-Anella terms
    - checks that assume `products/anella/package.yml`

14. **Summarize findings.** At the end of the report, provide:
    - counts of files by category
    - a risk/impact list for Phase 2
    - open questions to resolve in Phase 2

## Validation

- The report file exists and is readable.
- The report contains categorized lists for all required inventories.
- No source files were modified during this phase.
- The `grep` command output is captured verbatim in the report.

## Exit criteria

1. `.agents/reports/clean-pave-runtime-repo/01-boundary-inventory.md` exists and is complete.
2. All required inventory categories are documented.
3. Zero source-code changes were committed in this phase.
4. The inventory is approved as input for Phase 2.

## Notes for the next phase

Phase 2 uses this inventory as its todo list. Start with the highest-contamination areas identified here (typically `config/products.rb`, `config/routes.rb`, `bin/pave`, test files, and host-app defaults). Prefer deletion over generalization. Replace only the test fixtures that are still needed with `DemoScheduling`.

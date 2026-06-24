# Phase 2: Remove product contamination

## Objective

Remove or externalize all product-specific and Anella-specific code from the clean Pavê runtime repository. The repository must end this phase with no forbidden Anella references in runtime code, tests, docs, generators, templates, config, or examples.

## Scope

- All files and directories identified in the Phase 1 boundary inventory.
- Focus on Anella contamination; do not yet move runtime code to `gems/` (Phase 3).
- Do not yet create the `DemoScheduling` dummy product (Phase 4).

## Required reading

- `.agents/specs/SPEC_CLEAN_PAVE_REPO.md` sections 4, 9, 10, 15, 16, 17, 18, 25.
- `AGENTS.md` section 7.
- `.agents/reports/clean-pave-runtime-repo/01-boundary-inventory.md`.

## Allowed changes

- Delete files and directories that are purely Anella-specific.
- Edit files to remove Anella references, names, defaults, routes, i18n keys, comments, and assumptions.
- Replace Anella test fixtures with neutral names only where a test fixture is still required.
- Disable or remove Anella-specific checks in `bin/pave`.
- Update `config/products.rb` to remove `:anella` registration.
- Update `config/routes.rb` to remove `/admin/anella` and `/backoffice/anella/*` redirects.
- Update locale files to remove `anella` keys and copy.
- Update `config/application.rb` default app name and logo.
- Update or delete deployment/credentials/config files that reference Anella.

## Forbidden changes

- Do not move runtime packages to `gems/` yet.
- Do not create the `gems/pave` meta-gem yet.
- Do not create `test/dummy/products/demo_scheduling/` yet (except where necessary to keep a test compiling; prefer leaving tests broken-and-documented over inventing stubs).
- Do not add new runtime behavior or over-generalize Anella-specific logic. Prefer deletion.
- Do not introduce new Anella references.
- Do not modify git history.

## Step-by-step tasks

1. **Remove product registration.**
   - Edit `config/products.rb` and delete the entire `:anella` product block.
   - If the file becomes empty except for `Pave.configure`, leave a minimal neutral block or delete the file and its require if safe.

2. **Remove product routes.**
   - Edit `config/routes.rb` and delete `/backoffice/anella/spaces` redirects and any `/admin/anella` routes.
   - Keep generic backoffice platform routes only.

3. **Remove host-app Anella defaults.**
   - Edit `config/application.rb`:
     - Change default `config.x.app.name` from `"Anella"` to `"Pavê"` or remove the default.
     - Change default `config.x.app.logo_asset` from `"anella-logo.png"` to a neutral value or remove it.
   - Edit `config/environments/development.rb` and remove the comment about `anella.localhost`.
   - Edit `config/environments/test.rb` and remove comments referencing `products/anella/test/`.

4. **Remove Anella from host views and assets.**
   - Edit `app/views/layouts/_pwa_head.html.erb` and change `apple-mobile-web-app-title` from `"Anella"` to `"Pavê"` or remove the hard-coded value.
   - Edit `app/assets/tailwind/application.css` and remove `@source` directives pointing at `products/anella/`.
   - Delete any Anella brand assets under `app/assets/` or `public/`.

5. **Remove Anella from app models.**
   - Edit `app/models/space.rb` and remove the `has_one :anella_space_profile` association.
   - If `app/models/space.rb` becomes empty or purely host-app specific, delete it.

6. **Remove deployment/credentials contamination.**
   - Delete `config/deploy.yml` (it is Anella-specific).
   - Delete or neutralize credential files that contain Anella provider names.
   - Delete `.kamal/` directory if it is Anella-specific.
   - Note: `Dockerfile`, `docker-compose.yml`, and `Procfile.dev` may be host-app-generic or Anella-specific; delete them only if they contain Anella assumptions. Document the decision.

7. **Remove Anella from locales.**
   - Edit `config/locales/en/interface.yml` and `config/locales/pt-BR/interface.yml`; remove `app_name: "Anella"`.
   - Edit `config/locales/en/backoffice.yml` and `config/locales/pt-BR/backoffice.yml`; remove all `anella:` keys and Anella-specific copy.
   - Edit `config/locales/en/billing.yml` and `config/locales/pt-BR/billing.yml`; remove Anella-specific demo description copy.

8. **Clean the CLI.**
   - Edit `bin/pave`:
     - Remove the `Anella` term from `FORBIDDEN_RUNTIME_PATTERN`, or replace the pattern with a neutral runtime anti-contamination check.
     - Remove the `anella_package_dependencies_valid?` method and its doctor check.
     - Remove the `"Anella package dependencies"` failure.
     - Update doctor output to refer to host app, product, plugin, runtime, module — never Anella.

9. **Delete Anella-specific tests and helpers.**
   - Delete test files whose sole purpose is asserting Anella behavior:
     - `test/integration/backoffice_layout_test.rb` if fully Anella-shaped
     - `test/integration/backoffice_request_matrix_test.rb` if fully Anella-shaped
     - `test/integration/backoffice_product_dashboard_test.rb` if fully Anella-shaped
     - `test/integration/pwa_directives_test.rb` or neutralize it
     - `test/lib/mailer_configuration_test.rb` or neutralize it
     - `test/lib/security/webauthn_config_test.rb` or neutralize it
     - `test/lib/app_brand_test.rb` or neutralize it
     - `test/services/backups/*` if fully Anella-specific
     - any other test files identified in Phase 1
   - Prefer deletion. If a test exercises a generic runtime contract, rewrite it using neutral names (`DemoScheduling`, `Acme`, etc.).

10. **Clean test fixtures.**
    - Edit `test/fixtures/billing_products.yml` and remove `"Anella CRM product"` description.
    - Search for any other fixtures/factories named after Anella entities and delete or neutralize them.

11. **Clean runtime package internals.**
    - Inspect each `runtime/pave-*` directory for Anella-shaped code.
    - Delete or neutralize per module:
      - `pave-backoffice`: delete Anella billing/spaces/WhatsApp/customer panels and menu labels.
      - `pave-billing`: delete Anella-specific plan defaults, Asaas adapter names, message credit assumptions.
      - `pave-identity`: delete Anella user profile/onboarding fields and sign-in copy.
      - `pave-tenancy`: delete Anella space profile fields, salon/clinic business categories, onboarding state.

12. **Clean docs and agent context.**
    - Delete `.agents/ANELLA_LANDING_PAGE_HANDOFF.md`.
    - Delete or rewrite `.agents/plans/pave-runtime/*` files that reference Anella if they are not historical artifacts needed for the split. Historical reports may be kept but must not be referenced by runtime code.
    - Update `README.md` title and content to describe Pavê runtime, not Anella.
    - Update `AGENTS.md` if needed (it is already mostly clean).

13. **Run the cleanliness check and iterate until clean.**
    ```bash
    grep -R "Anella\\|anella\\|ANELLA" . \
      --exclude-dir=.git \
      --exclude='SPEC_CLEAN_PAVE_REPO.md'
    ```

## Validation

```bash
# Hard cleanliness invariant
grep -R "Anella\\|anella\\|ANELLA" . \
  --exclude-dir=.git \
  --exclude='SPEC_CLEAN_PAVE_REPO.md'
# Expected: no output.

# Rails boot still works
bin/rails runner "puts 'boot ok'"

# Existing non-Anella tests still pass
bundle exec rails test test/lib/pave_billing_contracts_test.rb
bundle exec rails test test/lib/pave_audit_contracts_test.rb

# Packwerk still validates
bundle exec packwerk validate
bundle exec packwerk check
```

## Exit criteria

1. The cleanliness command returns no forbidden references.
2. `config/products.rb` no longer registers `:anella`.
3. `config/routes.rb` no longer contains `/admin/anella` or `/backoffice/anella`.
4. `bin/pave` no longer checks Anella package dependencies.
5. All deleted tests/files are documented in the commit message or a brief note.
6. Rails still boots and non-Anella runtime contract tests pass.
7. Packwerk validation and dependency checks pass.

## Notes for the next phase

Phase 3 moves the now-clean runtime packages from `runtime/` to `gems/`. Some tests may still be broken because they expect a product to exist; do not fix them here. Phase 4 introduces `DemoScheduling` and rewrites the remaining product-shaped tests.

# Phase 4: Dummy product and tests

## Objective

Replace Anella-dependent tests and fixtures with a neutral dummy product named `DemoScheduling`. The dummy product must exercise runtime contracts (product boot, routes, migrations, backoffice panels) without bringing Anella business logic into the repo.

## Scope

- `test/dummy/products/demo_scheduling/`
- Test files that previously referenced Anella and still need a product-shaped fixture.
- Backoffice tests that exercise product panels.
- Routing tests for product scopes.
- Registry/panel contract tests.

## Required reading

- `.agents/specs/SPEC_CLEAN_PAVE_REPO.md` sections 11, 15.
- `AGENTS.md` sections 7, 9.
- Results of Phase 3.

## Allowed changes

- Create `test/dummy/products/demo_scheduling/` with the target structure.
- Create minimal models, controllers, services, views, routes, migrations, and backoffice panels for `DemoScheduling`.
- Rewrite existing tests to use `:demo_scheduling` instead of `:anella`.
- Update `config/products.rb` (or the dummy host config) to register `DemoScheduling` only in test/dummy mode.
- Update locale files to add neutral demo product names.
- Update route tests to use `/admin/demo_scheduling` paths.

## Forbidden changes

- Do not copy Anella code into `DemoScheduling` with names changed.
- Do not make `DemoScheduling` deep or realistic beyond what is needed to test runtime contracts.
- Do not introduce Anella references.
- Do not add real product application code to the runtime monorepo.

## Step-by-step tasks

1. **Create the dummy product skeleton.**
   ```txt
   test/dummy/products/demo_scheduling/
   ├── app/
   │   ├── controllers/
   │   │   └── demo_scheduling/
   │   │       └── backoffice/
   │   │           ├── dashboard_controller.rb
   │   │           ├── spaces_controller.rb
   │   │           └── users_controller.rb
   │   ├── models/
   │   │   └── demo_scheduling/
   │   │       └── appointment.rb
   │   ├── services/
   │   │   └── demo_scheduling/
   │   │       └── book_appointment.rb
   │   └── views/
   │       └── demo_scheduling/
   │           └── backoffice/
   │               └── dashboard/
   │                   └── index.html.erb
   ├── config/
   │   ├── routes.rb
   │   ├── product.rb
   │   └── backoffice.rb
   ├── db/
   │   └── migrate/
   │       └── 20240101000000_create_demo_scheduling_appointments.rb
   ├── product.yml
   ├── package.yml
   └── CONTEXT.md
   ```

2. **Implement `product.yml`.**
   ```yaml
   name: DemoScheduling
   namespace: demo_scheduling
   version: "1.0.0"
   dependencies:
     - gems/pave-core
     - gems/pave-tenancy
     - gems/pave-identity
     - gems/pave-audit
     - gems/pave-backoffice
   ```

3. **Implement `package.yml`.**
   ```yaml
   enforce_dependencies: true
   enforce_privacy: true
   dependencies:
     - gems/pave-core
     - gems/pave-tenancy
     - gems/pave-identity
     - gems/pave-audit
     - gems/pave-backoffice
   ```

4. **Implement `config/product.rb`.**
   - Register `DemoScheduling` with `Pave.configure`.
   - Set `label: "Demo Scheduling"`.
   - Set `root:` to the product directory.
   - Avoid chrome/settings hooks unless required by a runtime contract test.

5. **Implement `config/routes.rb`.**
   - Define `demo_scheduling` routes inside a `Pave::Product::Router` or host route block.
   - Provide a root dashboard route and panel routes (e.g., spaces, users).

6. **Implement `config/backoffice.rb`.**
   - Register `DemoScheduling` with the backoffice:
     ```ruby
     config.backoffice.register_product :demo_scheduling,
       path: "/backoffice/demo_scheduling",
       i18n_key: "backoffice.products.index.demo_scheduling"
     ```
   - Register a few modules/panels:
     - `demo_scheduling.appointments`
     - `demo_scheduling.spaces`
   - Keep labels neutral.

7. **Implement minimal runtime contract models/services.**
   - `DemoScheduling::Appointment` — a tiny model with `belongs_to :space` (if tenancy fixture supports it) or standalone.
   - `DemoScheduling::BookAppointment` — a tiny service object inheriting from `Pave::Service`.
   - Controllers should inherit from `Pave::Backoffice::BaseController` for backoffice panels.

8. **Create the migration.**
   - A single table for demo appointments.
   - Keep the migration timestamp stable or use a deterministic date.

9. **Rewrite tests that need a product fixture.**
   - For each test file identified in Phase 1/2:
     - Replace `:anella` with `:demo_scheduling`.
     - Replace `"Anella"` with `"Demo Scheduling"`.
     - Replace `/admin/anella` paths with `/admin/demo_scheduling`.
     - Replace `anella/backoffice/*` controllers with `demo_scheduling/backoffice/*`.
   - Example files to review:
     - `test/lib/pave_backoffice_contracts_test.rb`
     - `test/integration/backoffice_layout_test.rb`
     - `test/integration/backoffice_product_dashboard_test.rb`
     - `test/integration/backoffice_request_matrix_test.rb`
     - `test/routing/backoffice_routing_test.rb`
     - `test/controllers/backoffice/products_controller_test.rb`
     - `test/helpers/backoffice_ui_helper_test.rb`
     - `test/system/backoffice/hotwire_components_test.rb`

10. **Add or update test fixtures.**
    - Create `test/fixtures/demo_scheduling/appointments.yml` if needed.
    - Ensure no fixture refers to Anella.

11. **Register the dummy product in the dummy host app.**
    - If the project uses `test/dummy/` as a host app, ensure it loads `test/dummy/products/demo_scheduling/config/product.rb`.
    - If the project loads all products from `products/`, create a symlink or config entry that points the test runner at `test/dummy/products/`.

12. **Update locales.**
    - Add neutral keys:
      ```yaml
      en:
        backoffice:
          products:
            index:
              demo_scheduling: "Demo Scheduling"
      ```

13. **Run the test suite and iterate.**
    - Fix failures related to the new dummy product.
    - If a test cannot be salvaged without product depth, delete it.

## Validation

```bash
# Cleanliness check
grep -R "Anella\\|anella\\|ANELLA" . \
  --exclude-dir=.git \
  --exclude='SPEC_CLEAN_PAVE_REPO.md'
# Expected: no output.

# Dummy product loads
bin/rails runner "puts Pave.registry.products.keys.inspect"
# Expected: includes :demo_scheduling

# Dummy product routes exist
bin/rails routes | grep demo_scheduling

# Backoffice boots with zero products and with DemoScheduling
bin/rails test test/integration/pave/backoffice/platform/dashboard_test.rb
bin/rails test test/integration/backoffice_product_dashboard_test.rb

# Full test suite
bundle exec rake test
```

## Exit criteria

1. `test/dummy/products/demo_scheduling/` exists with the target structure.
2. No Anella references remain in tests or fixtures.
3. `DemoScheduling` is registered as a product in the test environment.
4. Backoffice product panel tests use `DemoScheduling`.
5. Routing tests use `/admin/demo_scheduling`.
6. Runtime contract tests pass.
7. `bundle exec rake test` passes (or fails only on unrelated, documented issues).

## Notes for the next phase

Phase 5 generalizes the CLI (`bin/pave`), install generator, and agent context. The dummy product provides a concrete example to test `bin/pave list products` and `bin/pave new product` against.

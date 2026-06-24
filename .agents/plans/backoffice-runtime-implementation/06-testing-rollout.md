# 06. Testing, Doctor Checks, And Rollout

## Goal

Ship the new backoffice safely in small increments while preserving useful legacy behavior and proving the scope, auth, routing, and audit contracts with tests.

## Test Strategy

The current repository uses Minitest. Keep Minitest for this implementation unless the team explicitly decides to migrate to RSpec.

Test layers:

- Unit tests for registry, route drawer, settings schema, settings adapter, navigation context, and audit helper.
- Request/integration tests for routes, auth boundaries, tenant-scope guard, and mutations.
- System tests for shell, navigation, modals, drawers, secret field behavior, and responsive basics.
- Model tests for encrypted settings and audit append-only behavior.
- Doctor command tests for reserved names, missing controllers, and unaudited mutations.

Suggested commands:

```sh
bin/rails test test/lib/pave_backoffice_contracts_test.rb
bin/rails test test/integration/pave_backoffice_auth_test.rb
bin/rails test test/integration/pave_backoffice_platform_test.rb
bin/rails test test/integration/pave_backoffice_products_test.rb
bin/rails test test/system/pave_backoffice_shell_test.rb
bundle exec rubocop
```

Run Packwerk checks if available in the repo tooling.

## Acceptance Matrix

### Global

- `/admin` without platform admin session shows `/admin/sign_in`.
- Product sessions do not grant `/admin` access.
- Platform admin sessions do not grant product app access.
- Product sign-in rejects super-admin-only accounts.
- Backoffice shell always shows current context.
- Platform and Product navigation are visually separated.
- No backoffice page shows a global space switcher.
- Every state-changing action shows audit-aware feedback.
- Empty product registry renders useful Platform dashboard.
- Product panels render under their product only.
- Plugin panels show plugin identity and product identity.

### Platform

- `/admin` renders Platform dashboard.
- `/admin/users` renders platform users index.
- `/admin/users/:id` renders user detail.
- `/admin/audit` renders audit index.
- `/admin/settings` renders settings by namespace.
- Platform pages do not require registered products.
- Platform mutations write `Pave::Audit::AuditEvent` with nil `space_id`.

### Product

- `/admin/:product` renders product dashboard for registered product.
- `/admin/:product` returns not found for unregistered product.
- `/admin/:product/:panel` renders only registered panels.
- Product dashboard shows no-panels empty state.
- Product pages show Product context without activating tenant scope.
- Product panels inherit Pave shell and audit components.
- Panel-unavailable state is graceful and doctor reports the issue.

### Settings

- Declared settings namespaces render in `/admin/settings`.
- Empty settings schema renders `No settings declared`.
- Required missing values are flagged.
- Credentials fallback is displayed without exposing secret plaintext.
- Saving a namespace writes or updates `pave_settings` rows.
- Encrypted settings are encrypted at rest through Active Record Encryption.
- Saving settings writes audit event `backoffice.settings.updated`.

## Doctor Checks

Extend `bin/pave doctor` with backoffice validations:

- Product slug is not reserved.
- Product backoffice config loads successfully.
- Registered product panel controller exists or reports unavailable.
- Registered platform panel controller exists.
- Route blocks do not collide within a product context.
- Every non-GET backoffice action is audited or explicitly marked non-mutating.
- Settings schemas have valid key names and supported value types.
- Required indexes exist for new settings and common audit filters.
- No backoffice layout renders tenant chrome or a global space selector.

## Rollout Phases

### Phase 0. Baseline And Safety Net

- Add this plan and keep docs close to implementation PRs.
- Add failing acceptance tests for auth/session separation, zero-product dashboard, tenant-scope guard, and route shape.
- Inventory legacy routes used in production before removing `/backoffice`.

### Phase 1. Engine Foundation

- Add mount path configuration.
- Add engine routes.
- Add registry replacement and route drawer.
- Add reserved name validation.
- Add route and registry tests.

### Phase 2. Auth And Base Controllers

- Add platform admin session service.
- Add sessions controller and sign-in page.
- Replace base controller auth and tenant guard.
- Add forbidden/not-found/tenant-leak pages.
- Add auth/session/tenant tests.

### Phase 3. Shell And Components

- Create every component listed in `05-ux-components-hotwire.md`.
- Replace the simple shell partial with top bar, sidebar, breadcrumbs, page header, and status rail.
- Add responsive shell behavior.
- Add component/system tests.

### Phase 4. Platform Pages

- Implement Platform dashboard.
- Implement users index/detail and grant/revoke flows.
- Implement audit index and drawer.
- Register users/audit panels from runtime modules.
- Add platform request/system tests.

### Phase 5. Settings And Credentials

- Add `Pave::Settings` interface in `pave-core`.
- Add DB-backed settings adapter in backoffice.
- Add migration/model for `pave_settings`.
- Implement settings UI and secret field behavior.
- Add settings tests.

### Phase 6. Product Context

- Implement Product dashboard.
- Load `products/<product>/config/backoffice.rb`.
- Implement product panel route contract.
- Add panel unavailable fallback.
- Add product context tests.

### Phase 7. Legacy Migration

- Move Anella panel declarations from `config/products.rb` into `products/anella/config/backoffice.rb`.
- Migrate Spaces panel first because it strongly exercises tenant-scope safety.
- Migrate Product Billing panel next if controllers/models are ready.
- Split legacy Users functionality into Platform access and product membership views.
- Migrate logs/backups/registration settings only after their owning runtime modules are clear.
- Keep shims until the replacement passes acceptance tests.

### Phase 8. Cleanup

- Remove flat panel registration compatibility.
- Remove legacy host `/backoffice` routes if no explicit compatibility requirement remains.
- Remove legacy `Backoffice::BaseController` shim.
- Update README and developer docs.
- Re-run full test suite, RuboCop, and doctor checks.

## Risks And Open Decisions

### Auth Adapter Boundary

The existing app uses Devise on `User`, while runtime identity has `Pave::Identity::User`. The implementation needs a stable adapter that authenticates credentials without coupling backoffice controllers to product sessions.

Decision needed before Phase 2 implementation:

- Use a backoffice-owned credential authenticator that delegates to Devise when available.
- Or move password authentication into `pave-identity` first.

### Legacy Route Compatibility

The new design requires `/admin`; existing pages use `/backoffice` helpers. Do not carry compatibility automatically. If production users rely on old URLs, add explicit temporary redirects and track removal.

### Old AuditLog Data

New code should use `Pave::Audit::AuditEvent`. If old `AuditLog` history must remain searchable, decide between migration, dual-read audit UI, or a legacy-only archived page.

### Settings Ownership

`Pave::Settings` must live in `pave-core`, but the DB adapter initially lives in `pave-backoffice`. Keep the adapter boundary clean so settings can later move into a standalone `pave-settings` package.

### UI Dependency Surface

Backoffice should not depend on product app shared partials. Recreate necessary UI primitives inside `runtime/pave-backoffice` first, then migrate pages onto them.

## Final Release Checklist

- Docs updated.
- All plan acceptance criteria passing.
- No unexpected tenant scope in backoffice requests.
- No missing audit events for mutations.
- No product app session dependency in backoffice controllers.
- No product tenant chrome in backoffice layout.
- No reserved product route collisions.
- Missing panel controllers are diagnosed gracefully.
- Components from UX doc exist and are used.
- Full test suite and style checks pass.

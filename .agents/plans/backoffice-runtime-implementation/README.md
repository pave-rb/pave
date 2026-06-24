# Pave Backoffice Runtime Implementation Plan

Created: 2026-06-23

## Source Inputs

- `.agents/docs/BACKOFFICE_SYSTEM_DESIGN.md`
- `.agents/ux/BACKOFFICE_UX.md`
- Existing runtime package: `runtime/pave-backoffice`
- Existing host-level legacy backoffice: `app/controllers/backoffice`, `app/views/backoffice`, `config/products.rb`

## Objective

Implement `pave-backoffice` as the runtime-level administration console for Pave applications. The backoffice must be usable with zero products installed, mounted at `/admin` by default, separated from product authentication and tenant scope, driven by runtime/product/plugin registrations, and safe through explicit audit framing.

## Non-Negotiable Constraints

- Only platform super admins can access `/admin`.
- Backoffice authentication uses a separate platform admin session. Product sessions must not grant backoffice access.
- The backoffice never sets or reads active tenant scope. `Pave::Current.space` must remain nil during every backoffice request.
- Platform and Product contexts are distinct in routes, controllers, navigation, and visual chrome.
- Platform pages work with zero registered products.
- Product panels are registered declaratively by products and plugins, not hardcoded in `pave-backoffice`.
- Every state-mutating backoffice action writes a `Pave::Audit` event.
- New UI component ideas from the UX document must be implemented as reusable backoffice-owned components or partials.
- Controllers stay thin. Collection queries use eager loading where associations are rendered. Columns used for filtering, joining, and ordering need indexes.

## Existing Implementation Inventory

### Preserve And Adapt

- `runtime/pave-backoffice/lib/pave/backoffice/engine.rb`: keep the isolated Rails engine, expand it with routes, controllers, helpers, assets, and initializers.
- `runtime/pave-backoffice/package.yml`: dependency shape already matches the design: core, tenancy, audit, identity, billing.
- `runtime/pave-backoffice/lib/pave/backoffice/breadcrumbs.rb`: keep the concept, extend it with context-aware route metadata.
- `runtime/pave-backoffice/lib/pave/backoffice/navigation.rb`: keep the idea of filtered navigation, replace the flat panel list with platform/product groups.
- Existing table, filter, pagination, and audit patterns in legacy controllers/views can be mined for page behavior.
- Existing `Pave::Audit::AuditEvent` is the target audit store for the new runtime backoffice.
- Existing `Pave::Identity::User` is the target identity read model for platform users.

### Replace

- The flat `Pave::Backoffice::Registry#register_panel` model. Replace with explicit platform panel and product panel registries.
- The legacy `/backoffice` host namespace as the primary route. The design requires `/admin` through `Pave::Backoffice::Engine`.
- `Pave::Backoffice::BaseController` auth behavior that relies on product `authenticate_user!` and product session state.
- The current top-only shell partial. Replace with a dedicated top bar, sidebar, page header, breadcrumbs, context badge, and status rail.
- Host app shared UI partial dependency for the backoffice shell. Backoffice components should live in `runtime/pave-backoffice`.

### Migrate Or Rehome

- `Backoffice::ProductsController`: split into Platform dashboard and Product dashboard.
- `Backoffice::UsersController`: split platform user inspection/super-admin access from product membership management.
- `Backoffice::AuditLogsController`: migrate investigation UX to `Pave::Audit::AuditEvent`; keep legacy `AuditLog` only as migration data if needed.
- `Backoffice::SpacesController`: product panel candidate. It must treat spaces as records, not active tenant context.
- `Backoffice::LogsController`, `Backoffice::BackupsController`, `Backoffice::RegistrationSettingsController`: keep as candidates for runtime module/platform panels if their owning modules are formalized.
- `config/products.rb` backoffice registrations: migrate to `products/<product>/config/backoffice.rb` product-owned declarations.

## Plan Sections

1. `01-foundation-routing-registry.md`: engine mount, routes, route drawer, registry, boot sequence, reserved names.
2. `02-auth-context-audit.md`: platform admin session, tenant-scope guard, base controllers, audit contract.
3. `03-platform-pages-settings.md`: Platform dashboard, users, audit, settings/credentials, billing overview.
4. `04-product-panels-legacy-migration.md`: product dashboards, panel contract, legacy backoffice migration.
5. `05-ux-components-hotwire.md`: required component inventory, shell, visual system, Turbo/Stimulus interactions.
6. `06-testing-rollout.md`: test matrix, doctor checks, phased PR sequence, rollout risks.

## Small-PR Sequence

1. Foundation config and engine routes.
2. Registry replacement and route drawer.
3. Platform admin session and base controller guard.
4. Backoffice shell and core UI components.
5. Platform dashboard with zero-product empty state.
6. Platform users index/detail and super-admin access mutations.
7. Audit index with filters and inline detail drawer.
8. `Pave::Settings` interface in core and DB-backed implementation in backoffice.
9. Settings UI with secret field and namespace saves.
10. Runtime module platform panel contributions.
11. Product dashboard and product panel route contract.
12. Migrate first product panels from legacy backoffice.
13. Plugin panel registration hook and example panel.
14. `bin/pave doctor` validations for backoffice contracts.
15. Cleanup legacy routes/shims once replacement pages pass acceptance criteria.

## Definition Of Done

- `/admin/sign_in`, `/admin/sign_out`, `/admin`, `/admin/users`, `/admin/users/:id`, `/admin/audit`, `/admin/settings`, `/admin/:product`, and registered `/admin/:product/:panel` paths behave as documented.
- A product session alone cannot access `/admin`.
- A platform admin session alone does not sign into a product app.
- Every backoffice page shows Platform or Product context.
- The Platform dashboard renders useful content with zero products.
- Product dashboards render useful diagnostics when no panels exist.
- No backoffice page includes a global space switcher or active tenant state.
- Every mutation has confirmation/audit framing where required and writes `Pave::Audit`.
- UX components listed in `05-ux-components-hotwire.md` exist in `runtime/pave-backoffice` and are used by the first platform/product pages.
- Request/integration/system tests cover the documented acceptance criteria.

# R6 — pave-backoffice Implementation Plan

## 1. Purpose

Extract the generic backoffice shell, registration, navigation, and layout contracts into `pave-backoffice` while keeping product/module panel content in Anella or future plugins.

## 2. Preconditions

- R0 through R5 are complete and green.
- Runtime core, tenancy, audit, identity, and billing public APIs are stable.
- Existing backoffice routes and Anella backoffice flows have a green baseline.

## 3. Non-goals

- Do not build a full admin framework, CRUD generator, marketplace, or resource screen DSL.
- Do not move Anella dashboards, appointment charts, WhatsApp data, customer lists, schedules, billing copy, or logs content into runtime.
- Do not implement Hotwire UI derivation from resources.
- Do not widen runtime APIs only to silence future Packwerk violations.

## 4. Repo observations

- Existing `lib/pave/backoffice_registry.rb` already stores product/module metadata.
- `config/products.rb` registers Anella product and module metadata, including CRM, appointments, inbox, WhatsApp, and `peti_vet` entries.
- Root `app/controllers/backoffice/*` includes generic-looking base/products/logs/users/spaces/audit/registration controllers mixed with Anella/platform content.
- `products/anella/config/routes.rb` owns `/backoffice/anella` routes and product panel content.
- `app/services/platform/modules.rb` reads `Pave.backoffice.modules` but enforces availability through legacy `Billing::Entitlements` and `PermissionService`.

## 5. Planned changes

### Runtime/package structure

- Add `Pave::Backoffice` under `runtime/pave-backoffice/lib/pave/backoffice.rb`.
- Move/replace generic registry code into `runtime/pave-backoffice/lib/pave/backoffice/*`.
- Add `Pave::Backoffice::BaseController`, panel, navigation, and breadcrumb objects.
- Add generic layout and shared shell partials under `runtime/pave-backoffice/app/views`.

### Rails integration

- Make `pave-backoffice` depend on `pave-core`, `pave-tenancy`, `pave-audit`, `pave-identity`, and `pave-billing`.
- Keep root `/backoffice` shell route stable.
- Keep `/backoffice/anella` and its panel content product-owned.
- Keep top-level `Backoffice::BaseController` compatibility if current product controllers still inherit from it.

### Controllers/routes

- Runtime base controller provides authentication hook, authorization hook, current space hook, layout selection, breadcrumb helper, and panel lookup.
- Authorization must use runtime identity/capability APIs, not `super_admin?` or Anella permission names directly.
- Product routes register panel metadata using safe route references, not boot-time helper calls that can fail load order.
- Move product-specific backoffice controllers/views from root `app/controllers/backoffice` and `app/views/backoffice` to `products/anella` where they are not generic shell.

### Services/commands

- Implement `Pave::Backoffice.register_panel` and `Pave::Backoffice.panels`.
- Validate panel metadata: key, title, owner, route reference, capability, group/position, optional icon.
- Reject duplicate panel keys.
- Update `Platform::Modules` compatibility to read from the new public panel/capability APIs or mark it as a legacy facade.

### Tests

- Add tests for panel registration validation, duplicate keys, ordering/grouping, unauthorized access, breadcrumb contract, empty shell rendering, and Anella panel ownership.
- Preserve current backoffice integration tests.

### Documentation/agent context

- Document final shell/panel API and product registration locations in the R6 handoff.

## 6. Public contracts introduced or changed

- `Pave::Backoffice`.
- `Pave::Backoffice::BaseController`.
- `Pave::Backoffice::Panel`.
- `Pave::Backoffice::Navigation`.
- `Pave::Backoffice::Breadcrumbs`.
- `Pave::Backoffice.register_panel`.
- `Pave::Backoffice.panels`.
- Generic runtime layout `layouts/pave/backoffice`.
- Product-owned panels register from Anella/plugin code and own their content.

## 7. Migration strategy

R6 is shell extraction with product-content move-only cleanup.

- Source location: `lib/pave/backoffice_registry.rb`, `app/controllers/backoffice/base_controller.rb`, root backoffice controllers/views, `app/services/platform/modules.rb`, and Anella backoffice routes/controllers/views.
- Target location: `runtime/pave-backoffice/app/controllers/pave/backoffice/*`, `runtime/pave-backoffice/app/views/pave/backoffice/*`, `runtime/pave-backoffice/app/views/layouts/pave/backoffice.html.erb`, and `runtime/pave-backoffice/lib/pave/backoffice*`.
- Compatibility shim: keep `Backoffice::BaseController` and `Pave.backoffice` facades until product controllers use runtime names.
- Deletion timing: delete root app product-panel content only after it has moved to `products/anella` and routes/tests prove parity.

## 8. Anti-contamination checks

- Runtime backoffice must not mention Anella, appointments, customers, CRM panels, WhatsApp, Asaas, booking, clinic, salon, or product billing copy.
- Runtime shell may render slots and navigation containers only; panel bodies are product/plugin-owned.
- Product panel registration metadata may include product keys, but those registrations must live in product/plugin code, not runtime package files.
- Authorization hooks must depend on generic capabilities such as `backoffice.access`, not Anella roles.

## 9. Validation commands

```bash
git status --short
bundle exec rails zeitwerk:check
bin/rails routes
bin/pave doctor
bin/rails test test products/anella/test
bundle exec packwerk check
grep -R "Anella\|Appointment\|Customer\|Whatsapp\|WhatsApp\|Asaas\|booking\|clinic\|salon\|CRM" runtime/pave-backoffice || true
```

## 10. Commit plan

```txt
1. R6: add backoffice panel registry contracts
2. R6: move generic backoffice shell to runtime
3. R6: register Anella panels from product code
4. R6: bridge legacy backoffice controllers
5. R6: cover shell navigation and authorization
```

## 11. Handoff criteria

- Runtime shell renders without product content.
- Anella panels register from product-owned code and existing flows remain green.
- Backoffice authorization uses runtime identity/capability APIs.
- Runtime backoffice contamination search has no unapproved hits.
- Handoff lists shell API, Anella panel registrations, moved views/layouts, authorization model, and tests.

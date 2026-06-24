# 04. Product Panels And Legacy Migration

## Goal

Implement the Product context and migrate useful legacy backoffice behavior into registered product/plugin panels without carrying over tenant-scope or product-session confusion.

## Deliverables

- Product dashboard at `/admin/:product`.
- Product panel contract for product-owned and plugin-owned controllers.
- Product-owned `config/backoffice.rb` declarations.
- Graceful no-panels and panel-unavailable states.
- Migration path for legacy Anella-oriented backoffice controllers/views.

## Work Items

### M1. Product Dashboard

Route: `GET /admin/:product`

Controller:

- `Pave::Backoffice::Products::DashboardController < Pave::Backoffice::Products::BaseController`

Content sections:

- Product status.
- Registered panels.
- Plugin panels.
- Product settings health.
- Recent product audit events.
- Product-level diagnostics.

Scope copy:

```txt
No tenant space is active in backoffice.
```

No-panel empty state:

- Title: `No backoffice panels registered`
- Body: `This product is registered, but it has not declared product backoffice panels.`
- Action: `Add products/:product/config/backoffice.rb`
- Secondary action: `Run bin/pave doctor`

Implementation notes:

- The dashboard must work for registered products even when there are no panels.
- It must not render product app navigation or tenant chrome.
- It must show Product context, not tenant context.

### M2. Product Panel Contract

Product panel controllers must inherit from:

```ruby
Pave::Backoffice::Products::BaseController
```

Required controller behavior:

- Use `current_product` from route defaults.
- Use `current_panel` from registry metadata when available.
- Never infer active tenant context from URL segments.
- Use `audit_admin` for mutations.
- Use backoffice-owned confirmation components for dangerous actions.

Required panel metadata:

- Label.
- Slug.
- Source package.
- Owning product.
- Route.
- Description.
- Position.
- Source type: product, plugin, runtime module where applicable.

Generic panel layout:

- Panel overview.
- Primary resources.
- Configuration health.
- Recent activity.
- Panel-specific actions.

### M3. Product Backoffice Config Files

Migrate product registrations out of `config/products.rb` and into product-owned files.

Target path:

```txt
products/anella/config/backoffice.rb
```

Example:

```ruby
Pave::Backoffice.product(:anella) do |b|
  b.panel :spaces,
    label: "Spaces",
    controller: "anella/backoffice/spaces",
    routes: -> { resources :spaces, only: %i[index show] },
    source: :product,
    source_package: "products/anella",
    position: 20
end
```

Migration tasks:

- Keep product registration itself in `config/products.rb` or future `config/pave.rb`.
- Move only backoffice panel declarations into product config.
- Add boot loader to read the file when present.
- Make absence of the file valid.

### M4. Legacy Controller Migration Map

Existing files and target destinations:

```txt
app/controllers/backoffice/products_controller.rb
  -> Pave::Backoffice::Platform::DashboardController and Products::DashboardController

app/controllers/backoffice/users_controller.rb
  -> Platform::UsersController for super-admin access
  -> optional product membership panel for product-owned team/member admin

app/controllers/backoffice/spaces_controller.rb
  -> Anella::Backoffice::SpacesController product panel

app/controllers/backoffice/audit_logs_controller.rb
  -> Platform::AuditEventsController using Pave::Audit::AuditEvent
  -> optional product audit filtered view through query params

app/controllers/backoffice/logs_controller.rb
  -> future runtime operations Platform panel if operations module owns logs

app/controllers/backoffice/backups_controller.rb
  -> future runtime operations Platform panel if backups module owns backups

app/controllers/backoffice/registration_settings_controller.rb
  -> future identity or registration settings namespace under Platform Settings

app/controllers/backoffice/impersonations_controller.rb
  -> backoffice-owned audited impersonation flow, if retained
```

Do not migrate legacy CRUD blindly. Only preserve behavior that matches the new context model.

### M5. Spaces Product Panel

The legacy spaces page is useful, but it must be reframed.

New route examples:

```txt
/admin/anella/spaces
/admin/anella/spaces/:id
```

UX rules:

- Use label `Spaces` or `Tenant records`, not `Current space`.
- Show warning: `Viewing a space here does not activate tenant scope.`
- Do not provide a space switcher.
- Do not set `Current.space` or `Pave::Current.space`.
- Render only implemented actions.

Table columns:

- Name.
- Slug.
- Owner.
- Plan.
- Status.
- Members.
- Created.
- Last activity.

Query requirements:

- Eager load owner, subscription/plan, and members/counts used in the table.
- Avoid loading full user/customer collections only for counts. Use counter caches or aggregate queries where needed.
- Add indexes for slug, status, created_at, and foreign keys if absent.

### M6. Product Billing Panel

If the legacy billing routes/controllers exist, migrate them as product panel content. If they are not formalized yet, implement the shell and panel contract first, then add billing in a separate PR.

Route examples:

```txt
/admin/anella/billing
/admin/anella/billing/plans
/admin/anella/billing/plans/:id
/admin/anella/billing/subscriptions
/admin/anella/billing/subscriptions/:id
```

UX distinction:

- Platform billing answers whether runtime billing infrastructure is healthy.
- Product billing answers how a product defines and operates billing.

Dangerous actions:

- Force subscription state requires confirmation.
- Reason field is required.
- Audit event is required.

### M7. Plugin Panel Contract

Plugins register panels in `on_boot` after product configs load.

Example shape:

```ruby
runtime.backoffice.product_panel(:anella, :whatsapp,
  label: "WhatsApp",
  controller: "pave/plugins/whatsapp_channel/backoffice",
  routes: -> {
    resources :message_templates, only: %i[index show]
    resource :webhook_config, only: %i[show update]
  },
  source: :plugin,
  source_package: "whatsapp_channel"
)
```

UX rules:

- Plugin panels show both Product and Plugin badges.
- Plugin settings use the same Secret Field component as Platform settings.
- Plugin panels inherit the Pave backoffice shell.

### M8. Legacy View Reuse

Reusable patterns:

- Table markup from users, spaces, audit logs, and logs pages.
- Filter forms that serialize to query params.
- Pagination placement.
- Empty state rendering pattern.
- Existing copy keys as source material.

Replace or rewrite:

- Product app `shared/page_header` dependency for backoffice pages.
- Product app `shared/empty_state` dependency for backoffice pages.
- Product app button class assumptions when the backoffice visual language diverges.
- Any view copy implying tenant or workspace admin context.

### M9. Compatibility Shims And Cleanup

Current shim files:

- `lib/pave/backoffice_registry.rb`
- `app/controllers/backoffice/base_controller.rb`

Plan:

- Keep shims while legacy pages are being migrated.
- Add deprecation warnings only if they are useful and not noisy in tests.
- Remove shims after all product panels inherit from `Pave::Backoffice::Products::BaseController` and tests no longer reference legacy constants.
- Remove flat `register_panel` support after product configs use `Pave::Backoffice.product` and runtime modules use `platform_panel`.

### M10. Product Context Tests

Add tests:

- `/admin/:product` renders for a registered product.
- `/admin/:product` returns not found for unregistered products.
- Product dashboard shows no-panel empty state for product without panels.
- `/admin/:product/:panel` renders only registered panels.
- Missing panel controller renders unavailable state and doctor reports failure.
- Product panel controller has nil tenant scope throughout request.
- Product panel mutation writes `Pave::Audit` with product metadata and nil `space_id`.
- Plugin panel shows both product and plugin badges.

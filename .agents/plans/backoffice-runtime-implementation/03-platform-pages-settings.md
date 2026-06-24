# 03. Platform Pages And Settings

## Goal

Build the Platform context pages that work without any registered products: dashboard, users, audit, settings/credentials, and runtime module panels such as billing overview.

## Deliverables

- `Pave::Backoffice::Platform::DashboardController`
- `Pave::Backoffice::Platform::UsersController`
- `Pave::Backoffice::Platform::AuditEventsController`
- `Pave::Backoffice::Platform::SettingsController`
- `Pave::Settings` public interface in core.
- DB-backed encrypted settings implementation wired by backoffice.
- Platform panel registration from runtime modules.

## Work Items

### P1. Platform Dashboard

Route: `GET /admin`

Content sections:

- Runtime status.
- Registered products.
- Installed runtime modules.
- Plugin registrations.
- Recent audit events.
- Settings health.
- Billing overview when `pave-billing` registers its panel.

Reusable data sources:

- Product registry: `Pave.products` or future `Pave.registry.products` bridge.
- Backoffice registry: platform panels, product panels, diagnostics.
- Audit events: `Pave::Audit::AuditEvent.order(occurred_at: :desc).limit(5)`.
- Settings health: missing required declared settings.

Zero-product empty state:

- Title: `No products installed`
- Body: `This Pave runtime is running without registered products. Platform modules are still available.`
- Action: product registration docs.
- Diagnostic: `Run bin/pave doctor to validate runtime configuration.`

Implementation notes:

- Use registry cards for products, modules, plugins, and panels.
- Keep this page useful even when products list is empty.
- Avoid querying product tenant tables from the Platform dashboard unless a module owns that status card.

### P2. Platform Users Index

Route: `GET /admin/users`

Purpose:

- Inspect runtime identity users.
- Manage platform super-admin access.

Initial columns:

- Name.
- Email.
- Account type.
- Platform access.
- Product memberships.
- Last sign-in.
- Created.
- Status.

Filters:

- Search by name/email.
- Platform access.
- Product.
- Status.
- Created date.
- Last sign-in date.

Query requirements:

- Use `Pave::Identity::User` or a runtime identity query object.
- Eager load membership associations when rendering product membership counts or labels.
- Add indexes for any new searchable/filterable columns not already indexed.
- Use server-side pagination.

Actions:

- View user.
- Grant super admin.
- Revoke super admin.
- View audit events.

Safety:

- Prevent accidental revocation of the current admin's last remaining super-admin access.
- Use confirmation modal for grant/revoke.
- Write `backoffice.super_admin.granted` or `backoffice.super_admin.revoked` audit event.

Legacy reuse:

- Reuse query/pagination style from `Backoffice::UsersController#index`.
- Do not reuse product-space filtering as ambient state.
- Do not expose legacy create/edit/destroy product user flows as Platform user actions.

### P3. Platform User Detail

Route: `GET /admin/users/:id`

Sections:

- Identity.
- Platform access.
- Product memberships.
- Recent sessions.
- Recent audit events.
- Danger zone only for implemented actions.

Important copy:

```txt
These memberships belong to product applications. They do not define backoffice access.
```

Audit links:

- Related events route to `/admin/audit?actor_or_target=:user_id`.

Implementation notes:

- Avoid implying that super admins belong to a product or space.
- Render product memberships as records.
- Use the audit trail component for the last 10 related events.

### P4. Platform Audit Index

Route: `GET /admin/audit`

Target model:

- `Pave::Audit::AuditEvent`

Columns:

- Time.
- Event.
- Actor.
- Source.
- Context.
- Target.
- Product.
- Metadata.

Filters:

- Date range.
- Event key.
- Actor.
- Target type.
- Product.
- Source.
- Mutation only.
- Namespace for settings events.

Interaction:

- Row click opens inline drawer or expandable row.
- Use Turbo Frame for drawer content.
- Keep filters serialized in query params.

Legacy reuse:

- Reuse filtering concepts from `Backoffice::AuditLogsController#index`.
- Do not build new pages on legacy `AuditLog` unless a migration view is intentionally required.
- If legacy audit history must remain visible, add a read-only "Legacy audit" filter or migration job in a later PR.

Query requirements:

- Use existing indexes on `pave_audit_events` for key, actor, target, space, and occurred_at.
- Add expression or JSONB indexes only if metadata filters become hot and measurable.

### P5. Pave Settings Public Interface

The system design decision is to define `Pave::Settings` in `pave-core`, not in `pave-backoffice`, so runtime modules can read settings without depending on backoffice.

Core interface:

```ruby
Pave::Settings.get(:billing, :api_key)
Pave::Settings.get!(:billing, :api_key)
Pave::Settings.define(:billing) { |s| s.key :webhook_secret, type: :string, encrypted: true }
Pave::Settings.schema_for(:billing)
Pave::Settings.namespaces
```

Core fallback behavior:

- Return DB-backed adapter value when a settings adapter is installed.
- Fall back to `Rails.application.credentials.dig(namespace, key)`.
- Return nil from `get` when absent.
- Raise `Pave::Settings::MissingSettingError` from `get!` when absent.

### P6. DB-Backed Settings Implementation

Backoffice-owned migration:

```ruby
create_table :pave_settings do |t|
  t.string :namespace, null: false
  t.string :key, null: false
  t.text :value
  t.string :value_type, null: false, default: "string"
  t.bigint :updated_by_id
  t.timestamps

  t.index %i[namespace key], unique: true
  t.index :updated_by_id
end
```

Model requirements:

- `Pave::Backoffice::Setting` or future `Pave::Settings::Setting`.
- `encrypts :value` using Active Record Encryption.
- Validate namespace/key presence.
- Validate declared value type.
- Preserve last updater metadata.

Adapter responsibilities:

- Read DB values.
- Write values one namespace at a time.
- Expose source status: database, credentials fallback, missing, optional unset.
- Never expose plaintext secrets by default.

### P7. Platform Settings UI

Route: `GET /admin/settings`, `PATCH /admin/settings`

UX structure:

- Header: `Settings`, `Runtime configuration and encrypted credentials.`
- Scope warning banner: `You are editing Platform settings. Changes may affect every product using the configured module or plugin.`
- Namespace list or tabs.
- Namespace cards with owner, required count, missing count, source status, last updated.
- One form per namespace.
- Secret field component for encrypted keys.

Save behavior:

- Save one namespace at a time.
- Validate against schema before writing.
- Write audit event `backoffice.settings.updated` with namespace metadata.
- Success notice: `Settings saved. A backoffice audit event was recorded.`
- Validation failure: `Some settings need attention before they can be saved.`

Secret field requirements:

- Mask by default.
- Show source state: missing, credentials fallback, stored in database, edited unsaved.
- Reveal requires deliberate click.
- Copy requires deliberate click.
- Clear action is separate and confirmed when no fallback exists.

### P8. Runtime Module Platform Panels

Register Platform panels in module engines:

- `pave-identity`: Users panel.
- `pave-audit`: Audit panel.
- `pave-billing`: Billing overview panel.
- `pave-backoffice`: Dashboard and Settings panels.

Billing overview scope:

- Show runtime billing adapter status.
- Show products using billing.
- Show recent subscription events.
- Show missing billing settings.
- Do not manage product plans from Platform billing.

### P9. Platform Page Tests

Add tests:

- `/admin` renders with zero products.
- `/admin` displays registered products when present.
- `/admin/users` filters by view and query params.
- `/admin/users/:id` shows platform access and product memberships as records.
- Grant/revoke super admin writes audit event and requires platform admin.
- `/admin/audit` filters by event, actor, target, source, product, date range.
- Audit row drawer renders metadata.
- `/admin/settings` renders empty state when no schemas exist.
- Settings namespace save validates schema, writes encrypted row, and writes audit event.
- Secret field never displays plaintext by default.

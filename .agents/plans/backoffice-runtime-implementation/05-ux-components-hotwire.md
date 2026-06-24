# 05. UX Components And Hotwire

## Goal

Create the reusable backoffice-owned component system described by the UX document, then use it across Platform and Product pages.

## Component Strategy

The repository does not currently show a dedicated ViewComponent dependency. Start with engine-owned partials, helpers, presenters, and Stimulus controllers. Do not add a component gem unless the team explicitly chooses that direction.

Target locations:

```txt
runtime/pave-backoffice/app/helpers/pave/backoffice/ui_helper.rb
runtime/pave-backoffice/app/views/pave/backoffice/components/*.html.erb
runtime/pave-backoffice/app/javascript/controllers/pave/backoffice/*_controller.js
runtime/pave-backoffice/app/assets/stylesheets/pave/backoffice.css
```

## Required Components To Create

### C1. Backoffice Shell

Files:

- `app/views/layouts/pave/backoffice/application.html.erb`
- `app/views/pave/backoffice/shell/_top_bar.html.erb`
- `app/views/pave/backoffice/shell/_sidebar.html.erb`
- `app/views/pave/backoffice/shell/_breadcrumbs.html.erb`
- `app/views/pave/backoffice/shell/_status_rail.html.erb`

Required regions:

- Top bar: Pave mark/name, environment badge, context pill, signed-in super admin, sign out of backoffice.
- Sidebar: Platform group and Products group.
- Page header area.
- Main content.

Mobile behavior:

- Sidebar collapses behind a menu button.
- Context remains visible in the top bar.
- Tables use horizontal scrolling where needed.

### C2. Context Badge

Partial:

```txt
pave/backoffice/components/_context_badge.html.erb
```

Variants:

- Platform.
- Product.
- Plugin.
- Runtime module.

Examples:

```txt
Platform
Product · Anella
Plugin · whatsapp_channel
Runtime module · pave-billing
```

Usage:

- Top bar context pill.
- Page header scope label.
- Audit event context column.
- Product and plugin panel cards.

### C3. Scope Warning Banner

Partial:

```txt
pave/backoffice/components/_scope_warning_banner.html.erb
```

Examples:

```txt
You are editing Platform settings. These values may affect every installed product.
You are viewing product-level administration for Anella. No tenant space is active.
Viewing a space here does not activate tenant scope.
```

Variants:

- Info.
- Warning.
- Danger.

### C4. Page Header

Partial:

```txt
pave/backoffice/components/_page_header.html.erb
```

Inputs:

- Title.
- Scope label.
- Description.
- Primary action.
- Secondary actions.
- Context badge.

The backoffice should not depend on the product app `shared/page_header` partial.

### C5. Registry Card

Partial:

```txt
pave/backoffice/components/_registry_card.html.erb
```

Content:

- Name.
- Type.
- Source package.
- Status.
- Route.
- Registered panel count.
- Last boot validation status.

Usage:

- Platform dashboard products/modules/plugins/panels.
- Product dashboard panel cards.

### C6. Status Card

Partial:

```txt
pave/backoffice/components/_status_card.html.erb
```

Usage:

- Runtime status cards.
- Products count.
- Runtime modules count.
- Plugins count.
- Missing settings count.
- Recent audit events count.
- Background jobs health.
- Billing adapter status.

### C7. Data Table

Partial and presenter:

```txt
pave/backoffice/components/_data_table.html.erb
Pave::Backoffice::Table
Pave::Backoffice::TableColumn
```

Required affordances:

- Server-side pagination slot.
- Search slot or filter bar integration.
- Filter chips.
- Sortable column links where useful.
- Row action menu slot.
- Empty state.
- Loading state.
- Error state.

Initial pages using it:

- Users index.
- Audit index.
- Settings history if implemented.
- Product Spaces panel.
- Product Billing plans/subscriptions when implemented.

### C8. Filter Bar

Partial:

```txt
pave/backoffice/components/_filter_bar.html.erb
```

Behavior:

- GET forms only for index filtering.
- Query params remain shareable.
- Applied filters render as chips.
- Clear action resets current filter group.
- Turbo Frame updates table content.

Common filters:

- Product.
- Module.
- Plugin.
- Event type.
- Actor.
- Target type.
- Date range.
- Status.
- Source.

### C9. Action Menu

Partial and Stimulus controller:

```txt
pave/backoffice/components/_action_menu.html.erb
pave/backoffice/action_menu_controller.js
```

Examples:

- View details.
- View audit trail.
- Grant super admin.
- Revoke super admin.
- Force subscription state.
- Open product dashboard.

Dangerous actions must open the confirmation modal instead of submitting immediately.

### C10. Confirmation Modal

Partial and Stimulus controller:

```txt
pave/backoffice/components/_confirmation_modal.html.erb
pave/backoffice/modal_controller.js
```

Content structure:

- Title.
- Impact summary.
- Affected object.
- Audit statement.
- Confirmation input when destructive.
- Reason field when required.
- Primary action.
- Cancel.

Use cases:

- Grant/revoke super admin.
- Clear secret without fallback.
- Force subscription state.
- Disable integrations.
- Start impersonation.

### C11. Secret Field

Partial and Stimulus controller:

```txt
pave/backoffice/components/_secret_field.html.erb
pave/backoffice/secret_field_controller.js
```

States:

- Missing.
- Using Rails credentials fallback.
- Stored in database.
- Edited, unsaved.

Behavior:

- Never show plaintext by default.
- Show masked value.
- Reveal requires deliberate click.
- Copy requires deliberate click.
- Clear action is separate.
- Saving writes audited event through the settings controller.

### C12. Audit Trail

Partial:

```txt
pave/backoffice/components/_audit_trail.html.erb
```

Compact version:

- Latest backoffice event.
- Actor.
- Time.
- Event type.
- Metadata summary.

Expanded version:

- Timeline grouped by date.
- Diff preview.
- Target object.
- Source.
- Request metadata if available.

Usage:

- User detail.
- Product dashboard.
- Settings namespace.
- Product panel resource details.

### C13. Empty State

Partial:

```txt
pave/backoffice/components/_empty_state.html.erb
```

Required variants:

- Correctly empty.
- Missing configuration.
- Module absent.
- Boot validation failed.
- Restricted by access.

Initial copies:

- No products installed.
- No panels registered.
- No audit events match these filters.
- No settings declared.
- Panel unavailable.

### C14. Drawer

Partial and Stimulus controller:

```txt
pave/backoffice/components/_drawer.html.erb
pave/backoffice/drawer_controller.js
```

Use cases:

- Audit event detail.
- User quick view.
- Plan quick view.
- Subscription quick view.
- Space quick view.

Use full pages for complex edit flows.

## Hotwire Patterns

### Turbo Frames

Use frames for:

- Settings namespace switching.
- Table filtering.
- Inline audit drawer.
- Product panel cards.
- Detail drawers.
- Confirmation modals.

Suggested frame ids:

```txt
backoffice_settings_namespace
backoffice_users_table
backoffice_audit_table
backoffice_audit_drawer
backoffice_confirmation_modal
backoffice_product_panels
```

### Turbo Streams

Use streams for:

- Saving settings.
- Refreshing status cards.
- Updating table rows after mutations.
- Appending audit event confirmations.
- Replacing validation error summaries.

## Visual Direction

Implement a distinct operational console visual language:

- Platform: neutral graphite.
- Product: stable accent.
- Plugin: secondary accent.
- Danger: red.
- Warning: amber.
- Success: green.
- Info: blue.

Typography requirements:

- Routes, slugs, event keys, namespace keys, and metadata use monospaced styling.
- Tables can use moderate density.
- Destructive flows should be more spacious.

Avoid:

- Product tenant chrome.
- Product app navigation.
- Marketing gradients.
- Generic SaaS dashboard copy.
- Space switchers.

## Component Acceptance Tests

Add view/system coverage for:

- Shell shows context, environment, admin identity, and sign-out action.
- Sidebar separates Platform and Products.
- Product panels expand only under selected product.
- Context badge variants render expected text.
- Scope warning banner appears on settings, product dashboard, and spaces panel.
- Confirmation modal blocks dangerous submit until required confirmation is satisfied.
- Secret field masks by default and shows source state.
- Data table renders empty, loading, error, and populated states.
- Filter bar serializes filters to query params.
- Audit drawer opens without full page navigation.

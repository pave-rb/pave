# Pavê Backoffice UX Design

## 1. Purpose

The Pavê backoffice is the super-admin control plane for the Rails runtime.

It is not a tenant dashboard, not a product application, and not a space-scoped admin area. It is a runtime-level administration surface for inspecting and operating Pavê itself, installed runtime modules, registered products, product-level panels, plugins, settings, credentials, users, billing, and audit history.

The interface must make one thing impossible to misunderstand:

**Backoffice users are platform super admins. They are not product users. They are not members of spaces. They do not operate through tenant scope.**

## 2. Hard UX Constraints

### 2.1 Access model

Only super admins may access the backoffice.

A super admin is a platform-level administrative actor. A super admin must not be treated as:

* a product user
* a space member
* a tenant manager
* a product customer
* a product owner
* a product-scoped staff account

The UI must never imply that a super admin “belongs” to Anella, a space, a tenant, or any product.

### 2.2 Authentication separation

Backoffice authentication must be its own explicit flow.

Required flows:

```txt
GET    /admin/sign_in
POST   /admin/sign_in
DELETE /admin/sign_out
```

Product authentication must remain outside the backoffice.

A product sign-in must never authenticate a super admin into `/admin`.

A backoffice sign-in must never authenticate a product user into a product application.

If the same underlying identity table is used, the session boundary still needs to be separate at the UX and controller level.

Recommended conceptual sessions:

```txt
platform_admin_session
product_user_session
```

### 2.3 Routing separation

Platform administration lives at:

```txt
/admin
/admin/users
/admin/users/:id
/admin/audit
/admin/settings
```

Product-level administration lives at:

```txt
/admin/:product
/admin/:product/:panel
/admin/:product/:panel/*
```

Do not introduce `/admin/platform` as a primary navigation route. Platform is the default root context.

Do not create product names that collide with reserved platform routes:

```txt
users
audit
settings
credentials
health
platform
```

### 2.4 Context separation

The backoffice has two operational contexts:

```txt
Platform context
Product context
```

Platform context is cross-product and runtime-level.

Product context is scoped to one registered product, but still not tenant-scoped. Product context means “administer this product package and its registered panels,” not “enter one customer workspace.”

The UI must always display the current context.

### 2.5 Tenant-scope prohibition

Backoffice screens must not show “current space” as an ambient state.

The following patterns are prohibited:

* global space selector in backoffice chrome
* tenant switcher in the backoffice shell
* showing product spaces as if the admin has entered one
* using product app navigation inside `/admin`
* silently sharing product app session state with backoffice state

When spaces are listed inside a product panel, they are records being administered, not active application context.

## 3. UX Principles

### 3.1 The backoffice is a control plane

The backoffice should feel like an operational console for a runtime.

It should favor:

* clear hierarchy
* exact labels
* strong context markers
* auditability
* safe destructive actions
* predictable navigation
* low visual ambiguity

It should not feel like a generic SaaS dashboard, because product users should never confuse it with their own app.

### 3.2 Context before content

Every page must answer three questions before the user interacts:

```txt
Where am I?
What am I administering?
What scope am I operating in?
```

Examples:

```txt
Platform / Dashboard
Platform / Users
Platform / Settings
Product: Anella / Billing
Product: Anella / Spaces
```

### 3.3 Registry-driven navigation

The navigation must reflect the runtime registry.

Platform panels are registered by runtime modules.

Product panels are registered by products and plugins.

The shell owns placement and interaction. The module, product, or plugin owns panel content.

### 3.4 Dangerous operations require audit framing

Any action that changes platform state should carry visible operational weight.

Examples:

* granting super-admin access
* revoking super-admin access
* changing credentials
* forcing subscription state
* starting impersonation
* changing product billing configuration
* disabling integrations

The UI must explain what will be audited before the action executes.

### 3.5 Empty states are part of the runtime story

The backoffice must be useful with zero products installed.

Empty states should guide the developer toward product registration, module installation, and configuration rather than appearing broken.

## 4. Global Information Architecture

```txt
/admin
├── Sign in
├── Platform
│   ├── Dashboard
│   ├── Users
│   │   ├── User index
│   │   └── User detail
│   ├── Audit
│   ├── Billing overview
│   └── Settings / Credentials
└── Products
    ├── Anella
    │   ├── Product dashboard
    │   ├── Billing
    │   ├── Spaces
    │   └── Plugin panels
    └── Other registered product
        ├── Product dashboard
        └── Registered panels
```

## 5. Global Backoffice Shell

### 5.1 Layout

The backoffice uses one dedicated layout:

```txt
pave/backoffice/application
```

Recommended layout regions:

```txt
┌──────────────────────────────────────────────────────────────┐
│ Top bar: brand, context, environment, admin identity          │
├───────────────┬──────────────────────────────────────────────┤
│ Sidebar       │ Page header                                  │
│               │ Breadcrumbs                                  │
│ Platform nav  │ Main content                                 │
│ Products nav  │                                              │
│               │                                              │
└───────────────┴──────────────────────────────────────────────┘
```

### 5.2 Top bar

The top bar should contain:

* Pavê mark/name
* environment badge, for example `Development`, `Staging`, `Production`
* current context pill
* signed-in super admin identity
* sign out action

Context pill examples:

```txt
Platform
Product · Anella
Product · Anella · WhatsApp
```

The context pill should visually distinguish platform from product context.

### 5.3 Sidebar

The sidebar should have two major groups:

```txt
Platform
Products
```

Platform group:

```txt
Dashboard
Users
Audit
Billing
Settings
```

Products group:

```txt
Anella
Other Product
```

When inside a product, the selected product expands to show its registered panels:

```txt
Products
└── Anella
    ├── Overview
    ├── Billing
    ├── Spaces
    └── WhatsApp
```

Do not show product panels under the Platform group.

Do not show platform panels under a product group.

### 5.4 Breadcrumbs

Breadcrumbs are mandatory because `/admin/:product/:panel/*` can become deep.

Examples:

```txt
Platform / Dashboard
Platform / Users / Maria Silva
Platform / Settings / Billing
Products / Anella / Overview
Products / Anella / Billing / Plans
Products / Anella / WhatsApp / Message Templates
```

Breadcrumbs should map to actual route hierarchy when possible.

### 5.5 Page header

Each page should have:

* title
* scope label
* short description
* primary action, if any
* secondary actions, if any

Example:

```txt
Title: Settings
Scope: Platform
Description: Manage runtime and integration settings declared by installed modules.
Primary action: Save changes
Secondary action: View audit events
```

### 5.6 Global status rail

Every page can optionally show small runtime status cards:

* products registered
* installed runtime modules
* missing settings
* latest audit event
* background jobs health
* billing adapter status

This should not become noisy. Use it mainly on dashboards.

## 6. Core UI Components

### 6.1 Context badge

Used in top bar, page header, tables, and audit events.

Variants:

```txt
Platform
Product
Plugin
Runtime module
```

For product context:

```txt
Product · Anella
```

For plugin panels:

```txt
Plugin · whatsapp_channel
Product · Anella
```

### 6.2 Scope warning banner

Used when an operation is global or sensitive.

Example:

```txt
You are editing Platform settings. These values may affect every installed product.
```

Example:

```txt
You are viewing product-level administration for Anella. No tenant space is active.
```

### 6.3 Registry card

Used on dashboards to show products, modules, plugins, and panels.

Content:

* name
* type
* source package
* status
* route
* registered panels count
* last boot validation status

### 6.4 Data table

Default table pattern for users, audit events, spaces, plans, subscriptions, and settings history.

Required affordances:

* server-side pagination
* search
* filter chips
* sortable columns where useful
* row action menu
* empty state
* loading state
* error state

### 6.5 Filter bar

Used above large lists.

Common filters:

* product
* module
* plugin
* event type
* actor
* target type
* date range
* status
* source

Filters should serialize to query params.

### 6.6 Action menu

Use compact row actions for non-primary operations.

Examples:

```txt
View details
View audit trail
Grant super admin
Revoke super admin
Force subscription state
Open product dashboard
```

Dangerous actions require confirmation modals.

### 6.7 Confirmation modal

Required for state-changing actions with high impact.

Content structure:

```txt
Title
Impact summary
Affected object
Audit statement
Confirmation input when destructive
Primary action
Cancel
```

Example audit statement:

```txt
This action will write a backoffice audit event with your admin identity.
```

### 6.8 Secret field

Used in Settings and Credentials.

States:

```txt
Missing
Using Rails credentials fallback
Stored in database
Edited, unsaved
```

Display behavior:

* never show plaintext by default
* show masked value
* reveal requires deliberate click
* copy requires deliberate click
* save writes audited event
* clearing a value requires confirmation if fallback does not exist

### 6.9 Audit trail component

Used on detail pages and after mutations.

Compact version:

```txt
Latest backoffice event
Actor
Time
Event type
Metadata summary
```

Expanded version:

```txt
Timeline grouped by date
Diff preview
Target object
Source
Request metadata if available
```

### 6.10 Empty state

Empty states should explain whether the system is:

* correctly empty
* missing configuration
* unavailable due to module absence
* failed due to boot validation
* restricted by access

Example:

```txt
No products installed

The Pavê runtime is running without registered products. Platform modules remain available. Register a product in config/pave.rb, then restart the app.
```

## 7. Authentication UX

## 7.1 Platform sign-in page

### Route

```txt
GET /admin/sign_in
```

### Purpose

Authenticate a platform super admin into the Pavê backoffice.

### Page title

```txt
Pavê Backoffice
```

### Subtitle

```txt
Platform administration access
```

### Form fields

```txt
Email
Password
Remember this device
```

Optional future fields:

```txt
Passkey
Two-factor code
Recovery code
```

### Primary action

```txt
Sign in to backoffice
```

### Required copy

The page should explicitly state:

```txt
This sign-in is only for Pavê platform super admins.
Product users must sign in through their product application.
```

### Error states

Non-super-admin credentials:

```txt
This account does not have platform backoffice access.
```

Super admin credentials from disabled account:

```txt
This platform admin account is disabled.
```

Invalid credentials:

```txt
Invalid email or password.
```

Already signed in as product user:

```txt
You are signed in to a product account, but backoffice access requires a separate platform admin session.
```

Do not silently reuse a product session.

### Success behavior

After successful sign-in:

```txt
redirect_to /admin
```

If a safe backoffice return path exists:

```txt
redirect_to requested /admin path
```

Never redirect to a product app after platform sign-in.

## 7.2 Platform sign-out flow

### Route

```txt
DELETE /admin/sign_out
```

### Purpose

Destroy only the platform admin session.

### Behavior

After sign-out:

```txt
redirect_to /admin/sign_in
```

with message:

```txt
You signed out of Pavê backoffice.
```

If the user also has a product session in the same browser, do not destroy it unless an explicit “sign out everywhere” action exists.

### Admin menu copy

```txt
Sign out of backoffice
```

Avoid generic `Sign out` if product sessions can coexist.

## 7.3 Product sign-in protection

Product sign-in pages must reject super-admin-only accounts.

When a super admin attempts to sign in through a product sign-in page:

```txt
This account is reserved for Pavê platform administration.
Use the backoffice sign-in page instead.
```

Link:

```txt
/admin/sign_in
```

Do not create a product session.

Do not redirect into a product space.

Do not infer product membership from the `super_admin` flag.

## 7.4 Backoffice access from product app

If a super admin is browsing a product app, the product UI should not show backoffice navigation unless the platform admin session also exists.

If shown, the link should be visually separated:

```txt
Open Pavê Backoffice
```

The action should route to:

```txt
/admin
```

If no platform admin session exists, the backoffice sign-in page appears.

## 8. Platform Navigation UX

## 8.1 Platform dashboard

### Route

```txt
GET /admin
```

### Purpose

Provide a runtime-level overview.

### Header

```txt
Dashboard
Platform overview for the Pavê runtime.
```

### Primary content

Recommended sections:

```txt
Runtime status
Registered products
Installed modules
Plugin registrations
Recent audit events
Settings health
Billing overview
```

### Runtime status cards

Cards:

```txt
Products
Runtime modules
Plugins
Missing settings
Recent audit events
```

Each card links to its owning panel if available.

### Registered products section

Display each product as a registry card:

```txt
Name
Slug
Status
Panels
Plugins
Primary route
```

Card action:

```txt
Open product admin
```

Routes to:

```txt
/admin/:product
```

### Empty state: zero products

Title:

```txt
No products installed
```

Body:

```txt
This Pavê runtime is running without registered products. Platform modules are still available.
```

Action:

```txt
View product registration docs
```

Secondary diagnostic:

```txt
Run bin/pave doctor to validate runtime configuration.
```

### UX notes

The dashboard must not look broken when no products exist. It should communicate that platform modules still work.

## 8.2 Platform users index

### Route

```txt
GET /admin/users
```

### Purpose

Inspect runtime identity users and manage super-admin status.

### Header

```txt
Users
Runtime identity users and platform access.
```

### Recommended tabs

Use query-param tabs rather than new routes:

```txt
All users
Platform admins
Product users
Disabled
```

Example:

```txt
/admin/users?view=platform_admins
```

### Table columns

```txt
Name
Email
Account type
Platform access
Product memberships
Last sign-in
Created
Status
```

Account type values:

```txt
Platform super admin
Product user
System
```

Important: `Platform super admin` must not display product or space ownership.

### Row actions

```txt
View user
Grant super admin
Revoke super admin
Disable account
View audit events
```

Grant/revoke actions require confirmation.

### Filters

```txt
Search by name/email
Platform access
Product
Status
Created date
Last sign-in date
```

### Empty states

No users:

```txt
No users found
```

No platform admins except current:

```txt
You are the only platform super admin. Be careful before revoking access.
```

### Safety rule

The current admin should not be able to accidentally revoke their own last remaining super-admin access without a stronger confirmation.

## 8.3 Platform user detail

### Route

```txt
GET /admin/users/:id
```

### Purpose

Show identity record, platform access, product memberships, and audit trail.

### Header

```txt
User detail
```

Scope badge:

```txt
Platform
```

### Content sections

```txt
Identity
Platform access
Product memberships
Recent sessions
Recent audit events
Danger zone
```

### Identity section

Fields:

```txt
Name
Email
Status
Created at
Last sign-in
Authentication methods
```

### Platform access section

Show:

```txt
Super admin: Yes/No
Granted by
Granted at
Last platform sign-in
```

Primary action if not super admin:

```txt
Grant super admin
```

Danger action if super admin:

```txt
Revoke super admin
```

### Product memberships section

This section is read-only by default unless product modules expose membership management panels.

Display:

```txt
Product
Space
Role
Status
```

Use clear copy:

```txt
These memberships belong to product applications. They do not define backoffice access.
```

### Audit section

Show last 10 events involving this user as actor or target.

Action:

```txt
View all related audit events
```

This routes to:

```txt
/admin/audit?actor_or_target=:user_id
```

### Danger zone

Actions:

```txt
Disable account
Force password reset
Revoke all product sessions
```

These may be future capabilities. If unavailable, do not render disabled fake controls.

## 8.4 Platform audit index

### Route

```txt
GET /admin/audit
```

### Purpose

Inspect backoffice audit events and runtime operational history.

### Header

```txt
Audit
Backoffice actions and runtime events.
```

### Table columns

```txt
Time
Event
Actor
Source
Context
Target
Product
Metadata
```

### Context values

```txt
Platform
Product: Anella
Plugin: whatsapp_channel
```

### Filters

```txt
Date range
Event type
Actor
Target type
Product
Source
Mutation only
```

### Row interaction

Clicking a row opens an inline drawer or expandable row.

Do not require a route unless a future audit detail route is added.

### Expanded event content

```txt
Event type
Actor
Target
Source
Request id
IP address, if stored
Metadata
Before/after diff, if available
```

### Empty state

```txt
No audit events match these filters.
```

### UX note

The audit page should be optimized for investigation, not decoration. Filters matter more than charts.

## 8.5 Platform settings and credentials

### Route

```txt
GET   /admin/settings
PATCH /admin/settings
```

### Purpose

Manage runtime settings declared by installed modules and plugins.

### Header

```txt
Settings
Runtime configuration and encrypted credentials.
```

### Scope warning

```txt
You are editing Platform settings. Changes may affect every product using the configured module or plugin.
```

### Information architecture

Settings are grouped by namespace.

Example namespaces:

```txt
billing
identity
audit
whatsapp_channel
smtp
```

Use a left-side namespace list or horizontal tabs depending on density.

### Namespace card

Each namespace shows:

```txt
Namespace label
Owning module/plugin
Required values count
Missing values count
Source status
Last updated
```

### Setting field states

```txt
Stored in database
Using Rails credentials fallback
Missing required value
Optional and unset
Unsaved change
Invalid
```

### Secret field behavior

For encrypted fields:

* mask by default
* show `••••••••`
* reveal only after click
* clear action separated from edit
* saving writes audit event
* show last updated metadata, not value

### Fallback source display

If a setting uses Rails credentials fallback:

```txt
Using credentials fallback
```

Action:

```txt
Move to database
```

This should prefill only when safe. For secret values, require re-entry unless plaintext is available in memory and intentionally exposed.

### Save behavior

Primary action:

```txt
Save namespace settings
```

Save should update one namespace at a time.

On success:

```txt
Settings saved. A backoffice audit event was recorded.
```

On validation failure:

```txt
Some settings need attention before they can be saved.
```

### Audit affordance

Each namespace should link to:

```txt
/admin/audit?event_type=backoffice_settings_updated&namespace=:namespace
```

### Empty state

If no settings schemas are declared:

```txt
No settings declared
Installed runtime modules have not registered configurable settings.
```

## 8.6 Platform billing overview

### Route

The system design describes billing as a platform panel contributed by `pave-billing`. The exact route may be panel-owned.

Recommended visible nav label:

```txt
Billing
```

### Purpose

Show cross-product billing infrastructure status, not product plan management.

### Header

```txt
Billing
Runtime billing overview.
```

### Content sections

```txt
Billing adapter status
Products using billing
Recent subscription events
Missing billing settings
Provider health
```

### UX distinction

Platform billing answers:

```txt
Is the runtime billing infrastructure configured and healthy?
```

Product billing answers:

```txt
How does this product package define and operate billing?
```

Keep those separate.

## 9. Product Navigation UX

## 9.1 Product dashboard

### Route

```txt
GET /admin/:product
```

Example:

```txt
GET /admin/anella
```

### Purpose

Provide product-level administration for one registered product.

This is not a customer workspace dashboard.

### Header

```txt
Anella
Product administration.
```

Scope badge:

```txt
Product · Anella
```

Scope note:

```txt
No tenant space is active in backoffice.
```

### Primary content

```txt
Product status
Registered panels
Plugin panels
Product settings health
Recent product audit events
Product-level diagnostics
```

### Registered panels section

Cards:

```txt
Billing
Spaces
WhatsApp
```

Each card includes:

```txt
Panel label
Source: product/plugin/runtime
Route
Status
Last audit activity
```

Action:

```txt
Open panel
```

Routes to:

```txt
/admin/:product/:panel
```

### Empty state: no panels registered

Title:

```txt
No backoffice panels registered
```

Body:

```txt
This product is registered, but it has not declared product backoffice panels.
```

Action:

```txt
Add products/:product/config/backoffice.rb
```

Secondary action:

```txt
Run bin/pave doctor
```

### UX notes

The product dashboard should expose product-level diagnostics even when no panels exist.

## 9.2 Product panel index

### Route

```txt
GET /admin/:product/:panel
```

Example:

```txt
GET /admin/anella/billing
GET /admin/anella/spaces
GET /admin/anella/whatsapp
```

### Purpose

Render a registered product or plugin panel inside the Pavê backoffice shell.

### Header pattern

```txt
[Panel Label]
Product administration for [Product Name].
```

Examples:

```txt
Billing
Product administration for Anella.
```

```txt
WhatsApp
Plugin administration for Anella.
```

### Required chrome

Every product panel inherits:

```txt
Backoffice top bar
Backoffice sidebar
Product context badge
Breadcrumbs
Audit-aware action components
```

Panel content is owned by the product or plugin, but the shell remains Pavê-owned.

### Required panel metadata

Each panel should expose:

```txt
Label
Slug
Source package
Owning product
Route
Description
Position
```

The shell can use this for page headers, nav, and diagnostics.

### Generic panel layout

Recommended structure:

```txt
Panel overview
Primary resources
Configuration health
Recent activity
Panel-specific actions
```

### Empty state

If a panel exists but has no records:

```txt
No records yet
```

If a panel controller is missing due to boot validation issue:

```txt
Panel unavailable
This panel is registered, but its controller could not be loaded.
```

This should ideally be caught before route drawing, but the UX should still have a graceful failure pattern.

## 9.3 Product billing panel

### Route examples

```txt
/admin/anella/billing
/admin/anella/billing/plans
/admin/anella/billing/plans/:id
/admin/anella/billing/subscriptions
/admin/anella/billing/subscriptions/:id
```

These deeper routes are panel-owned and depend on the product’s route block.

### Purpose

Manage product-specific billing objects.

### Header

```txt
Billing
Plans, subscriptions, and product billing operations for Anella.
```

### Overview content

```txt
Plans
Active subscriptions
Trialing subscriptions
Past due subscriptions
Billing provider status
Recent billing events
```

### Plans table

Columns:

```txt
Plan
Price
Interval
Limits
Features
Status
Subscribers
Updated
```

Actions:

```txt
View
Create plan
Edit plan
Archive plan
```

Mutating actions must show audit framing.

### Subscriptions table

Columns:

```txt
Subscriber
Space
Plan
Status
Current period
Provider id
Updated
```

Actions:

```txt
View
Force state
Cancel
View audit events
```

### Dangerous billing actions

Actions like forcing subscription state require confirmation:

```txt
You are about to force a subscription state. This may affect product access and billing reconciliation.
```

Required confirmation content:

```txt
Target subscription
Current state
New state
Reason
Audit statement
```

A reason field should be required.

## 9.4 Product spaces panel

### Route examples

```txt
/admin/anella/spaces
/admin/anella/spaces/:id
```

### Purpose

Inspect and administer product tenant spaces as records.

### Header

```txt
Spaces
Tenant spaces registered under Anella.
```

### Scope warning

```txt
Viewing a space here does not activate tenant scope.
```

### Spaces table columns

```txt
Name
Slug
Owner
Plan
Status
Members
Created
Last activity
```

### Row actions

```txt
View
View members
View audit events
Open product impersonation
Suspend
Export data
```

Some actions may be future-facing. Render only implemented actions.

### Space detail page

Recommended sections:

```txt
Overview
Owners and members
Billing
Recent activity
Data portability
Danger zone
```

### Important UX rule

Do not make the page feel like the admin has “entered” the space.

Avoid copy like:

```txt
Current space
Switch to space
You are now managing this space
```

Prefer:

```txt
Space record
Tenant record
Inspect space
```

## 9.5 Plugin panel: WhatsApp example

### Route examples

```txt
/admin/anella/whatsapp
/admin/anella/whatsapp/message_templates
/admin/anella/whatsapp/message_templates/:id
/admin/anella/whatsapp/webhook_config
```

### Purpose

Manage plugin-owned configuration and operational resources for a product.

### Header

```txt
WhatsApp
Plugin administration for Anella.
```

### Plugin badge

```txt
Plugin · whatsapp_channel
```

### Overview content

```txt
Connection status
Webhook status
Phone number configuration
Message templates
Recent webhook events
Missing settings
```

### Message templates table

Columns:

```txt
Template
Locale
Category
Status
Last synced
Provider id
```

Actions:

```txt
View
Sync
Disable
View provider payload
```

### Webhook config page

Sections:

```txt
Endpoint
Verify token
App secret
Signature validation
Last received event
Failure rate
```

Secret fields use the platform secret field component.

### UX distinction

Plugin panels must always show both:

```txt
Product · Anella
Plugin · whatsapp_channel
```

This prevents plugin configuration from looking like native platform settings.

## 10. Error and Boundary Pages

## 10.1 Forbidden

### Trigger

A non-super-admin reaches `/admin`.

### Message

```txt
You do not have access to Pavê backoffice.
```

Secondary text:

```txt
Backoffice access is restricted to platform super admins.
```

Action:

```txt
Return to product sign in
```

Optional action:

```txt
Sign in as platform admin
```

## 10.2 Not found

### Trigger

Invalid route, product slug not registered, missing panel, or reserved route misuse.

### Message

```txt
Backoffice page not found.
```

If product not found:

```txt
No registered product matches this route.
```

If panel not found:

```txt
This product does not have a registered panel with this slug.
```

Action:

```txt
Go to Platform dashboard
```

## 10.3 Tenant scope leak

### Trigger

A backoffice request detects `Current.space`.

### UX

This is an operator-facing runtime safety error.

Message:

```txt
Backoffice tenant-scope leak detected.
```

Body:

```txt
A tenant space was present during a backoffice request. Pavê backoffice must run outside tenant scope.
```

Actions:

```txt
Go to Platform dashboard
View diagnostics
```

This should be rare and treated as a bug, not a user mistake.

## 11. Visual Direction

## 11.1 Personality

The backoffice should feel:

```txt
precise
quiet
architectural
operational
trustworthy
modern
```

Avoid:

```txt
playful SaaS dashboard patterns
tenant app styling
marketing gradients
unclear glassmorphism
decorative noise
```

## 11.2 Color semantics

Recommended semantic roles:

```txt
Platform: neutral / graphite
Product: accent
Plugin: secondary accent
Danger: red
Warning: amber
Success: green
Info: blue
```

The exact palette can follow Pavê’s brand, but semantics must be stable.

## 11.3 Density

Backoffice users are technical/operators. Use moderate density.

Tables can be dense. Destructive flows should be spacious.

## 11.4 Typography

Use clear hierarchy:

```txt
Page title
Section title
Table header
Metadata label
Code/route text
Audit metadata
```

Routes, slugs, event types, and namespace keys should use monospaced styling.

Examples:

```txt
/admin/anella/billing
backoffice_settings_updated
whatsapp_channel.access_token
```

## 12. Interaction Patterns

## 12.1 Turbo Frames

Use Turbo Frames for:

* settings namespace switching
* table filtering
* inline audit drawer
* product panel cards
* detail drawers
* confirmation modals

## 12.2 Turbo Streams

Use Turbo Streams for:

* saving settings
* refreshing status cards
* updating table rows after mutations
* appending audit event confirmations
* replacing validation error summaries

## 12.3 Drawers

Use drawers for:

* audit event detail
* user quick view
* plan quick view
* subscription quick view
* space quick view

Use full pages for complex edit flows.

## 12.4 Modals

Use modals only for:

* confirmation
* small forms
* destructive actions
* secret reveal confirmation
* reason capture

Do not use modals as primary navigation.

## 13. Copy Standards

### 13.1 Use exact domain language

Use:

```txt
Platform
Product
Plugin
Runtime module
Panel
Space record
Super admin
Audit event
Settings namespace
Credentials fallback
```

Avoid:

```txt
Workspace admin
Organization admin
Store owner
Tenant dashboard
Current space
```

unless the page is explicitly rendering product-owned concepts as records.

### 13.2 State scope in action labels

Bad:

```txt
Save
Delete
Edit
```

Better:

```txt
Save platform settings
Archive plan
Revoke super admin access
Force subscription state
```

### 13.3 Audit-aware success messages

Every mutation success should mention audit when relevant:

```txt
Settings saved. A backoffice audit event was recorded.
```

```txt
Super admin access granted. A backoffice audit event was recorded.
```

## 14. Implementation-Oriented UX Acceptance Criteria

### 14.1 Global acceptance criteria

* Visiting `/admin` without a platform admin session shows `/admin/sign_in`.
* Product sessions do not grant access to `/admin`.
* Platform admin sessions do not grant access to product apps.
* Product sign-in rejects super-admin-only accounts.
* The backoffice shell always shows current context.
* Platform and Product navigation are visually separated.
* No backoffice page shows a global space switcher.
* Every state-changing action shows audit-aware feedback.
* Empty product registry still renders a useful Platform dashboard.
* Product panels are rendered under their product, never as platform nav.
* Plugin panels show plugin identity and product identity.

### 14.2 Platform context acceptance criteria

* `/admin` renders Platform dashboard.
* `/admin/users` renders platform users index.
* `/admin/users/:id` renders user detail.
* `/admin/audit` renders audit index.
* `/admin/settings` renders settings by namespace.
* Platform pages do not require any registered product.

### 14.3 Product context acceptance criteria

* `/admin/:product` renders product dashboard for a registered product.
* `/admin/:product` returns not found for unregistered products.
* `/admin/:product/:panel` renders only registered panels.
* Product dashboard shows “no panels registered” when product exists without panels.
* Product pages show product context without activating tenant scope.
* Product panels inherit Pavê shell and audit components.

## 15. Page Inventory Summary

| Page                       | Route                      | Context       | Purpose                               |
| -------------------------- | -------------------------- | ------------- | ------------------------------------- |
| Platform sign in           | `/admin/sign_in`           | Platform auth | Authenticate super admins only        |
| Platform sign out          | `/admin/sign_out`          | Platform auth | Destroy platform admin session        |
| Platform dashboard         | `/admin`                   | Platform      | Runtime overview                      |
| Users index                | `/admin/users`             | Platform      | Inspect users and platform access     |
| User detail                | `/admin/users/:id`         | Platform      | Inspect one identity user             |
| Audit index                | `/admin/audit`             | Platform      | Investigate audit events              |
| Settings                   | `/admin/settings`          | Platform      | Manage settings and credentials       |
| Product dashboard          | `/admin/:product`          | Product       | Product-level administration overview |
| Product panel              | `/admin/:product/:panel`   | Product       | Product/plugin-owned admin panel      |
| Product panel nested pages | `/admin/:product/:panel/*` | Product       | Panel-owned resource pages            |
| Forbidden                  | internal render            | Boundary      | Non-super-admin access                |
| Not found                  | internal render            | Boundary      | Missing product/panel/page            |
| Tenant leak error          | internal render            | Boundary      | Runtime safety failure                |

## 16. Final UX Position

Pavê backoffice should be designed as a runtime administration console.

Its most important job is not to expose CRUD. Its most important job is to make runtime scope visible and safe:

```txt
Platform is global.
Product is registered-package scope.
Space is never active.
Super admins are platform actors.
Every mutation is audited.
```

That is the spine of the experience.

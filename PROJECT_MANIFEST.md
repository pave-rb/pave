# Pavê — Rails-Native Business Runtime for Modular SaaS

Pavê is a modular monorepo runtime for building real SaaS products and business web applications on Rails. It provides the reusable business-layer foundation that every serious Rails product ends up rebuilding from scratch.

---

## Core Idea

Rails gives developers a powerful web framework. Pavê adds the missing business-runtime layer on top of it.

Many web applications rebuild the same foundation repeatedly: users, teams, tenants, roles, permissions, settings, billing hooks, admin screens, audit logs, onboarding, dashboards, and deployment conventions. Pavê encodes that foundation as composable modules so products can focus on their domain logic from day one.

Pavê is also designed to be agent-readable. Every architectural decision is documented so AI-assisted development stays inside the right boundaries.

---

## What Pavê Aims to Be

- A Rails application skeleton for starting real SaaS products.
- A modular runtime for installing and composing business modules.
- A set of Rails engines/gems providing reusable core functionality.
- An agent-readable architecture system for AI-assisted development.
- A tooling-rich framework for operating products in production.

## What Pavê Does Not Aim to Be

- A replacement for Rails.
- A no-code platform.
- A generic CMS.
- A clone of WordPress.
- A clone of Ash.
- A SaaS boilerplate only.
- A plugin marketplace before the core is proven.

---

## Target Users

- Rails solo founders building SaaS.
- Rails consultants and agencies building similar business apps repeatedly.
- Small teams building internal tools, ERPs, CRMs, scheduling systems, education platforms, or vertical SaaS.
- Developers who want Rails productivity but more structure for business modules and AI-assisted development.

---

## Stack

- **Framework:** Rails 8
- **Database:** PostgreSQL (schema-separated multi-tenancy)
- **Background jobs:** Solid Queue
- **Frontend:** Hotwire (Turbo + Stimulus), Tailwind CSS
- **Deployment:** Kamal

We breathe the Rails ecosystem. Modern Rails features — Action Cable, Solid Queue, Solid Cache — are used before reaching for external tools. On the frontend we stay narrowed to Hotwire. 

---

## Architectural Principles

### Monorepo Structure

Pavê is a schema-separated modular monolith. It is organized into:

- **Core Modules** — reusable business-runtime primitives (Tenancy, Identity, Billing, Backoffice, Audit).
- **Products** — applications inside the monorepo that implement domain logic by composing core modules.

### Controllers Orchestrate, They Don't Implement

Business logic lives in service objects (POROs in `app/services`), not controllers. Controllers are thin: they authenticate, authorize, call a service, and redirect. Name services by intent — `CreateSubscription`, `RetryFailedPayment`, `InviteMember`.

### Background Jobs

All background jobs must be:
- **Product-aware** -- explicitly knows the product that called it.
- **Tenant-aware** — explicitly reload the tenant, never inherit it from a request context.
- **Idempotent** — safe to retry and resilient to duplicate delivery.
- **Ordered-resilient** — especially webhook handlers, which must handle out-of-order events.

---

## Core Modules

### Tenancy

The foundation. Manages Spaces (tenants), membership, and the request-scoping lifecycle.

**Key primitives:**
- `Space` — the tenant unit. Every tenant-owned resource belongs to one.
- `SpaceMembership` — join between a User and a Space with a role.
- `Current.space` — set in `Spaces::BaseController`, available throughout the request at zero DB cost.
- Tenant-scoped base controllers that make unscoped queries impossible by default.

**Background job contract:** Jobs must call `Space.find(space_id)` explicitly. They must never assume `Current.space` is set.

### Identity

Manages users, authentication, sessions, roles, and impersonation.

**Key primitives:**
- User accounts with email/password authentication.
- Role system via `SpaceMembership`.
- Impersonation as a first-class, auditable primitive — not a debug shortcut.

**Impersonation rules (hard constraints):**
- Only super admins can impersonate.
- Every impersonation event is written to the Audit log with actor, target, and timestamp.
- Privilege escalation through impersonation is impossible by design.
- The active session must carry a visible impersonation marker accessible to the UI (e.g., `Current.impersonating?`).

### Billing

Provider-agnostic billing module with an adapter layer for concrete payment providers.

**Core model:**
- One active subscription per Space per billing product. Designed for multi-product from day one — even if a product starts with one subscription type, the schema supports independent pricing per product.
- Trial period is configurable per deployment. Default: 14 days, no payment required.
- Plans are defined in the database, managed by super admins.

**Plan enforcement:**
- `Billing::PlanEnforcer` is a stateless service object called explicitly at action boundaries.
- It is not a concern, not middleware, and not called on read paths.
- Primary gate: team member count (`SpaceMembership`).
- Secondary gate: feature access flags bundled into a plan.
- Add-on pattern: metered resources (e.g., message credits) as a separate axis from the base plan.

**Metered resources:**
- Tied to a Space, not a User.
- Deducted at send time, refunded on failure.
- Race conditions prevented via `pg_advisory_xact_lock(space_id)` inside a transaction.
- At zero credits, block paid outbound actions. Never block read access to existing data.

**BillingEvent:**
- Immutable append-only log. No `updated_at`. No updates. Ever.
- Every event carries: timestamp, actor, event type, metadata.
- This is the source of truth for billing history.

**Subscription states:** `trialing`, `active`, `past_due`, `canceled`, `expired`.
- Expired spaces enter read-only mode: no new resource creation, public-facing pages show a service unavailable state. Data is never deleted.

**Provider adapter contract:**
- Store provider IDs explicitly. Never infer them.
- Sandbox credentials for dev/test, production credentials for prod — environment-driven via Rails credentials. Never in ENV vars. Never in code.
- Webhook handlers must be idempotent and look up Space from provider IDs, not from `Current.space`.

### Backoffice

The super-admin interface for operating the entire platform. Sees across all tenants and all products. Nothing else in the system may do this.

Backoffice is organized as three nested levels. Each level is a distinct context. Entering a deeper level nests context — it does not replace it. A persistent breadcrumb provides the path back up at every level.

```
Platform Panel
└── Product Panel
    └── Module Panel
```

**Platform Panel**

The top level. Knows about products and nothing else. Displays registered products as cards — name, description, status. Clicking a card enters that product's panel.

The only cross-product concerns that live here are user lookup (for support) and the global audit log. Platform does not know about plans, billing, domain models, or any product internals.

**Product Panel**

Scoped to one product. Displays that product's registered modules as cards. Clicking a card enters that module's panel.

Pavê does not prescribe what modules a product registers. The product decides.

**Module Panel**

Fully owned by the module. Pavê provides the chrome — breadcrumb, navigation, auth. The module provides all content and behavior.

**What Pavê provides:**

The Platform Panel shell, the Product Panel shell, the Module Panel shell, `Backoffice::BaseController`, and the breadcrumb and nav chrome.

Products and modules register themselves declaratively:

```ruby
Pave::Backoffice.register_product(:demo, label: "Demo")
Pave::Backoffice.register_module(:demo, :billing, label: "Billing", root: "...")
```

**What Pavê does not provide:**

The content of any Module Panel. That is entirely the product's responsibility.

**Base controller contract:**
- Authenticates `current_user.super_admin?` — a platform-level flag, not a SpaceMembership role.
- Explicitly opts out of all tenant scoping. Any controller under `Backoffice::` that sets `Current.space` is a bug.
- Every action that modifies tenant data is logged to Audit.

### Audit

First-class, cross-domain immutable event log. Not an afterthought.

Any module can write to Audit. No module reads from Audit to make decisions — it is an observation layer, not a control layer.

**Log entry fields:** timestamp, actor (user or system), event type, target (type + id), metadata (JSON), source module.

**Audit must be written for:**
- All impersonation events.
- All billing state transitions.
- All plan enforcement decisions (allowed and blocked).
- All metered resource deductions and refunds.
- All super-admin actions that affect tenant data.

---

## Products

Products live inside the Pavê monorepo. They implement business domain logic while composing core modules.

**Product rules:**
- Products own their domain models, controllers, and views.
- Products do not access another product's private tables directly.
- Cross-product integration uses explicit contracts or events.

---

## Frontend Conventions

- **Turbo Drive / Frames / Streams + Stimulus** is the only frontend stack.
- Successful form submissions (POST/PATCH/DELETE) must **redirect** (303 PRG). Never `render 200` after a form POST — Turbo expects the redirect.
- Use Turbo Frames to scope partial page updates (modals, settings panels, inline edits).
- Use Stimulus controllers for JS behavior tied to DOM elements.
- Prefer micro-interactions and state animations over flash notices. Flash notices are a last resort.
- **Block before you fail.** If an action will fail due to plan limits or state, block the triggering UI element and display the reason inline. Never let the user hit a wall they could have seen coming.

---

## Code Style

- Idiomatic Ruby. Readability over cleverness.
- Methods under ~25 lines when possible.
- No business logic in helpers.
- Avoid meta-programming unless necessary.
- Avoid fat models when logic represents a workflow rather than state behavior.
- Avoid N+1 queries. Use `includes` / `preload` intentionally.
- Always add indexes for foreign keys.
- Heavy work goes to Solid Queue. Controllers stay fast (<200ms target).

---

## Testing Standards

- Test-Driven Development. Tests first.
- Every service object: happy path, failure path, edge case.
- Background jobs: idempotency and retry safety.
- Prefer request specs over controller specs.
- Avoid over-mocking domain logic.

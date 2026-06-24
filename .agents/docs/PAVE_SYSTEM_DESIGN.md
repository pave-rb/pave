# Pavê — System Design

**Mission:** Let Rails developers ship real SaaS products without rebuilding the same business foundation every time.

---

## The Problem with the Alternatives

**Boilerplates** (Jumpstart Pro, Bullet Train in template mode) give you a starting point — a snapshot of code you fork, own, and diverge from forever. There's no upgrade path. You copy the foundation and carry the debt.

**Bullet Train** (as a framework) is closer to Pavê's spirit, but its Super Scaffolding emphasis is code generation, not a runtime. It focuses on CRUD scaffolding speed and a prebuilt UI theme. Pavê's bet is different: the business runtime layer — tenancy, billing enforcement, audit, metered resources, background job contracts — should be a living dependency, not generated code.

**Ash Framework** (Elixir) is the strongest prior art in this space. It encodes a data layer and behavioral model into a reusable runtime. Pavê does not copy it, but it validates the category: a framework-above-the-framework for building real business software has a real audience.

Pavê's bet is: **ship a runtime, not a template.**

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Products                                               │
│  (first-class runtime nodes; Packwerk packages)         │
├─────────────────────────────────────────────────────────┤
│  Plugins                                                │
│  (optional gems, registered at boot)                    │
├─────────────────────────────────────────────────────────┤
│  Core Modules                                           │
│  Tenancy · Identity · Billing · Backoffice · Audit      │
├─────────────────────────────────────────────────────────┤
│  Pavê Runtime                                           │
│  (module registry, request lifecycle, Current*, CLI)    │
├─────────────────────────────────────────────────────────┤
│  Rails 8                                                │
└─────────────────────────────────────────────────────────┘
```

Products compose core modules and are first-class runtime nodes. Plugins extend the runtime through installable engines.
Products themselves are not engines by default; inside the monorepo they are Packwerk
packages loaded by Pavê product boot. Runtime modules are released in
lockstep as one Pavê runtime line. Nothing in this stack replaces Rails.

---

## The Runtime Contract

Pavê's reusable runtime modules and installable plugins are gems. Runtime modules that
need Rails integration are Rails engines; `pave-core` remains a pure Ruby gem. Product
code writes against Pavê's public API, but a product inside the monorepo is a Packwerk
package, not a gem dependency and not a mounted engine.

```ruby
# config/application.rb — a product declares its composition
Pave.configure do |c|
  c.product     :anella
  c.modules     [:tenancy, :identity, :billing, :audit]
  c.backoffice  :anella, label: "Anella CRM"
end
```

The runtime handles:
- Mounting runtime and plugin engine routes
- Registering products as runtime graph nodes
- Loading product packages through Pavê product boot
- Configuring product namespaces, autoload roots, view roots, routes, and migration paths
- Wiring `Current.*` into the request lifecycle
- Providing base controllers products inherit from
- Registering modules and product panels in the Backoffice

---

## Product Runtime Nodes

The boundary rule is distribution-driven:

| Code | Vehicle | Reason |
|---|---|---|
| Core runtime modules | Rails engine gems, except pure-Ruby `pave-core` | Reused across multiple products/apps and upgraded as dependencies. |
| Plugins | Rails engine gems | Optional installable extensions registered at boot. |
| Products | Pavê product packages + Packwerk packages | Product-specific app code that should be easy to create, clone, plug, inspect, and evolve without engine overhead. |

A product is a first-class Pavê runtime node. Product authors do not manually wire
Zeitwerk, route loading, view lookup, migration paths, or context files into the
host app. Pavê owns that plumbing.

A product uses regular Rails-like directories under `products/<name>`:

```text
products/anella/
├── app/
│   ├── controllers/
│   ├── models/
│   ├── services/
│   ├── jobs/
│   ├── helpers/
│   └── views/
├── config/
│   └── routes.rb
├── db/
│   └── migrate/
├── package.yml
├── product.yml
└── CONTEXT.md
```

Pavê maps those folders into the product namespace at boot, so this file:

```text
products/anella/app/models/appointment.rb
```

defines:

```ruby
Anella::Appointment
```

The product path gives the package boundary. Pavê product boot gives the Ruby/Rails
namespace. The developer should not need duplicated paths such as
`products/anella/app/models/anella/appointment.rb`.

When a product is registered:

```ruby
Pave.configure do |c|
  c.product :anella, label: "Anella CRM"
end
```

Pavê:

- defines or validates the product namespace
- registers product autoload/eager-load roots
- registers product view roots and controller lookup convention
- loads product routes from `products/anella/config/routes.rb`
- adds product migrations from `products/anella/db/migrate`
- registers the product in `Pave.registry`
- exposes it to `bin/pave context --product anella`
- allows plugins and backoffice panels to target it by product name

A product subset graduates to an engine only when it becomes reusable and distributable
outside that product. Until then, a clear package boundary is enough.

## Versioning Model

Pavê uses lockstep runtime releases. `pave-core`, `pave-tenancy`,
`pave-identity`, `pave-billing`, `pave-audit`, and `pave-backoffice` are treated
as one coordinated runtime, not as independently mixable libraries.

External applications should upgrade Pavê as a runtime line. Plugins declare
compatibility against the Pavê runtime version. Independent per-module compatibility
matrices are deferred until there is real external adoption pressure.

## Core Modules

### Tenancy

The foundation. Pavê uses row-level multi-tenancy by default: tenant-owned tables live in shared database tables and carry a non-null `space_id`. Request scope is represented by `Current.space`. Tenant reads go through scoped associations such as `current_space.appointments.find(id)`. Raw tenant-owned `Model.find(id)` is forbidden in tenant controllers/services and checked by tooling/tests; it is not treated as magically impossible.

Tenant-owned tables use `space_id`-scoped indexes and uniqueness constraints. Schema-per-tenant is explicitly not the default because it adds migration and operational complexity too early. PostgreSQL Row-Level Security remains a future hardening option for high-risk tables, not a Phase 1 requirement.

**Background job contract:** jobs receive `space_id` explicitly and load the space inside the job. `Current.space` is never inherited from the request context.

### Identity

Users, sessions, roles, impersonation. Role system lives on `SpaceMembership`, not on User. Impersonation is a first-class auditable primitive: only super admins, always written to Audit, visible via `Current.impersonating?`.

### Billing

Provider-agnostic via an adapter interface. Core model: one active subscription per Space per billing product. Plans in the database, managed by super admins.

Key enforcement primitives:
- `Billing::PlanEnforcer` — stateless service, called at action boundaries, never in middleware
- `MessageCredit` — metered resource tied to Space, deducted at send time, `pg_advisory_xact_lock` prevents races
- `BillingEvent` — immutable append-only log. No updates. Ever.

Subscription states: `trialing → active → past_due → canceled → expired`. Expired = read-only. Data never deleted.

### Backoffice

Three-level nested panel: Platform → Product → Module. The only context in the system that sees across all tenants. Pavê provides the chrome (auth, breadcrumb, nav). Products provide module content.

### Audit

Immutable event log. Any module writes. No module reads from it to make decisions. Fields: timestamp, generic actor reference, event type, generic target reference, space reference, metadata (JSON), source module. Audit must not depend on Identity or Billing internals.

Required audit events: all impersonation, all billing state transitions, all plan enforcement decisions, all metered resource deductions/refunds, all super-admin mutations to tenant data.

---

## Plugin System

A plugin is a gem that:

1. Declares a `Pave::Plugin` manifest
2. Ships a Rails engine
3. Registers itself at boot

```ruby
# inside a plugin gem
Pave::Plugin.define do |p|
  p.name        :whatsapp_channel
  p.requires    [:tenancy, :billing, :audit]
  p.backoffice  label: "WhatsApp", root: "whatsapp/backoffice"
end
```

Plugins can:
- Add routes via their engine
- Extend the Backoffice (a Module Panel)
- Emit Audit events
- Consume Billing credit deductions
- Add background jobs

Plugins cannot:
- Access another product's private tables directly
- Skip tenant scoping
- Bypass plan enforcement

**No plugin marketplace before the core is proven.**

---

## bin/pave — Developer and Agent CLI

The home for tooling that developers and agents run repeatedly. It is not a one-shot app generator; it is the command surface for managing the Pavê runtime graph, product packages, and workflow scaffolding.

```
bin/pave context            # emit architecture context for agent sessions
bin/pave context --module billing   # scoped context for one module
bin/pave context --product anella    # scoped context for one product
bin/pave context --workflow new-job  # scoped context for one workflow

bin/pave new product <name>         # scaffold and register a first-class product package
bin/pave install product <git-url>   # clone/install a product package and register it
bin/pave link product <path>         # register an existing local product package
bin/pave list products               # list registered products and boot status
bin/pave install plugin <gem>        # install and register a plugin

bin/pave doctor                     # audit the repo for violations of contracts
                                    # (unscoped queries, audit gaps, job idempotency)

bin/pave audit:check                # verify audit coverage across modules

bin/pave agent:workflow <name>      # run a named, predefined agent workflow
                                    # e.g.: add-billing-gate, new-job,
                                    #        extract-service, add-plan-feature
```

`bin/pave context` outputs a structured snapshot (Markdown + YAML) tailored to the current working state — which product, which modules, and which workflow are in scope. Context is task-scoped by default so agent sessions carry fewer irrelevant constraints. This is the primary input to agent sessions, not raw README files.

Agent workflows in `bin/pave agent:workflow` encode the same decision process a senior developer would follow for a common task (e.g. "adding a new billing gate") as a reproducible sequence of prompts, checks, and file scaffolding.

---

## Deployment: Container-first, Kamal-default

Pavê is container-first. Kamal is the blessed default deploy path because it is
Rails-friendly and operationally simple for small teams, but the runtime must not
depend on Kamal-specific behavior to boot or run.

Pavê ships a standard `Dockerfile`, a local/staging `docker-compose.yml`, a Kamal
`config/deploy.yml` template, and a `bin/pave deploy` wrapper that:
- Validates credentials are in Rails credentials (never ENV)
- Runs `bin/pave doctor` before deploy
- Tags the release
- Runs migrations in the deploy hook

**Accessory services** run as ordinary containers. Kamal may manage them as accessories, but Docker Compose remains the portable baseline:
- PostgreSQL (or managed via deploy target)
- Solid Queue (as puma plugin or dedicated process)
- Observability stack (see below)

---

## Observability

Self-hosted. Open source. No per-seat bill. Runs as ordinary containers. Kamal can deploy the stack as accessories, but the observability design is not Kamal-specific.

### Stack

```
Rails App
└── opentelemetry-sdk (traces)
    opentelemetry-instrumentation-all (auto-instruments Rails, AR, SolidQueue)
         │
         ▼
OTel Collector  ←── Vector (log shipping)
    │       │
    ▼       ▼
 Tempo   Prometheus
    │       │
    └───────┘
         │
         ▼
      Grafana
       (logs → Loki, traces → Tempo, metrics → Prometheus)
```

### What gets instrumented out of the box

- All HTTP requests (spans + latency)
- All ActiveRecord queries (duration, N+1 detection)
- All SolidQueue jobs (enqueue, execute, fail)
- All external HTTP calls (via Net::HTTP instrumentation)
- Business events from Audit log surfaced as custom spans

### Product-level telemetry

Products add business-level spans explicitly:

```ruby
# app/services/create_appointment.rb
def call
  Pave::Telemetry.span("appointment.create", space_id: @space.id) do |span|
    span.set_attribute("plan.limit_reached", false)
    # ...
  end
end
```

Pavê provides `Pave::Telemetry` as a thin wrapper over the OTel SDK so products don't couple to OTel internals directly.

### Note on Ruby OTel maturity

Traces are stable. Metrics via OTel Ruby SDK are in beta — Pavê derives metrics from span data via the OTel Collector's `spanmetrics` processor rather than emitting them directly from the app. Logs are shipped via Vector (file → Loki), not through the OTel logs SDK.

---

## LLM Agent Readiness

Pavê treats AI-assisted development as a first-class use case, not a footnote.

### Architecture context files

Every module ships a `CONTEXT.md` alongside its source:
- What the module owns and does not own
- Public API surface (methods products can call)
- Hard constraints (things that are always wrong)
- Schema it controls

These files are the source of truth for `bin/pave context`. They are kept minimal and current — not aspirational.

### Agent contract

The root `AGENT_CONTEXT.md` encodes:
- The module registry and ownership map
- Cross-module integration rules
- Background job contract
- Forbidden patterns (raw `Model.find`, `Current.space` in jobs, etc.)
- Code style and naming conventions

This is what an agent reads at the top of a session, not the entire codebase.

### Workflow templates

Common agent tasks are pre-structured in `bin/pave agent:workflow`:

| Workflow               | What it does |
|------------------------|--------------|
| `add-billing-gate`     | Scaffolds PlanEnforcer call, UI block, audit event for a new gated action |
| `new-job`              | Generates idempotent, tenant-aware, product-aware job template |
| `extract-service`      | Guides extraction of business logic out of a controller into a service object |
| `add-plan-feature`     | Adds a feature flag to the plan schema and enforcement path |
| `new-module-panel`     | Scaffolds a Backoffice module panel for a product |

---

## What Pavê is Not

- Not a no-code platform
- Not a CMS
- Not a clone of Bullet Train or Ash
- Not a boilerplate (you don't fork it; you depend on it)
- Not a plugin marketplace before the core is proven
- Not an abstraction over Rails — it is built on Rails idioms, not against them
- Not a mandate that products become Rails engines before they need distribution
- Not a Kamal-only framework; Kamal is the default deploy path, not a runtime dependency

---

## Differences from Bullet Train

| Dimension | Bullet Train | Pavê |
|-----------|-------------|------|
| Delivery | Fork/template (generated code) | Runtime (gem dependency) |
| Upgrades | Manual, diverges forever | `bundle update` |
| Scaffolding | Super Scaffolding (CRUD emphasis) | Module system + bin/pave workflows |
| Business primitives | Partial (billing in Pro) | Full (billing, audit, enforcement, metered resources) |
| Observability | Not included | Bundled self-hosted OTel stack |
| Deploy | Heroku-oriented | Container-first, Kamal-default |
| Agent tooling | None | First-class (context, workflows, bin/pave) |
| Theme | Tailwind UI (opinionated) | Tailwind (products own their design) |

---

## Migration from Anella

Pavê is being extracted from a working application, but the first full migration does not need to happen live in production. The current product can keep shipping while Pavê is built and validated off-production. The migrated product is deployed only after the runtime path is stable.

Correct order:

1. **Extract the runtime interfaces first** — define Pavê's public API (base controllers, Current, PlanEnforcer contract) without moving product code yet.
2. **Test contracts against Anella off-production** — Anella's existing behavior becomes the first integration test of Pavê's API.
3. **Move modules one at a time** — Tenancy first, then Audit, then Identity, then Billing, then Backoffice. Audit comes before Identity and Billing because impersonation and billing transitions write audit events.
4. **Cut over intentionally** — no production dual-write requirement for the first migration. Billing must have one authoritative write path at a time.
5. **Contamination rule** — Anella-specific domain models (Appointment, Customer, Inbox) never move into Pavê. If you're unsure whether something belongs in a core module or in Anella, it belongs in Anella. If a reusable subset emerges later, extract that subset into a runtime module or plugin engine then.

---

## Remaining Open Questions

These are real trade-offs that need answers, not filler:

**1. Plugin compatibility**
Runtime modules use lockstep Pavê versions. Before a second external plugin exists, define how plugins declare compatible Pavê runtime ranges.

**2. Backoffice theming**
Pavê provides the chrome. Products provide the content. But Pavê's chrome needs a visual baseline. Decision: ship a minimal, unstyled chrome or ship one opinionated Tailwind theme. Pick one before the first product uses it.

**3. bin/pave agent:workflow implementation**
Workflows can be implemented as: (a) plain shell scripts that call Claude/LLM APIs, (b) structured prompt templates the user pastes into their agent session, or (c) a Pavê-internal agent client. Start with (b) — lowest risk, immediately useful.

# Pavê — Architecture Specification

This document is the implementation reference. It defines the structure, contracts,
and conventions that every module, product, and plugin must follow. It is the
primary input for `bin/pave context`.

---

## Monorepo Structure

```
pave/
│
├── runtime/                    # The Pavê runtime — reusable modules distributed as gems
│   ├── pave-core/              # Pure Ruby gem: registry, Current, Service, errors, plugin DSL
│   ├── pave-tenancy/           # Engine gem: Space, SpaceMembership, tenant request scoping
│   ├── pave-identity/          # Engine gem: User, Session, roles, impersonation
│   ├── pave-billing/           # Engine gem: Subscription, Plan, BillingEvent, PlanEnforcer, credits
│   ├── pave-backoffice/        # Engine gem: Platform/Product/Module panel chrome
│   └── pave-audit/             # Engine gem: AuditEvent, Audit.log interface
│
├── products/
│   └── anella/                 # CRM product — first-class Pavê product package, not an engine
│       ├── app/
│       │   ├── controllers/    # Loaded under Anella:: by Pavê product boot
│       │   ├── models/         # Loaded under Anella:: by Pavê product boot
│       │   ├── services/       # Loaded under Anella:: by Pavê product boot
│       │   ├── jobs/           # Loaded under Anella:: by Pavê product boot
│       │   ├── helpers/
│       │   └── views/          # Product view root owned by Pavê product boot
│       ├── config/
│       │   └── routes.rb       # Product routes loaded by Pavê
│       ├── db/
│       │   └── migrate/        # Product-owned migrations
│       ├── spec/
│       ├── package.yml         # Packwerk declares deps on runtime modules
│       ├── product.yml         # Optional product metadata for tooling
│       └── CONTEXT.md
│
├── plugins/                    # Optional installable engine gems. None until core is proven.
│
├── app/                        # Host Rails app — thin. Only wires the runtime.
│   └── controllers/
│       └── application_controller.rb
│
├── config/
│   ├── application.rb          # Composes modules via Pave.configure
│   ├── routes.rb               # Thin host routes; mounts runtime/plugin engines
│   └── pave.rb                 # Pave.configure block
│
├── db/
│   └── migrate/                # Host/runtime migrations; products own products/*/db/migrate
│
├── ops/
│   ├── observability/          # OTel Collector, Prometheus, Loki, Tempo, Grafana configs
│   └── kamal/                  # deploy.yml templates
│
├── bin/
│   └── pave                    # CLI entry point
│
├── Gemfile                     # All runtime modules as path: deps
├── AGENT_CONTEXT.md            # Root agent context — what agents read first
└── packwerk.yml                # Boundary enforcement config
```

Every module follows this internal layout:

```
runtime/pave-tenancy/
├── app/
│   ├── controllers/pave/tenancy/
│   ├── models/pave/tenancy/
│   ├── jobs/pave/tenancy/
│   └── views/pave/tenancy/
├── db/migrate/
├── lib/
│   └── pave/
│       └── tenancy/
│           ├── engine.rb       # Rails::Engine subclass
│           └── version.rb
├── pave-tenancy.gemspec
├── package.yml                 # Packwerk config
├── CONTEXT.md                  # Agent context for this module
└── spec/
```

---

## Gemfile Composition

```ruby
# Gemfile (root)

# Runtime — local path dependencies during development
gem "pave-core",       path: "runtime/pave-core"
gem "pave-tenancy",    path: "runtime/pave-tenancy"
gem "pave-identity",   path: "runtime/pave-identity"
gem "pave-billing",    path: "runtime/pave-billing"
gem "pave-audit",      path: "runtime/pave-audit"
gem "pave-backoffice", path: "runtime/pave-backoffice"

# Products are not Gemfile dependencies.
# They are first-class Pavê product packages loaded by the runtime graph.
```

When a runtime module or plugin is published as a gem, the `path:` reference becomes
a versioned dependency. This is how products outside the monorepo depend on Pavê.

Products inside this monorepo are not engines, do not have gemspecs, and are not
mounted. They are first-class Pavê product packages with explicit Packwerk boundaries
and runtime-managed loading, routes, migrations, and context.

Pavê runtime modules are released in lockstep. External applications should depend
on a single Pavê runtime release line, or on matching versions of the individual
runtime gems. Plugins declare compatibility against the Pavê runtime version, not
against every internal module independently.

---

## Runtime Bootstrap

```ruby
# config/pave.rb

Pave.configure do |c|
  c.product     :anella, label: "Anella CRM"
  c.modules     [:tenancy, :identity, :billing, :audit, :backoffice]
  c.trial_days  14

  c.backoffice do |b|
    b.register :anella, :billing,    label: "Billing",    root: "anella/backoffice/billing"
    b.register :anella, :customers,  label: "Customers",  root: "anella/backoffice/customers"
  end
end
```

```ruby
# config/application.rb

require_relative "pave"

module PaveHost
  class Application < Rails::Application
    # Runtime engines declare their own load paths.
    # Products are registered as runtime nodes by Pave.configure.
    # Pavê product boot owns product namespaces, autoload/eager_load roots,
    # route loading, view roots, migration paths, and context registration.
    # Pave.configure is evaluated before engine initializers run.
  end
end
```

---

## Packaging Boundary Rule

Use a Rails engine only when the code has a distribution story.

| Code | Vehicle | Why |
|---|---|---|
| `runtime/pave-tenancy`, `runtime/pave-identity`, `runtime/pave-billing`, etc. | Rails engine gem | Reusable runtime modules distributed across products and apps. |
| `plugins/whatsapp_channel`, etc. | Rails engine gem | Optional installable extensions plugged into any Pavê deployment. |
| `products/anella` | Pavê product package + Packwerk package | Product-specific application code in this monorepo. It needs runtime registration and boundaries, not engine overhead. |

A product is a first-class Pavê runtime node. It is not a Rails engine by default,
but it still has a lifecycle in the runtime graph.

```text
products/
└── anella/
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
    ├── spec/
    ├── package.yml
    ├── product.yml      # Optional metadata for label, namespace, icon, default modules
    └── CONTEXT.md
```

**Product rules:**

- No `engine.rb`
- No `gemspec`
- No dummy app
- No `isolate_namespace`
- No product entry in the Gemfile
- No manual Zeitwerk setup by product authors
- No manual host-route wiring by product authors
- No manual migration-path wiring by product authors
- Packwerk enforces product dependencies, privacy, and public interfaces

If a subset of a product becomes genuinely reusable across multiple products, extract
that subset into a runtime module or plugin engine at that point. Do not pay the
engine cost before there is a real distribution boundary.

---

## Product Runtime Contract

Products are configured through `Pave.configure` and materialized by Pavê during
boot. A developer creating or plugging a product should not need to know how Rails
autoload paths, view paths, route loading, or migration paths are wired.

```ruby
# config/pave.rb

Pave.configure do |c|
  c.product :anella, label: "Anella CRM"
end
```

At boot, Pavê registers the product as a runtime node:

```ruby
Pave.registry.register_product(
  name:      :anella,
  namespace: Anella,
  root:      Rails.root.join("products/anella"),
  label:     "Anella CRM"
)
```

For each registered product, Pavê owns these integrations:

| Integration | Runtime responsibility |
|---|---|
| Namespace | Define or validate the product namespace, e.g. `Anella`. |
| Autoload/eager load | Register `products/anella/app/models`, `controllers`, `services`, `jobs`, and `helpers` under the `Anella` namespace. |
| Views | Register `products/anella/app/views` as the product view root and provide the product controller lookup convention. |
| Routes | Load `products/anella/config/routes.rb` into the host router under the product's route scope. |
| Migrations | Add `products/anella/db/migrate` to migration paths. |
| Assets | Register product asset roots when the product ships local assets. |
| Context | Include the product in `bin/pave context --product anella`. |
| Backoffice | Allow product panels to be registered by name. |

This allows product code to avoid duplicated namespace directories:

```text
products/anella/app/models/appointment.rb
products/anella/app/controllers/appointments_controller.rb
products/anella/app/services/create_appointment.rb
```

while still defining namespaced constants:

```ruby
module Anella
  class Appointment < ApplicationRecord
  end
end
```

```ruby
module Anella
  class AppointmentsController < ApplicationController
  end
end
```

The package path gives the product boundary; Pavê's product boot gives the Ruby/Rails
namespace. Product authors do not manually patch Rails lookup or configure Zeitwerk.

**Product lifecycle:**

```text
create    -> scaffold product package
register  -> add product to Pave.configure / runtime graph
boot      -> wire namespace, loader, routes, views, migrations, context
develop   -> write normal Rails code under the product namespace
inspect   -> use bin/pave context --product <name>
extract   -> move reusable pieces to runtime modules or plugin engines when justified
```

## Module Contract

`pave-core` is a pure Ruby gem. Every Rails-integrated Pavê runtime module is a
Rails engine that implements this interface:

```ruby
# runtime/pave-tenancy/lib/pave/tenancy/engine.rb

module Pave
  module Tenancy
    class Engine < ::Rails::Engine
      isolate_namespace Pave::Tenancy

      # 1. Declare public API — what other modules and products may call
      #    Everything else in app/ is private by convention and enforced by Packwerk.
      #
      # Public surface lives in lib/pave/tenancy/*.rb (not app/)
      # Products call: Pave::Tenancy.current_space, Pave::Tenancy::Space, etc.

      # 2. Extend Pave::Current with module-owned attributes
      initializer "pave.tenancy.current" do
        Pave::Current.include Pave::Tenancy::CurrentExtension
      end

      # 3. Provide base controllers for products to inherit
      #    Pave::Tenancy::BaseController sets Current.space and scopes queries.

      # 4. Register with the Pave module registry
      initializer "pave.tenancy.register" do
        Pave.registry.register(:tenancy, engine: self)
      end
    end
  end
end
```

**Every Rails-integrated module must provide:**

| Artifact | Location | Purpose |
|---|---|---|
| `Engine < Rails::Engine` | `lib/pave/<module>/engine.rb` | Rails integration |
| Public API module | `lib/pave/<module>.rb` | What products call |
| `CurrentExtension` | `lib/pave/<module>/current_extension.rb` | Attributes it contributes to `Pave::Current` |
| `BaseController` | `app/controllers/pave/<module>/base_controller.rb` | Products inherit this |
| `CONTEXT.md` | root of module | Agent context, ~100–200 lines |
| `package.yml` | root of module | Packwerk boundary declaration |
| Migrations | `db/migrate/` | Schema this module owns |

**A module may not:**

- Access another module's `app/` internals (only its `lib/` public API)
- Set `Current` attributes owned by another module
- Access a product's models directly

---

## Core Abstractions (pave-core)

### `Pave::Current`

Owned by pave-core. Modules contribute their attributes via `CurrentExtension`.

```ruby
# runtime/pave-core/lib/pave/current.rb

module Pave
  class Current < ActiveSupport::CurrentAttributes
    # Populated by Pave::Tenancy
    attribute :space             # Space instance. Set once per request.

    # Populated by Pave::Identity
    attribute :user              # User instance.
    attribute :impersonator      # User who is impersonating, or nil.

    # Populated by Pave::Billing
    attribute :subscription      # Subscription instance. Loaded once per request.
    attribute :plan_enforcer     # Memoized PlanEnforcer for this request.

    def impersonating?
      impersonator.present?
    end

    def guest?
      user.nil?
    end
  end
end
```

Modules extend this:

```ruby
# runtime/pave-tenancy/lib/pave/tenancy/current_extension.rb

module Pave
  module Tenancy
    module CurrentExtension
      # No new attributes — Tenancy contributes :space to Pave::Current directly.
      # This extension is where Tenancy adds request lifecycle behavior.

      def space=(value)
        super
        # When space is set, signal Billing to reset its memoized enforcer.
        self.plan_enforcer = nil
      end
    end
  end
end
```

### `Pave::Service`

Base class for all service objects across the entire monorepo.

```ruby
# runtime/pave-core/lib/pave/service.rb

module Pave
  class Service
    include ActiveModel::Validations

    # Class-level .call delegates to instance .call
    def self.call(...)
      new(...).tap(&:validate!).call
    rescue ActiveModel::ValidationError => e
      raise Pave::ValidationError, e.message
    end

    def call
      raise NotImplementedError, "#{self.class}#call is not implemented"
    end

    private

    # Write to the audit log without knowing the Audit module internals.
    # The call goes through the public Pave::Audit API.
    def audit(event_type, target:, metadata: {})
      Pave::Audit.log(
        actor:       Current.user,
        event_type:  event_type,
        target:      target,
        space:       Current.space,
        metadata:    metadata
      )
    end

    # Enforce plan at action boundaries.
    # Raises Pave::PlanLimitError if the action is not permitted.
    def enforce_plan!(action)
      Current.plan_enforcer.enforce!(action)
    end

    # Wrap in an OTel span for observability.
    def with_span(name, attributes = {}, &block)
      Pave::Telemetry.span(name, attributes, &block)
    end
  end
end
```

Products use it:

```ruby
# products/anella/app/services/create_appointment.rb

module Anella
  class CreateAppointment < Pave::Service
    def initialize(space:, params:, actor:)
      @space  = space
      @params = params
      @actor  = actor
    end

    def call
      enforce_plan!(:create_appointment)

      appointment = @space.appointments.create!(@params)

      audit(:appointment_created, target: appointment, metadata: { source: @params[:source] })
      appointment
    end
  end
end
```

### Error Hierarchy

```ruby
# runtime/pave-core/lib/pave/errors.rb

module Pave
  Error              = Class.new(StandardError)       # Base. Never rescue this directly.
  ValidationError    = Class.new(Error)               # Invalid input.
  AuthorizationError = Class.new(Error)               # User cannot perform this action.
  PlanLimitError     = Class.new(Error)               # Plan gate blocked the action.
  TenantStateError   = Class.new(Error)               # Space in a state that blocks the action (expired, etc.).
  ImpersonationError = Class.new(Error)               # Impersonation contract violation.
end
```

Base controllers rescue these once:

```ruby
# runtime/pave-tenancy/app/controllers/pave/tenancy/base_controller.rb

module Pave
  module Tenancy
    class BaseController < ApplicationController
      before_action :require_space!
      before_action :scope_to_space!

      rescue_from Pave::PlanLimitError,     with: :respond_plan_limit
      rescue_from Pave::AuthorizationError, with: :respond_unauthorized
      rescue_from Pave::TenantStateError,   with: :respond_tenant_state

      private

      def require_space!
        redirect_to root_path unless Current.space
      end

      def scope_to_space!
        # Makes current_space available to views and services.
        # Also asserts that any tenant-model lookup is scoped.
      end

      def current_space
        Pave::Current.space
      end

      def respond_plan_limit(error)
        respond_to do |format|
          format.turbo_stream { render_plan_limit_stream(error) }
          format.html         { redirect_back_or_to root_path, alert: error.message }
        end
      end

      def respond_unauthorized(_error)
        head :forbidden
      end

      def respond_tenant_state(error)
        respond_to do |format|
          format.html { render "pave/tenancy/errors/tenant_state", status: :forbidden, locals: { error: error } }
        end
      end
    end
  end
end
```

Product controllers inherit this:

```ruby
# products/anella/app/controllers/application_controller.rb

module Anella
  class ApplicationController < Pave::Tenancy::BaseController
    # Anella-specific before_actions and helpers go here.
    # Tenancy scoping and error handling are already wired.
  end
end
```

---

## Tenancy Model

Pavê commits to row-level multi-tenancy as the default strategy. Tenant-owned
records live in shared tables and are scoped by `space_id`; Pavê does not use one
PostgreSQL schema per tenant as the default architecture.

**Tenant-owned table rules:**

- Every tenant-owned table has a non-null `space_id`.
- Tenant-owned models use `belongs_to :space`.
- Tenant reads go through scoped associations, e.g. `current_space.appointments.find(id)`.
- Unique indexes are scoped by `space_id` unless the value is truly global.
- Common lookup indexes include `space_id` as the leading or co-leading column.
- Backoffice cross-tenant queries are explicit and isolated behind backoffice controllers/services.

`bin/pave doctor` and tests catch common unscoped-query mistakes. Packwerk protects
constant/package boundaries, not tenant data by itself. Stronger database-level
controls, such as PostgreSQL Row-Level Security, are optional future hardening for
high-risk tables and are not required for the first runtime extraction.

---

## Request Lifecycle

For every authenticated tenant request:

```
1. Rack / Puma receives the request.

2. ApplicationController#authenticate_user!
   → sets Current.user (Pave::Identity)
   → if impersonating: sets Current.impersonator, flags session

3. Spaces::BaseController#set_space!
   → resolves Space from subdomain or route param
   → sets Current.space
   → raises Pave::TenantStateError if space.expired?

4. Billing::BaseController concern (included by Spaces::BaseController)
   → loads Current.subscription = space.active_subscription
   → builds Current.plan_enforcer = Billing::PlanEnforcer.new(Current.subscription)
   → This is the ONLY place subscription is loaded per request. Zero extra DB calls after this.

5. Controller action runs.
   → Service objects call enforce_plan!(:action) at write boundaries only.
   → No plan checks on read paths.

6. Response rendered.
   → Turbo-native: form POSTs → 303 redirect → GET renders updated state.
   → Plan limit blocks are rendered inline in the triggering UI, never as flash notices.

7. OTel span closes. Attributes: space_id, user_id, subscription_state, impersonating.
```

**Background job lifecycle:**

```
1. Job is enqueued with: space_id, actor_id, idempotency_key, product.

2. Job runs:
   space = Pave::Tenancy::Space.find(space_id)     # Always. Never inherit Current.space.
   actor = Pave::Identity::User.find(actor_id)     # Always.
   return if already_processed?(idempotency_key)   # Idempotency check first.

3. Job body runs within OTel span: job.class.name, space_id, idempotency_key.

4. Job logs to Audit if it modifies tenant data.
```

---

## Plugin Contract

A plugin is a gem with a `Pave::Plugin` manifest. It ships a Rails engine and
declares its dependencies upfront. The runtime validates them at boot.

```ruby
# In a plugin gem: lib/pave/plugins/whatsapp_channel.rb

module Pave
  module Plugins
    module WhatsappChannel
      extend Pave::Plugin

      plugin do |p|
        p.name         :whatsapp_channel
        p.version      "1.0.0"
        p.requires     [:tenancy, :billing, :audit]
        p.description  "WhatsApp messaging via Meta Cloud API with credit deduction"
      end

      # Called by Pave runtime after all modules initialize.
      def self.on_boot(runtime)
        runtime.backoffice.register(
          product: :anella,
          module:  :whatsapp_channel,
          label:   "WhatsApp",
          root:    "pave/plugins/whatsapp_channel/backoffice"
        )
      end
    end
  end
end
```

**What a plugin may do:**
- Add routes via its engine
- Contribute a Backoffice Module Panel
- Emit Audit events via `Pave::Audit.log`
- Deduct `Billing::MessageCredit` via the public Billing API
- Add background jobs
- Extend `Pave::Current` via its own `CurrentExtension`

**What a plugin may not do:**
- Skip Packwerk dependency declarations
- Access a product's private app/ internals
- Set `Current.space` (only Tenancy sets this)
- Directly query another module's tables

---

## Boundary Enforcement (Packwerk)

Every package declares what it depends on. Packwerk is the baseline boundary tool: it catches dependency/privacy violations early without changing normal Rails development. It is not treated as a complete runtime security boundary.

```yaml
# runtime/pave-core/package.yml
enforce_dependencies: true
enforce_privacy: true
dependencies: []          # Core has no Pavê deps. It is the base.
```

```yaml
# runtime/pave-tenancy/package.yml
enforce_dependencies: true
enforce_privacy: true
dependencies:
  - runtime/pave-core
```

```yaml
# runtime/pave-billing/package.yml
enforce_dependencies: true
enforce_privacy: true
dependencies:
  - runtime/pave-core
  - runtime/pave-tenancy
  - runtime/pave-audit      # Billing writes to Audit
```

```yaml
# products/anella/package.yml
enforce_dependencies: true
enforce_privacy: true
dependencies:
  - runtime/pave-core
  - runtime/pave-tenancy
  - runtime/pave-identity
  - runtime/pave-billing
  - runtime/pave-audit
  - runtime/pave-backoffice
```

**Public interface convention:**

- `lib/pave/<module>/` — public. Other packages may reference these.
- `app/` — private. Only accessible within the package.

`packwerk check` runs in CI once boundary enforcement is enabled. During extraction, violations may temporarily exist and become cleanup backlog; after Phase 7, a violation fails the build.

```bash
# packwerk.yml (root)
package_paths:
  - runtime/*
  - products/*
  - plugins/*

custom_associations: []
```

**Dependency graph (must be acyclic):**

```
pave-core
    ↑
pave-tenancy ←── pave-identity
    ↑                  ↑
pave-audit         pave-billing
    ↑                  ↑
pave-backoffice ────────┘
    ↑
products/* and plugins/*
```

No module depends on a product. No module depends on a plugin. Ever. Products may depend on runtime module public APIs, but runtime modules never reference product packages. If Packwerk proves insufficient later, add targeted tests or `bin/pave doctor` checks for the specific violation pattern instead of prematurely building a heavy runtime policing layer.

---

## bin/pave

The CLI. Executable at `bin/pave`. Implemented in Ruby (not shell).

```
bin/pave context                         # Full architecture context for an agent session
bin/pave context --module billing        # Scoped context: just billing module
bin/pave context --product anella        # Scoped context: anella product
bin/pave context --workflow new-job       # Context for a specific agent workflow

bin/pave doctor                          # Check for architectural violations:
                                         #   - Unscoped queries (Model.find outside tenant scope)
                                         #   - Current.space in background jobs
                                         #   - Missing idempotency_key in jobs
                                         #   - Audit gaps (write actions without audit call)
                                         #   - Packwerk violations

bin/pave new product <name>              # Scaffold and register a first-class product package
bin/pave install product <git-url>        # Clone/install a product package and register it
bin/pave link product <path>              # Register an existing local product package
bin/pave list products                    # List registered products and boot status
bin/pave new module <name>               # Scaffold a new core module in runtime/

bin/pave agent:workflow add-billing-gate # Step-by-step workflow:
                                         #   1. Identify the action boundary
                                         #   2. Add PlanEnforcer call in the service
                                         #   3. Emit audit event
                                         #   4. Block triggering UI element
                                         #   5. Write failing tests, then pass them

bin/pave agent:workflow new-job          # Scaffold idempotent tenant-aware job
bin/pave agent:workflow extract-service  # Guide extraction from controller to service
bin/pave agent:workflow new-module-panel # Scaffold Backoffice module panel
bin/pave agent:workflow add-plan-feature  # Add a plan feature and enforcement path

bin/pave test runtime/pave-billing       # Run tests for one module
bin/pave test products/anella            # Run tests for one product
bin/pave test                            # Run full suite
```

`bin/pave context` outputs a YAML + Markdown document that encodes:
- Which modules and products are active in this monorepo
- The runtime graph
- The public API surface of each active module
- Hard constraints (forbidden patterns with examples)
- Naming conventions
- Current working package/product (inferred from git branch name or explicit flags)
- Optional workflow-specific instructions when `--workflow` is provided

This output is task-scoped by default. It should fit in a single agent context
window while staying narrow enough that the agent is not carrying irrelevant
constraints for the task.

---

## Extraction Phases

Each phase produces a **bootable migration branch**. The existing production Anella can continue unchanged while Pavê is extracted off-production. The migrated product is deployed only after the runtime path is validated.

No production dual-write strategy is required for the first extraction. If shadow
checks are useful, they run in tests, staging, or local migration scripts. Billing
state changes must not be duplicated; when billing migrates, there is one
authoritative write path at a time.

### Phase 0: Monorepo scaffold (no extraction yet)

- Create the directory structure above.
- Set up Packwerk with empty package declarations for runtime modules and products.
- Implement Pavê product boot: product registry, namespace setup, autoload/eager-load roots, view roots, route loading, migration paths, and context registration.
- Set up the host app with no modules wired — it just boots.
- Wire `bin/pave` skeleton (commands defined, not yet implemented).
- Set up CI: `packwerk check`, `bin/pave doctor`, test suite.

**Exit criterion:** `rails s` starts. `packwerk check` passes. CI is green.

---

### Phase 1: pave-core

Extract from Anella: nothing yet. Write from scratch.

- `Pave::Current` with placeholder attributes.
- `Pave::Service` base class.
- Error hierarchy (`Pave::Error` and subclasses).
- `Pave::Plugin` DSL skeleton.
- `Pave::Registry` (module + product registration).
- `Pave.configure` block.
- `bin/pave` skeleton.

**No Anella code moves.** This phase is additive.

**Exit criterion:** pave-core gem loads. Anella can add it as a dependency and boot.

---

### Phase 2: pave-tenancy

Extract from Anella:
- `Space` model → `Pave::Tenancy::Space`
- `SpaceMembership` model → `Pave::Tenancy::SpaceMembership`
- `Spaces::BaseController` → `Pave::Tenancy::BaseController`
- Current.space wiring

Anti-contamination rule: `Pave::Tenancy::Space` has no Anella-specific columns.
Anella's CRM columns stay in `Anella::SpaceProfile` (STI or separate model joined to Space).

**Exit criterion:** Anella's tenant scoping runs through `Pave::Tenancy`. No direct
Space queries in Anella controllers.

---

### Phase 3: pave-audit

Extract from Anella:
- `AuditEvent` model → `Pave::Audit::Event`
- `Audit.log` interface

Audit is extracted before Identity and Billing because they both write to it.
Nothing reads Audit to make decisions — extraction is clean. Audit stores generic
actor, target, space, and source references so it does not depend on Identity or
Billing internals.

**Exit criterion:** All existing audit writes in Anella go through `Pave::Audit.log`.

---

### Phase 4: pave-identity

Extract from Anella:
- `User` model → `Pave::Identity::User`
- Session management → `Pave::Identity::SessionsController`
- Impersonation → `Pave::Identity::ImpersonationsController`
- Role resolution (via SpaceMembership)

Anti-contamination rule: Anella-specific user profile fields stay in
`Anella::UserProfile`, not on `Pave::Identity::User`.

**Exit criterion:** Authentication and impersonation run through pave-identity.
Impersonation writes to Audit via `Pave::Audit.log`.

---

### Phase 5: pave-billing

Extract from Anella:
- `Subscription`, `Plan`, `BillingEvent` → `Pave::Billing::*`
- `MessageCredit` → `Pave::Billing::Credit`
- `PlanEnforcer` → `Pave::Billing::PlanEnforcer`
- Provider adapter interface (Asaas is Anella-specific; Billing exposes the adapter slot)
- Webhook handler base

Anti-contamination rule: The Asaas adapter stays in `Anella::Billing::AsaasAdapter`,
not in pave-billing. Pave-billing defines the adapter interface; products implement it.

**Exit criterion:** `Pave::Billing::PlanEnforcer` enforces plan limits for Anella.
`BillingEvent` log is immutable and append-only.

---

### Phase 6: pave-backoffice

Extract from Anella:
- Platform Panel, Product Panel shells → pave-backoffice
- `Backoffice::BaseController`
- Breadcrumb and nav chrome

Anti-contamination rule: All Anella-specific module panels (Billing panel content,
Customer support panel) stay in `Anella::Backoffice::*`. Pave-backoffice provides
only the shell and the registration API.

**Exit criterion:** Anella's backoffice runs through pave-backoffice chrome.
All super-admin actions write to `Pave::Audit`.

---

### Phase 7: Packwerk enforcement ON

After all six modules are extracted:

- Enable `enforce_dependencies: true` and `enforce_privacy: true` in all `package.yml` files.
- Run `packwerk check`. Fix all violations.
- The violation list from this run becomes the tech debt backlog for Anella's internal cleanup.

**Exit criterion:** `packwerk check` passes with zero violations. CI enforces it on every PR.

---

## Hard Rules (Machine-Checkable via bin/pave doctor)

These are always wrong. `bin/pave doctor` flags all of them:

```
VIOLATION: Unscoped model query outside backoffice
  Pave::Tenancy::Space.find(id)       ← wrong
  Pave::Identity::User.find(id)       ← wrong
  current_space.appointments.find(id) ← correct

VIOLATION: Current.space in a background job
  Current.space                        ← wrong in job context
  Pave::Tenancy::Space.find(space_id) ← correct

VIOLATION: Audit missing on state-mutating super-admin action
  Any action in Backoffice:: that modifies tenant data without Pave::Audit.log

VIOLATION: BillingEvent updated
  BillingEvent.find(id).update(...)   ← always wrong. Append-only.

VIOLATION: credentials in ENV
  ENV["ASAAS_API_KEY"]                ← wrong
  Rails.application.credentials.asaas ← correct

VIOLATION: render 200 after form POST
  render :new, status: :ok after POST  ← wrong. Turbo expects redirect.
  redirect_to ..., status: :see_other  ← correct
```

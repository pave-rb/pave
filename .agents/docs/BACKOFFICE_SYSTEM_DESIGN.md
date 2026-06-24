# pave-backoffice — System Design

**Scope:** This document designs the routing, controller architecture, panel
registration, and settings/credentials model for `pave-backoffice`. UX and visual
design are out of scope and handled separately.

---

## Requirements

### Functional

- The backoffice boots and is usable with zero products installed.
- Super admins can access the backoffice from a single, predictable URL (`/admin` by default).
- The backoffice has two distinct operational contexts: **Platform** (cross-product) and **Product** (scoped to one registered product).
- Runtime modules (tenancy, identity, billing, audit) contribute their own Platform panels.
- Products register Product panels declaratively from inside the product directory.
- Plugins register panels at boot via the plugin `on_boot` hook.
- Every state-mutating action in the backoffice writes an `Pave::Audit` event.
- No backoffice controller ever sets or reads `Current.space`. Backoffice is explicitly opt-out of tenant scoping.
- **Future (Phase: pave-settings):** A credential and settings management UI replaces the need to edit local Rails credential files and redeploy to change integration keys.

### Non-functional

- Route names must not collide between platform and product segments.
- Route drawing must not fail if a product is registered but its panel controller does not yet exist (boot-time check, not a route error).
- Adding a new product panel requires no changes to `pave-backoffice` source.
- Adding a new platform panel (from a runtime module) requires no changes to any product.

### Constraints

- Rails engine with `isolate_namespace`. All routes and helpers are engine-scoped.
- Mount point is configurable but defaults to `/admin`.
- Packwerk dependency: `pave-backoffice` depends on `pave-core`, `pave-tenancy`, `pave-identity`, `pave-audit`, and `pave-billing`. No product dependency ever.

---

## Architecture Overview

```
Pave::Backoffice::Engine (mounted at /admin)
│
├── Platform Context
│   ├── Dashboard          (pave-backoffice, always present)
│   ├── Users panel        (contributed by pave-identity)
│   ├── Audit panel        (contributed by pave-audit)
│   ├── Billing overview   (contributed by pave-billing)
│   └── Settings / Creds   (pave-settings, future)
│
└── Product Context (one per registered product)
    ├── Product Dashboard  (pave-backoffice provides shell)
    └── Module Panels      (product-owned + plugin-owned content)
        e.g. Anella: Billing panel, Spaces panel, WhatsApp panel (plugin)
```

Two-layer separation: Pavê owns the chrome (authentication, breadcrumb, nav shell,
audit hooks). Products and modules own all content inside panels.

---

## Routing

### Mount Point

```ruby
# config/routes.rb (host app)
mount Pave::Backoffice::Engine, at: "/admin", as: :pave_backoffice
```

Configurable via `Pave.configure`:

```ruby
Pave.configure do |c|
  c.backoffice_path "/admin"   # default
end
```

### Platform Routes (always drawn)

```
GET  /admin                           → platform/dashboard#show
GET  /admin/users                     → platform/users#index
GET  /admin/users/:id                 → platform/users#show
GET  /admin/audit                     → platform/audit_events#index
GET  /admin/settings                  → platform/settings#show
PATCH /admin/settings                 → platform/settings#update
```

These routes are hardcoded in the engine's `routes.rb` and are always available,
regardless of the product registry state.

### Product Routes (drawn at boot, per registered product)

```
GET  /admin/:product                              → products/dashboard#show
GET  /admin/:product/:panel                       → [panel's default controller]#index
     + any panel-specific routes declared in the panel's route block
```

Examples for a deployed Anella:

```
GET  /admin/anella                                → Anella product dashboard
GET  /admin/anella/billing                        → Anella::Backoffice::BillingController#index
GET  /admin/anella/billing/plans                  → Anella::Backoffice::PlansController#index
GET  /admin/anella/billing/plans/:id              → Anella::Backoffice::PlansController#show
GET  /admin/anella/spaces                         → Anella::Backoffice::SpacesController#index
GET  /admin/anella/whatsapp                       → Plugin panel (whatsapp_channel)
```

### Reserved Route Names

The following `:product` slug values are reserved and rejected at boot:

```
users, audit, settings, credentials, health, platform
```

`bin/pave doctor` validates product name against this list. Attempting to register a
product with a reserved name raises `Pave::Backoffice::ReservedNameError` at boot.

### Route Drawing Mechanism

The engine's `routes.rb` delegates product route drawing to the registry after
platform routes are defined. By the time Rails draws routes, `Pave.configure` has
already been evaluated (it runs in `config/pave.rb`, required from
`config/application.rb`), so the registry is fully populated.

```ruby
# runtime/pave-backoffice/config/routes.rb

Pave::Backoffice::Engine.routes.draw do
  # Platform routes — always present
  root to: "platform/dashboard#show"

  resources :users, only: [:index, :show], controller: "platform/users"
  resources :audit_events, only: [:index], controller: "platform/audit_events"
  resource  :settings, only: [:show, :update], controller: "platform/settings"

  # Product routes — drawn per registered product
  Pave::Backoffice::RouteDrawer.draw(self)
end
```

```ruby
# runtime/pave-backoffice/lib/pave/backoffice/route_drawer.rb

module Pave
  module Backoffice
    module RouteDrawer
      def self.draw(router)
        Pave.registry.products.each do |product|
          router.scope "/#{product.name}" do
            # Product dashboard
            router.get "/", to: "products/dashboard#show",
                            defaults: { product_id: product.name.to_s },
                            as: :"backoffice_#{product.name}"

            # Panel routes
            product.backoffice_panels.each do |panel|
              router.scope "/#{panel.slug}" do
                if panel.route_block
                  router.instance_exec(&panel.route_block)
                else
                  router.get "/", to: "#{panel.controller}#index",
                                  defaults: { product_id: product.name.to_s },
                                  as: :"backoffice_#{product.name}_#{panel.slug}"
                end
              end
            end
          end
        end
      end
    end
  end
end
```

---

## Controller Architecture

### Hierarchy

```
ApplicationController
└── Pave::Backoffice::BaseController
      ├── Pave::Backoffice::Platform::BaseController
      │     ├── Platform::DashboardController
      │     ├── Platform::UsersController
      │     ├── Platform::AuditEventsController
      │     └── Platform::SettingsController
      └── Pave::Backoffice::Products::BaseController
            └── [Product panel controllers, e.g.]
                Anella::Backoffice::BillingController
                Anella::Backoffice::SpacesController
```

### `Pave::Backoffice::BaseController`

The root. Owned by `pave-backoffice`. All backoffice controllers inherit this.

Responsibilities:
- Authenticate `current_user.super_admin?`. Non-super-admins receive 403.
- Explicitly opt out of tenant scoping: `skip_before_action :set_space!` and assert
  `Current.space.nil?` in an around-action (raises if something upstream sets it).
- Expose breadcrumb helpers and nav context to views.
- Provide `audit_admin(event_type, target:, metadata: {})` helper used by subclasses.
- Define the layout: `pave/backoffice/application`.

```ruby
# runtime/pave-backoffice/app/controllers/pave/backoffice/base_controller.rb

module Pave
  module Backoffice
    class BaseController < ApplicationController
      layout "pave/backoffice/application"

      before_action :require_super_admin!
      around_action :assert_no_tenant_scope!

      helper_method :current_admin, :backoffice_nav

      private

      def require_super_admin!
        render "pave/backoffice/errors/forbidden", status: :forbidden unless current_user&.super_admin?
      end

      def assert_no_tenant_scope!
        yield
      ensure
        raise Pave::Backoffice::TenantScopeLeakError if Pave::Current.space.present?
      end

      def audit_admin(event_type, target:, metadata: {})
        Pave::Audit.log(
          actor:        current_user,
          event_type:   event_type,
          target:       target,
          space:        nil,
          metadata:     metadata,
          source:       :backoffice
        )
      end

      def current_admin
        current_user
      end

      def backoffice_nav
        @backoffice_nav ||= Pave::Backoffice::NavContext.new(
          platform_panels: Pave::Backoffice.registry.platform_panels,
          products:         Pave.registry.products
        )
      end
    end
  end
end
```

### `Pave::Backoffice::Platform::BaseController`

Platform context. No product scope. Sees across all tenants and all products.

```ruby
module Pave
  module Backoffice
    module Platform
      class BaseController < Pave::Backoffice::BaseController
        # No additional before_actions.
        # All platform controllers operate with global scope.
        # Explicit unscoped queries are permitted here and only here.
      end
    end
  end
end
```

### `Pave::Backoffice::Products::BaseController`

Product context. Sets `current_product` from the `:product_id` route default. Used
by all product panel controllers.

```ruby
module Pave
  module Backoffice
    module Products
      class BaseController < Pave::Backoffice::BaseController
        before_action :set_current_product!

        helper_method :current_product

        private

        def set_current_product!
          product_id = params[:product_id] || request.path_parameters[:product_id]
          @current_product = Pave.registry.product(product_id&.to_sym)
          render "pave/backoffice/errors/not_found", status: :not_found unless @current_product
        end

        def current_product
          @current_product
        end
      end
    end
  end
end
```

### Product Panel Controllers

Product panel controllers inherit from `Products::BaseController`. They live inside
the product package and are NOT part of `pave-backoffice`.

```ruby
# products/anella/app/controllers/backoffice/billing_controller.rb

module Anella
  module Backoffice
    class BillingController < Pave::Backoffice::Products::BaseController
      def index
        @plans = Pave::Billing::Plan.all.order(:name)
      end

      def update_plan
        plan = Pave::Billing::Plan.find(params[:id])
        plan.update!(plan_params)
        audit_admin(:plan_updated, target: plan, metadata: { changes: plan.previous_changes })
        redirect_to backoffice_anella_billing_path, status: :see_other
      end

      private

      def plan_params
        params.require(:plan).permit(:name, :price_cents, :member_limit, features: [])
      end
    end
  end
end
```

---

## Panel Registration

### Product Panels

Products declare their backoffice panels in `products/<name>/config/backoffice.rb`.
Pavê product boot loads this file if it exists, after the product is registered.

```ruby
# products/anella/config/backoffice.rb

Pave::Backoffice.product(:anella) do |b|
  b.panel :billing,
    label:      "Billing",
    controller: "anella/backoffice/billing",
    routes: -> {
      resources :plans
      resources :subscriptions, only: [:index, :show] do
        post :cancel, on: :member
      end
    }

  b.panel :spaces,
    label:      "Spaces",
    controller: "anella/backoffice/spaces",
    routes: -> {
      resources :spaces, only: [:index, :show]
    }
end
```

If `backoffice.rb` does not exist, no panels are registered for that product. The
product dashboard still loads (it shows "no panels registered").

### Platform Panels (from Runtime Modules)

Runtime modules contribute platform panels in their engine initializer. These appear
in the platform-level navigation, not under any product.

```ruby
# runtime/pave-identity/lib/pave/identity/engine.rb

initializer "pave.identity.backoffice" do
  Pave::Backoffice.platform_panel(:users,
    label:      "Users",
    controller: "pave/identity/backoffice/users",
    routes: -> { resources :users, only: [:index, :show] }
  )
end

# runtime/pave-audit/lib/pave/audit/engine.rb

initializer "pave.audit.backoffice" do
  Pave::Backoffice.platform_panel(:audit,
    label:      "Audit Log",
    controller: "pave/audit/backoffice/audit_events",
    routes: -> { resources :audit_events, only: [:index, :show] }
  )
end

# runtime/pave-billing/lib/pave/billing/engine.rb

initializer "pave.billing.backoffice" do
  Pave::Backoffice.platform_panel(:billing,
    label:      "Billing",
    controller: "pave/billing/backoffice/overview",
    routes: -> {
      resource :overview, only: :show, controller: "pave/billing/backoffice/overview"
    }
  )
end
```

### Plugin Panels

Plugins register panels in `on_boot`, which runs after all module initializers:

```ruby
# plugins/whatsapp_channel

def self.on_boot(runtime)
  runtime.backoffice.product_panel(:anella, :whatsapp,
    label:      "WhatsApp",
    controller: "pave/plugins/whatsapp_channel/backoffice",
    routes: -> {
      resources :message_templates, only: [:index, :show]
      resource  :webhook_config, only: [:show, :update]
    }
  )
end
```

### Panel Data Model (in-memory, not persisted)

The registry holds panel registrations in memory. Panels are not stored in the
database — they are declared code, not runtime configuration.

```ruby
module Pave
  module Backoffice
    Panel = Data.define(:name, :label, :controller, :route_block, :position) do
      def slug = name.to_s.dasherize
    end

    class Registry
      attr_reader :platform_panels, :product_panels

      def initialize
        @platform_panels = []
        @product_panels  = Hash.new { |h, k| h[k] = [] }
      end

      def register_platform_panel(name, label:, controller:, routes: nil, position: 99)
        @platform_panels << Panel.new(
          name: name, label: label, controller: controller,
          route_block: routes, position: position
        )
      end

      def register_product_panel(product_name, name, label:, controller:, routes: nil, position: 99)
        @product_panels[product_name] << Panel.new(
          name: name, label: label, controller: controller,
          route_block: routes, position: position
        )
      end
    end
  end
end
```

---

## Settings & Credentials

### Problem

Rails credentials (`config/credentials.yml.enc`) require a local master key, a
re-encrypt step, and a redeploy to change any value in production. For integration
keys (payment provider API keys, WhatsApp tokens, SMTP credentials) that change
without code changes, this is unnecessary friction.

### Solution: `pave-settings` (designed now, extracted as separate module later)

A database-backed settings store with:
- Encrypted values at the row level (using Active Record Encryption)
- Per-namespace schema declared by modules
- Fallback to `Rails.application.credentials` for cold-start (first boot before DB is migrated)
- Backoffice UI auto-generated from the schema declaration
- All writes audited

This is initially implemented inside `pave-backoffice` and extracted to a standalone
`pave-settings` module when it warrants distribution.

### Settings Interface

```ruby
# Public API — how modules read settings at runtime

Pave::Settings.get(:billing, :api_key)
# → DB value if set, else Rails.application.credentials.dig(:billing, :api_key), else nil

Pave::Settings.get!(:billing, :api_key)
# → raises Pave::Settings::MissingSettingError if neither source has a value
```

Modules use this instead of calling `Rails.application.credentials` directly.
The fallback makes migration transparent: existing deployments continue working with
credential files until a super admin sets values in the backoffice.

### Schema Declaration

Modules declare their settings schema in their engine initializer. This drives
validation and auto-generates the backoffice settings form.

```ruby
# runtime/pave-billing/lib/pave/billing/engine.rb

initializer "pave.billing.settings" do
  Pave::Settings.define(:billing) do |s|
    s.key :provider_adapter,
      type:        :string,
      description: "Adapter class name (e.g. Anella::Billing::AsaasAdapter)",
      required:    true

    s.key :webhook_secret,
      type:        :string,
      encrypted:   true,
      description: "Webhook signature secret from provider dashboard"
  end
end
```

Plugins declare their settings similarly:

```ruby
# in whatsapp_channel plugin's on_boot

runtime.settings.define(:whatsapp_channel) do |s|
  s.key :access_token,   type: :string, encrypted: true
  s.key :app_secret,     type: :string, encrypted: true
  s.key :verify_token,   type: :string, encrypted: true
  s.key :phone_number_id, type: :string
end
```

### Data Model

```ruby
# Migration owned by pave-backoffice (or pave-settings)
create_table :pave_settings do |t|
  t.string  :namespace,   null: false
  t.string  :key,         null: false
  t.text    :value        # encrypted via Active Record Encryption
  t.string  :value_type,  null: false, default: "string"
  t.bigint  :updated_by_id
  t.timestamps

  t.index [:namespace, :key], unique: true
end
```

`value` is encrypted using `encrypts :value` (Active Record Encryption, available
since Rails 7.0). The DB never holds plaintext for encrypted keys.

### Fallback Chain

```
Pave::Settings.get(namespace, key)
  1. Query pave_settings WHERE namespace = ? AND key = ?
  2. If not found → Rails.application.credentials.dig(namespace, key)
  3. If not found → nil (or raise for .get!)
```

Step 2 ensures zero-downtime migration: existing apps with credential files continue
to work, and super admins can migrate keys to the database gradually.

### Backoffice Integration

The Platform Settings controller reads the declared schema and renders a form per
namespace. On save, it writes to `pave_settings` and emits an audit event.

```ruby
# pave-backoffice: Platform::SettingsController

def update
  namespace = params[:namespace]
  schema    = Pave::Settings.schema_for(namespace)

  schema.keys.each do |setting_key|
    next unless params.key?(setting_key.name)
    Pave::Settings.set(namespace, setting_key.name,
                       value:      params[setting_key.name],
                       updated_by: current_user)
  end

  audit_admin(:settings_updated, target: nil, metadata: { namespace: namespace })
  redirect_to backoffice_settings_path(namespace: namespace), status: :see_other
end
```

---

## Boot Sequence

```
1. config/pave.rb evaluates → Pave.configure block runs:
     - Products registered in Pave.registry
     - Module list resolved

2. Rails initializers run (alphabetical within each engine):
     - pave-identity initializer registers platform panel :users
     - pave-audit initializer registers platform panel :audit
     - pave-billing initializer registers platform panel :billing + declares settings schema
     - pave-backoffice initializer:
         * validates product names against reserved list
         * loads products/<name>/config/backoffice.rb for each registered product
         * calls on_boot for all registered plugins (plugin panels registered here)

3. Rails routes are drawn:
     - pave-backoffice engine routes.rb runs
     - RouteDrawer iterates Pave.registry.products and registered panels
     - Product routes injected per product name

4. App boots. /admin is reachable.
   If Pave.registry.products is empty → Platform dashboard renders "no products installed."
```

---

## Empty State

When no products are registered:

- `/admin` loads the Platform dashboard. It renders a "No products installed" card.
- Platform panels (Users, Audit, Billing Overview, Settings) are still accessible.
- Product route segments do not exist (none drawn), returning 404 for `/admin/*` paths.
- The Platform dashboard links to `bin/pave new product <name>` docs to guide setup.

The super admin session and authentication work independently of product registration.
`pave-identity` is a runtime module, not a product — its backoffice panel is always present.

---

## Audit Contract

Every state-mutating action in any backoffice controller must call `audit_admin`.
`bin/pave doctor` flags controllers under `Backoffice::` that define non-GET actions
without an `audit_admin` call in the action body.

Required audit events:

| Action | Event Type | Target |
|---|---|---|
| Settings updated | `:backoffice_settings_updated` | nil (namespace in metadata) |
| Plan created / updated | `:plan_created`, `:plan_updated` | `Pave::Billing::Plan` |
| User super_admin flag changed | `:super_admin_granted`, `:super_admin_revoked` | `Pave::Identity::User` |
| Impersonation started | `:impersonation_started` | `Pave::Identity::User` |
| Subscription state forced | `:subscription_state_forced` | `Pave::Billing::Subscription` |

Product panel controllers extend this list for their own domain actions.

---

## Trade-offs & Open Questions

**1. Route drawing at boot vs. route files per product**

Dynamic route drawing (`RouteDrawer`) is simpler for product authors (no route
wiring needed) but means routes are re-drawn on every Rails reload in development.
This is acceptable because route reload is cheap and already happens on any
`routes.rb` change. Alternative (each product has its own `config/routes.rb`
fragment appended by Pavê) is more explicit but requires more plumbing.
Decision: `RouteDrawer` for now; revisit if route reload causes measurable
development friction.

**2. Settings in pave-backoffice vs. pave-settings**

Keeping settings in `pave-backoffice` is simpler for Phase 6. The problem: modules
need to READ settings at runtime, not just in the backoffice. `pave-billing` calling
`Pave::Settings.get(...)` would create a `pave-billing → pave-backoffice` dependency,
which inverts the dependency graph.

Decision: implement `Pave::Settings` interface in `pave-core` (no DB, just the
interface + fallback to Rails credentials). `pave-backoffice` owns the DB-backed
implementation and wires it in its engine initializer. Modules depend only on
`pave-core`'s interface.

**3. Products::BaseController sets `current_product` from route defaults**

Route defaults (`:product_id`) require that every product panel route is drawn with
`defaults: { product_id: "anella" }`. This is handled by `RouteDrawer` centrally.
Product controllers should not infer product context from the URL string — always
use the `current_product` helper.

**4. Platform panels declared in engine initializers vs. `Pave.configure`**

Engine initializers are the right place: they fire after `config/application.rb`
and before routes are drawn, and they keep module-owned platform panel registration
inside the module gem. Declaring them in `pave.rb` would leak module specifics into
host config. Initializers are the correct Rails extension point here.

**5. Credentials cold-start for first-ever deploy**

On a brand-new deploy with an empty `pave_settings` table, everything falls back to
Rails credentials. This is correct. The backoffice settings UI then acts as a migration
path to move values to DB over time. There is no forced migration.

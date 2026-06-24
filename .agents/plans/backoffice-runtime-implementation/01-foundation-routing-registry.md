# 01. Foundation, Routing, And Registry

## Goal

Make `runtime/pave-backoffice` the authoritative isolated Rails engine mounted at `/admin` by default, with static Platform routes and boot-drawn Product routes from a registry.

## Deliverables

- Configurable backoffice mount path with `/admin` default.
- Engine-owned route file and route names that do not collide across Platform and Product contexts.
- Registry API for platform panels, product panels, source metadata, ordering, and diagnostics.
- Route drawer that tolerates missing panel controllers without breaking route drawing.
- Reserved product slug validation.
- Product backoffice config loader for `products/<name>/config/backoffice.rb`.
- Plugin boot hook integration for panel registration.

## Work Items

### F1. Add Backoffice Mount Configuration

- Add `Pave::Configuration#backoffice_path` with default `"/admin"`.
- Mount `Pave::Backoffice::Engine` from the host route file using the configured path.
- Keep `/admin` as the primary URL. Do not introduce `/admin/platform` as a primary route.
- Do not add `/backoffice` compatibility unless production deployments require it explicitly. If required, implement short-lived redirects as a separate migration task.

### F2. Add Engine Routes

Target file: `runtime/pave-backoffice/config/routes.rb`

Required routes:

```ruby
Pave::Backoffice::Engine.routes.draw do
  get    "sign_in",  to: "sessions#new",     as: :sign_in
  post   "sign_in",  to: "sessions#create"
  delete "sign_out", to: "sessions#destroy", as: :sign_out

  root to: "platform/dashboard#show"

  resources :users, only: %i[index show], controller: "platform/users" do
    patch :grant_super_admin, on: :member
    patch :revoke_super_admin, on: :member
  end

  get "audit", to: "platform/audit_events#index", as: :audit
  resource :settings, only: %i[show update], controller: "platform/settings"

  Pave::Backoffice::RouteDrawer.draw(self)
end
```

Notes:

- The mutating user routes exist only when the controller implements audited grant/revoke behavior.
- Platform route paths must remain `/admin/users`, `/admin/audit`, and `/admin/settings`.
- Product routes must be drawn after Platform routes.

### F3. Validate Reserved Product Names

Reserved product slugs:

```txt
users, audit, settings, credentials, health, platform
```

Implementation tasks:

- Add `Pave::Backoffice::ReservedNameError`.
- Validate registered product keys during backoffice boot.
- Add `bin/pave doctor` validation for reserved product slugs.
- Add tests for each reserved value and at least one valid product slug.

### F4. Replace Flat Panel Registry

Current registry stores a flat `panels_by_key` list. Replace it with explicit context-aware registries.

Target API:

```ruby
Pave::Backoffice.platform_panel(:users,
  label: "Users",
  controller: "pave/identity/backoffice/users",
  routes: -> { resources :users, only: %i[index show] },
  source: :runtime_module,
  source_package: "pave-identity",
  position: 10
)

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

Panel metadata to support UX:

```ruby
Panel = Data.define(
  :name,
  :label,
  :controller,
  :route_block,
  :position,
  :source,
  :source_package,
  :description,
  :status,
  :diagnostics
)
```

Required behavior:

- `panel.slug` returns `name.to_s.dasherize`.
- Duplicate panel slugs are rejected within the same context.
- Platform panels and product panels can share slugs because their route contexts differ.
- Panels are ordered by `position`, then `label`, then slug.
- Missing optional metadata gets safe defaults.

### F5. Add Navigation Context

Replace the current flat `Pave::Backoffice::Navigation` output with a context object.

Target object:

```ruby
Pave::Backoffice::NavContext.new(
  platform_panels: Pave::Backoffice.registry.platform_panels,
  products: Pave.registry.products,
  product_panels: Pave::Backoffice.registry.product_panels
)
```

Responsibilities:

- Return platform navigation separately from products navigation.
- Expand only the selected product in the sidebar.
- Provide selected context metadata for top bar, sidebar, breadcrumbs, and page header.
- Never mix product panels into the Platform group.

### F6. Implement Route Drawer

Target file: `runtime/pave-backoffice/lib/pave/backoffice/route_drawer.rb`

Behavior:

- Iterate registered products from `Pave.registry.products` or the current `Pave.products` registry bridge.
- Draw `/admin/:product` to `products/dashboard#show` with `defaults: { product_id: product.key.to_s }`.
- Draw each registered product panel under `/admin/:product/:panel`.
- If a panel provides a route block, instance-exec it inside the panel scope.
- If a panel has no route block, draw `GET /` to the panel default controller index action.
- Add route defaults for `product_id` and `panel_id` centrally.

Controller-missing behavior:

- Route drawing must not raise when a registered panel controller is missing.
- Add boot validation that records diagnostics on the panel.
- Draw unavailable panels to a backoffice-owned fallback controller or render a graceful unavailable page from `Products::BaseController`.
- Make `bin/pave doctor` fail for missing panel controllers.

### F7. Implement Boot Sequence

Engine initializer order:

1. Validate reserved product slugs.
2. Register core Platform panels owned by backoffice itself.
3. Allow runtime modules to register Platform panels in their engine initializers.
4. Load `products/<product>/config/backoffice.rb` for every registered product when present.
5. Run plugin `on_boot` hooks so plugins can register product panels.
6. Freeze or finalize registry before route drawing.
7. Route drawer reads finalized registry.

Add diagnostics:

- Duplicate panel slug.
- Missing controller.
- Missing route block for non-index controller.
- Reserved product name.
- Product config file load error.
- Plugin registration error.

### F8. Foundation Tests

Add or replace tests in `test/lib` and `test/integration`:

- Registry accepts valid platform and product panels.
- Registry rejects duplicate slugs within context.
- Registry allows same slug across platform and product contexts.
- Reserved product names raise `ReservedNameError`.
- Route drawer draws Platform routes with no products.
- Route drawer draws Product dashboard and panel routes for a registered product.
- Missing panel controller records diagnostics without breaking route drawing.
- Navigation context separates Platform and Product groups.

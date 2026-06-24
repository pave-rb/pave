# pave-backoffice — Admin UI Chrome

## Purpose

Provides the super-admin backoffice UI chrome: panel registration, navigation, breadcrumbs, authentication contract, and health checks.

## Public API

```ruby
Pave::Backoffice::BaseController        # Backoffice base controller
Pave::Backoffice::Panel.register(...)    # Register a backoffice panel
Pave::Backoffice::Navigation             # Navigation builder
Pave::Backoffice::Breadcrumbs            # Breadcrumb trail
Pave::Backoffice::Authentication         # Super admin auth contract
Pave::Backoffice::Doctor                 # Health checks
Pave::Backoffice::ProductConfigLoader    # Product config loading
Pave::Backoffice::ProductValidator       # Product validation
Pave::Backoffice::Registry               # Panel registry
Pave::Backoffice::RouteDrawer            # Route generation
Pave::Backoffice::SettingsAdapter        # Settings interface
```

## Panel Registration

```ruby
Pave::Backoffice::Panel.register :dashboard, namespace: :demo_scheduling, type: :product do |panel|
  panel.label "Dashboard"
  panel.icon "chart-bar"
end
```

## Dependencies

- pave-core
- pave-tenancy
- pave-audit
- pave-identity
- pave-billing

## Testing

Tests use `DemoScheduling` as the test product for backoffice panel tests.

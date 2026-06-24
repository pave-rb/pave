# DemoScheduling — Dummy Product

A minimal dummy product exercising Pavê runtime contracts.

Purpose: test product boot, routes, migrations, backoffice panels, and service
objects without bringing real application logic into the runtime monorepo.

## Runtime Contracts Exercised

- Product registration via `Pave.configure`
- Product autoload paths, view paths, migration paths
- Product backoffice panel registration
- Product route drawing
- Service object inheriting from `Pave::Service`
- Model with ActiveRecord concerns
- Backoffice controller inheriting from `Pave::Backoffice::Products::BaseController`

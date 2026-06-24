# Pavê Runtime

**Pavê is a Rails-native business runtime for building modular SaaS and business applications.**

It extends Ruby on Rails with reusable business modules, first-class products, and a runtime designed to reduce the amount of infrastructure every new application needs to rebuild.

> **Status:** Early development. APIs, architecture, and documentation are evolving.

## Installation

In a Rails host app, add to your Gemfile:

```ruby
gem "pave"
```

Then run:

```bash
bundle install
bin/rails generate pave:install
bin/pave doctor
```

For internal/private development, you can also consume gems via local path:

```ruby
gem "pave-core", path: "../pave/gems/pave-core"
gem "pave-rails", path: "../pave/gems/pave-rails"
# ... etc
```

Or via Git tag:

```ruby
git_url = "git@github.com:pave-rb/pave.git"
git_tag = "v0.1.0-internal"

gem "pave", git: git_url, tag: git_tag, glob: "gems/pave/pave.gemspec"
gem "pave-core", git: git_url, tag: git_tag, glob: "gems/pave-core/pave-core.gemspec"
gem "pave-rails", git: git_url, tag: git_tag, glob: "gems/pave-rails/pave-rails.gemspec"
gem "pave-tenancy", git: git_url, tag: git_tag, glob: "gems/pave-tenancy/pave-tenancy.gemspec"
gem "pave-identity", git: git_url, tag: git_tag, glob: "gems/pave-identity/pave-identity.gemspec"
gem "pave-audit", git: git_url, tag: git_tag, glob: "gems/pave-audit/pave-audit.gemspec"
gem "pave-billing", git: git_url, tag: git_tag, glob: "gems/pave-billing/pave-billing.gemspec"
gem "pave-backoffice", git: git_url, tag: git_tag, glob: "gems/pave-backoffice/pave-backoffice.gemspec"
```

**Note:** Bundler does **not** forward `glob` from gems declared inside a `git` block. Use per-gem `git:` with `glob:` instead. See `docs/host_app_consumption.md` for full details.

## Quick Start

```bash
# Create a new product
bin/pave new product my_product

# List registered products
bin/pave list products

# Run health checks
bin/pave doctor

# Generate agent context
bin/pave context
```

## Repository

This **monorepo** produces the Pavê runtime gems. It is not a deployable host app.
Host apps consume Pavê through Bundler.

### Gems

```
gems/pave              — Meta-gem (default dependency)
gems/pave-core         — Pure Ruby runtime contracts
gems/pave-rails        — Rails integration, generators
gems/pave-tenancy      — Multi-tenancy (Space, request lifecycle)
gems/pave-identity     — Users, sessions, roles
gems/pave-billing      — Provider-neutral billing primitives
gems/pave-audit        — Immutable audit log
gems/pave-backoffice   — Admin UI chrome
gems/pave-hotwire      — Hotwire helpers (planned)
gems/pave-agent        — Agent context (planned)
```

## License

MIT License.

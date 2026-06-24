# Host App Consumption Guide

This document describes how a Rails host app consumes Pavê runtime gems.

---

## Dependency modes

### 1. Local path development

Use during active Pavê development alongside a host app:

```ruby
# Gemfile
gem "pave", path: "../pave/gems/pave"
gem "pave-core", path: "../pave/gems/pave-core"
gem "pave-rails", path: "../pave/gems/pave-rails"
gem "pave-tenancy", path: "../pave/gems/pave-tenancy"
gem "pave-identity", path: "../pave/gems/pave-identity"
gem "pave-audit", path: "../pave/gems/pave-audit"
gem "pave-billing", path: "../pave/gems/pave-billing"
gem "pave-backoffice", path: "../pave/gems/pave-backoffice"
```

Run:

```bash
bundle install
bin/rails generate pave:install
bin/rails db:create db:migrate
bin/pave doctor
```

### 2. Git tag consumption (internal)

Use when Pavê is consumed from Git during internal development:

```ruby
# Gemfile
git "git@github.com:pave-rb/pave.git", tag: "v0.1.0.alpha.2" do
  gem "pave",            glob: "gems/pave/*.gemspec"
  gem "pave-core",       glob: "gems/pave-core/*.gemspec"
  gem "pave-rails",      glob: "gems/pave-rails/*.gemspec"
  gem "pave-tenancy",    glob: "gems/pave-tenancy/*.gemspec"
  gem "pave-identity",   glob: "gems/pave-identity/*.gemspec"
  gem "pave-audit",      glob: "gems/pave-audit/*.gemspec"
  gem "pave-billing",    glob: "gems/pave-billing/*.gemspec"
  gem "pave-backoffice", glob: "gems/pave-backoffice/*.gemspec"
end
```

Do not use `branch: "main"` for production host apps. Always pin to a tag or a released gem version.

Run:

```bash
bundle install
bin/rails generate pave:install
bin/rails db:create db:migrate
bin/pave doctor
```

### 3. RubyGems (future)

Once published:

```ruby
gem "pave", "~> 0.5"
```

---

## Installation commands

```bash
# Add Pavê to an existing Rails app
bundle add pave

# Run the install generator
bin/rails generate pave:install

# Create and migrate database
bin/rails db:create db:migrate

# Verify the installation
bin/pave doctor
```

---

## Product registration

After installation, register a product package:

```bash
bin/pave new product my_product
```

This creates a product under `products/my_product/` with a manifest, controller, model, and service scaffold.

List registered products:

```bash
bin/pave list products
```

---

## Commands reference

| Command | Description |
|---|---|
| `bin/pave help` | Show help |
| `bin/pave version` | Print Pavê runtime version |
| `bin/pave doctor` | Run health checks |
| `bin/pave doctor --upgrade` | Print upgrade checks |
| `bin/pave context` | Generate agent context snapshot |
| `bin/pave new product <name>` | Generate a product scaffold |
| `bin/pave list products` | List registered products |
| `bin/pave install:migrations` | Copy engine migrations |
| `bin/pave upgrade` | Upgrade plan |
| `bin/pave app:update` | Host app config update |

---

## Gem dependency graph

```
pave-core (pure Ruby, no Rails dependency)
    ↑
pave-rails (Rails integration, generators)
    ↑
pave-tenancy ←── pave-identity
    ↑                  ↑
pave-audit         pave-billing
    ↑                  ↑
pave-backoffice ────────┘
    ↑
products/* and plugins/*
```

The `pave` meta-gem depends on all of the above and is the recommended single entry point.

---

## Upgrade flow

```bash
bundle update pave
bin/pave upgrade
bin/pave doctor
```

---

## Temporary smoke test

To validate consumption from scratch:

```bash
rails new pave-smoke-host --skip-bundle
cd pave-smoke-host
# Add gem dependencies (see sections above)
bundle install
bin/rails generate pave:install
bin/rails db:create db:migrate
bin/pave doctor
bin/pave context
bin/rails runner "puts Pave::VERSION"
```

# Pavê Runtime

**Pavê is a Rails-native business runtime for building modular SaaS and business applications.**

It extends Ruby on Rails with reusable business modules, first-class products, and a runtime designed to reduce the amount of infrastructure every new application needs to rebuild.

## Status

Early internal runtime extraction. APIs, install flow, and packaging are unstable. Do not use in production.

## Current Internal Consumption

Pavê is not yet published to RubyGems. Consume it from a local path or a Git tag during internal development.

### Local path development

```ruby
gem "pave", path: "../pave/gems/pave"
gem "pave-core", path: "../pave/gems/pave-core"
gem "pave-rails", path: "../pave/gems/pave-rails"
gem "pave-tenancy", path: "../pave/gems/pave-tenancy"
gem "pave-identity", path: "../pave/gems/pave-identity"
gem "pave-audit", path: "../pave/gems/pave-audit"
gem "pave-billing", path: "../pave/gems/pave-billing"
gem "pave-backoffice", path: "../pave/gems/pave-backoffice"
```

### Git tag consumption (internal)

```ruby
git "git@github.com:pave-rb/pave.git", tag: "v0.1.0.alpha.1" do
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

Do not consume `branch: "main"` in production host apps. Use an explicit tag or a released gem version.

## Planned Public Installation

Once Pavê is published to RubyGems, the public install flow will be:

```ruby
gem "pave"
```

```bash
bundle install
bin/rails generate pave:install
bin/pave doctor
```

This flow is planned but not yet stable.

## Repository Shape

This repository is the **Pavê runtime source monorepo**. It produces the Pavê gems and runtime tooling. It is not a deployable host app.

Runtime code belongs in `gems/pave-*`. Product-specific application code does not belong in this repository. Real host apps consume Pavê through Bundler and keep their own product code.

## Development Harness

The Rails-shaped root application in this repository exists only as a development and test harness. It is not the public host-app template. The future public host-app template will live in `template/host_app/`.

## Agent Context

Public agent contracts live in `AGENTS.md` and, in the future, in `gems/pave-agent`. The `.agents/` directory is intentionally private and ignored in this repository.

## License

MIT License. Pavê name, logo, and brand identity are not granted as product branding without permission.

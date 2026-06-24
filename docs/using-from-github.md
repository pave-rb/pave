# Using Pavê from GitHub

Pavê is currently consumed from GitHub while it remains in early alpha. RubyGems releases are deferred until a host app has validated a GitHub tag in staging.

## Pin to a tag

Add this block to the host app `Gemfile`:

```ruby
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

Do **not** use `branch: "main"` or an unpinned reference in production host apps. Always pin to a validated tag.

## Install

```sh
bundle install
bin/rails generate pave:install
bin/rails db:create db:migrate
bin/pave doctor
```

## Local path override

For active Pavê development alongside a host app, clone the repository and use the local path:

```sh
git clone git@github.com:pave-rb/pave.git ../pave
```

```ruby
# Gemfile
gem "pave",            path: "../pave/gems/pave"
gem "pave-core",       path: "../pave/gems/pave-core"
gem "pave-rails",      path: "../pave/gems/pave-rails"
gem "pave-tenancy",    path: "../pave/gems/pave-tenancy"
gem "pave-identity",   path: "../pave/gems/pave-identity"
gem "pave-audit",      path: "../pave/gems/pave-audit"
gem "pave-billing",    path: "../pave/gems/pave-billing"
gem "pave-backoffice", path: "../pave/gems/pave-backoffice"
```

## Upgrading

When a new Pavê tag is released:

1. Update the tag in the host app `Gemfile`.
2. Run `bundle install`.
3. Run `bin/pave doctor`.
4. Run the host app test suite.
5. Deploy to staging before production.

## When to move to RubyGems

Use RubyGems only after:

- A matching GitHub tag has passed staging validation in a host app.
- The gem version is published and a clean `bundle install` succeeds in a test app.
- Staging boots successfully against the RubyGems version.

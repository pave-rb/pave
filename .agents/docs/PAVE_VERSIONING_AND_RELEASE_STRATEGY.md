# Pavê Versioning and Release Tagging Strategy

## 1. Purpose

This document defines how Pavê versions, tags, builds, and releases its runtime gems.

It is written for local coding agents and release agents working inside the clean Pavê runtime repository.

The goal is to make Pavê safe to develop as a multi-gem runtime while allowing external host apps, such as Anella, to upgrade Pavê through Bundler plus Pavê upgrade tooling.

---

## 2. Core Decision

Pavê is distributed as a runtime gem family.

A host app installs Pavê through Bundler:

```ruby
gem "pave"
```

A host app upgrades Pavê through Bundler plus Pavê tooling:

```bash
bundle update pave
bin/pave upgrade
bin/pave doctor
```

The Pavê source repo may contain many gems, but they are released as one coordinated runtime line.

---

## 3. Repository Model

The source repository is:

```txt
pave-rb/pave
```

It is a runtime source monorepo.

It produces multiple gems:

```txt
pave
pave-core
pave-rails
pave-tenancy
pave-identity
pave-billing
pave-audit
pave-backoffice
pave-hotwire
pave-agent
```

The gems do not need separate Git repositories.

RubyGems distributes gem artifacts. A single Git repository may build and publish multiple gems.

---

## 4. Lockstep Runtime Versioning

All first-party Pavê gems use the same version.

Example:

```txt
pave              0.4.0
pave-core         0.4.0
pave-rails        0.4.0
pave-tenancy      0.4.0
pave-identity     0.4.0
pave-billing      0.4.0
pave-audit        0.4.0
pave-backoffice   0.4.0
pave-hotwire      0.4.0
pave-agent        0.4.0
```

Do not independently version first-party runtime gems yet.

Independent versioning is deferred until Pavê has real external adoption pressure and clear independent release cadences.

### Reason

Pavê modules are not general-purpose independent libraries yet. They are parts of one runtime contract.

The host app should be able to say:

```txt
This app runs Pavê runtime 0.4.0.
```

Not:

```txt
This app runs pave-core 0.4.2, pave-identity 0.3.7, pave-backoffice 0.5.1...
```

---

## 5. Version Number Format

Use RubyGems-compatible version strings.

Allowed examples:

```txt
0.1.0
0.1.1
0.2.0
1.0.0
0.4.0.pre.1
0.4.0.rc.1
0.4.0.internal.1
```

Avoid hyphenated gem versions:

```txt
0.4.0-internal.1
0.4.0-rc.1
```

Use dot-separated prerelease labels instead:

```txt
0.4.0.internal.1
0.4.0.rc.1
```

Git tags should mirror the runtime version with a `v` prefix:

```txt
v0.4.0
v0.4.0.rc.1
v0.4.0.internal.1
```

---

## 6. Version Classes

### Internal development release

Used before public RubyGems distribution.

Example:

```txt
0.4.0.internal.1
0.4.0.internal.2
```

Git tags:

```txt
v0.4.0.internal.1
v0.4.0.internal.2
```

Purpose:

```txt
Allow external private host apps, such as Anella, to consume a pinned Pavê runtime through Bundler Git dependencies.
```

Internal releases must still pass build, test, and cleanliness checks.

### Release candidate

Used before a stable public or private release.

Example:

```txt
0.4.0.rc.1
0.4.0.rc.2
```

Git tags:

```txt
v0.4.0.rc.1
v0.4.0.rc.2
```

Purpose:

```txt
Validate upgrade paths, smoke hosts, and real host apps before cutting the stable release.
```

### Stable release

Used when the runtime is considered stable enough for host apps to pin as a normal release.

Example:

```txt
0.4.0
0.4.1
0.5.0
```

Git tags:

```txt
v0.4.0
v0.4.1
v0.5.0
```

Stable releases may eventually be published to RubyGems.

---

## 7. Semantic Versioning Policy

Before `1.0.0`, Pavê is allowed to make breaking changes in minor versions, but release notes and upgrade tooling must be explicit.

After `1.0.0`, use stricter semantic versioning.

### Patch release

Example:

```txt
0.4.1
```

Allowed:

```txt
bug fixes
security fixes
documentation corrections
doctor/check improvements
non-breaking generator fixes
internal refactors with no runtime contract change
```

Avoid:

```txt
new required migrations
breaking config changes
renaming public APIs
changing product manifest schema
```

### Minor release

Example:

```txt
0.5.0
```

Allowed:

```txt
new runtime modules
new optional APIs
new generators
new CLI commands
new migrations
new product manifest fields
new backoffice panels
deprecations
generated file updates
```

Allowed before `1.0.0`, if documented:

```txt
breaking changes
renamed APIs
manifest schema changes
required host app config changes
```

### Major release

Example:

```txt
1.0.0 -> 2.0.0
```

Reserved for:

```txt
major runtime contract changes
major host app upgrade work
removed deprecated APIs
incompatible product/plugin manifest changes
significant database migration strategy changes
```

---

## 8. Source of Truth for Version

Use one authoritative runtime version.

Recommended files:

```txt
VERSION
gems/*/lib/pave/<package>/version.rb
```

The root `VERSION` file is the release source of truth.

Example:

```txt
0.4.0.internal.1
```

Each gem must expose its own version constant for runtime and gemspec usage.

Examples:

```ruby
# gems/pave-core/lib/pave/core/version.rb
module Pave
  module Core
    VERSION = "0.4.0.internal.1"
  end
end
```

```ruby
# gems/pave-backoffice/lib/pave/backoffice/version.rb
module Pave
  module Backoffice
    VERSION = "0.4.0.internal.1"
  end
end
```

The release script must update all version constants together.

Do not manually update one gem version without updating all first-party Pavê gem versions.

---

## 9. Meta-Gem Dependency Policy

The `pave` gem is the normal installation surface.

Example:

```ruby
# gems/pave/pave.gemspec
Gem::Specification.new do |spec|
  spec.name = "pave"
  spec.version = Pave::VERSION

  spec.add_dependency "pave-core", Pave::VERSION
  spec.add_dependency "pave-rails", Pave::VERSION
  spec.add_dependency "pave-tenancy", Pave::VERSION
  spec.add_dependency "pave-identity", Pave::VERSION
  spec.add_dependency "pave-audit", Pave::VERSION
  spec.add_dependency "pave-backoffice", Pave::VERSION
end
```

Use exact matching versions between first-party Pavê gems while the runtime is lockstep.

This prevents unsupported combinations.

Optional heavier packages may be excluded from the meta-gem later, but do not split this prematurely.

---

## 10. Host App Consumption Modes

### Local path mode

Used while developing Pavê and a host app side by side.

Example in an external Anella host app:

```ruby
if ENV["PAVE_LOCAL_PATH"].present?
  pave_root = ENV["PAVE_LOCAL_PATH"]

  gem "pave",            path: "#{pave_root}/gems/pave"
  gem "pave-core",       path: "#{pave_root}/gems/pave-core"
  gem "pave-rails",      path: "#{pave_root}/gems/pave-rails"
  gem "pave-tenancy",    path: "#{pave_root}/gems/pave-tenancy"
  gem "pave-identity",   path: "#{pave_root}/gems/pave-identity"
  gem "pave-billing",    path: "#{pave_root}/gems/pave-billing"
  gem "pave-audit",      path: "#{pave_root}/gems/pave-audit"
  gem "pave-backoffice", path: "#{pave_root}/gems/pave-backoffice"
else
  gem "pave", git: "git@github.com:pave-rb/pave.git", tag: "v0.4.0.internal.1"
end
```

Use local path mode for active runtime development only.

Do not deploy production using local path mode.

### Git tag mode

Used for private/internal production before RubyGems publication.

Example:

```ruby
git "git@github.com:pave-rb/pave.git", tag: "v0.4.0.internal.1" do
  gem "pave",            glob: "gems/pave/*.gemspec"
  gem "pave-core",       glob: "gems/pave-core/*.gemspec"
  gem "pave-rails",      glob: "gems/pave-rails/*.gemspec"
  gem "pave-tenancy",    glob: "gems/pave-tenancy/*.gemspec"
  gem "pave-identity",   glob: "gems/pave-identity/*.gemspec"
  gem "pave-billing",    glob: "gems/pave-billing/*.gemspec"
  gem "pave-audit",      glob: "gems/pave-audit/*.gemspec"
  gem "pave-backoffice", glob: "gems/pave-backoffice/*.gemspec"
end
```

Always pin to tags, not branches.

Do not use `branch: "main"` for production host apps.

### RubyGems mode

Used after public or private gem registry publishing.

Example:

```ruby
gem "pave", "~> 0.5"
```

The host app upgrades with:

```bash
bundle update pave
bin/pave upgrade
bin/pave doctor
```

---

## 11. Tagging Policy

### Tag format

Use:

```txt
v<version>
```

Examples:

```txt
v0.4.0.internal.1
v0.4.0.rc.1
v0.4.0
v0.4.1
v0.5.0
```

### Tag meaning

A tag means:

```txt
All first-party Pavê gems in the repo have this exact version.
All tests passed at release time.
All gemspecs built successfully.
The tag is safe for host apps to pin through Bundler.
```

### Tag immutability

Never move a pushed release tag.

Never delete and recreate a released tag to “fix” it.

If a release is bad, cut a new version.

Bad:

```bash
git tag -d v0.4.0.internal.1
git push --delete origin v0.4.0.internal.1
git tag v0.4.0.internal.1
git push origin v0.4.0.internal.1
```

Good:

```bash
git tag v0.4.0.internal.2
git push origin v0.4.0.internal.2
```

Host apps must be able to trust tags as immutable release points.

---

## 12. Release Branch Policy

Initial policy:

```txt
main
  Active development.

tags
  Release points.
```

Do not create release branches until needed.

Add release branches only if maintaining multiple runtime lines becomes necessary.

Future policy, if needed:

```txt
main
  next development line

release/0.4
  patch maintenance for 0.4.x

release/0.5
  patch maintenance for 0.5.x
```

Do not introduce this complexity early.

---

## 13. Required Release Checks

Before creating any release tag, run:

```bash
bundle install
bundle exec rake test
scripts/repo-check-clean
scripts/build-gems
scripts/smoke-install
```

Use only commands that exist at the time.

If a script does not exist yet, the release agent must either:

```txt
- create it as part of the release infrastructure task, or
- document it as missing and stop before tagging.
```

A release tag must not be created if required checks fail.

---

## 14. Build Artifacts

Built gems should go to:

```txt
pkg/
```

Example:

```txt
pkg/pave-0.4.0.internal.1.gem
pkg/pave-core-0.4.0.internal.1.gem
pkg/pave-rails-0.4.0.internal.1.gem
pkg/pave-backoffice-0.4.0.internal.1.gem
```

`pkg/` should not be committed unless intentionally used for local debugging.

Add to `.gitignore`:

```txt
/pkg/
```

---

## 15. Release Script Contract

Target command:

```bash
scripts/release 0.4.0.internal.1
```

The release script should:

```txt
1. Verify working tree is clean.
2. Verify version string is valid.
3. Update root VERSION.
4. Update every first-party gem version constant.
5. Update gemspecs if needed.
6. Run tests.
7. Run repo cleanliness check.
8. Build all gems.
9. Optionally run smoke install.
10. Update CHANGELOG if automated.
11. Commit version changes.
12. Create Git tag v0.4.0.internal.1.
13. Print next steps for pushing tag or publishing gems.
```

During early development, the script may stop before pushing.

Do not auto-publish to RubyGems until the project explicitly enables public release.

---

## 16. Build Gems Script Contract

Target command:

```bash
scripts/build-gems
```

The script should:

```txt
1. Remove old pkg/*.gem files.
2. Iterate through all first-party gemspecs.
3. Build each gem.
4. Fail if any gem cannot be built.
5. Print built artifact paths.
```

Pseudo-shell:

```bash
#!/usr/bin/env bash
set -euo pipefail

rm -rf pkg
mkdir -p pkg

for gemspec in gems/*/*.gemspec; do
  gem_dir="$(dirname "$gemspec")"
  gem_name="$(basename "$gem_dir")"

  echo "Building ${gem_name}"
  gem build "$gemspec" --output "pkg/${gem_name}-$(cat VERSION).gem"
done
```

The actual script may need to respect gemspec output naming. Keep it explicit and boring.

---

## 17. Publishing Policy

### Internal phase

Do not publish to RubyGems.

Host apps consume Git tags.

### Private registry phase

Optional later.

Use only if Git-tag consumption becomes operationally annoying.

### Public RubyGems phase

Only publish once:

```txt
- install generator works in a clean host app
- upgrade command works across at least one tagged version
- smoke host passes
- Anella or another real host has consumed a tagged release successfully
- documentation explains install and upgrade flow
```

Publishing command, conceptually:

```bash
gem push pkg/pave-core-0.5.0.gem
gem push pkg/pave-rails-0.5.0.gem
gem push pkg/pave-0.5.0.gem
```

Push dependency gems before the meta-gem.

Recommended order:

```txt
1. pave-core
2. pave-rails
3. pave-tenancy
4. pave-identity
5. pave-audit
6. pave-billing
7. pave-backoffice
8. pave-hotwire
9. pave-agent
10. pave
```

The meta-gem `pave` should be pushed last because it depends on the others.

---

## 18. Host App Upgrade Flow

When a host app upgrades Pavê from one tag/version to another:

```bash
bundle update pave
bin/pave upgrade
bin/pave doctor
bin/rails test
```

For internal Git-tag upgrades:

```bash
bin/pave upgrade --to v0.4.0.internal.2
```

The command should eventually:

```txt
1. Update Gemfile Pavê tag or version requirement.
2. Run bundle update for Pavê gems.
3. Compare current runtime version against target runtime version.
4. Install new runtime migrations.
5. Reconcile generated files.
6. Regenerate agent context.
7. Check product/plugin compatibility.
8. Update pave.lock.
9. Write an upgrade report.
10. Run doctor checks.
```

The host app owns local config files.

Pavê should help reconcile them, but it must not assume it can overwrite them blindly.

---

## 19. pave.lock Policy

Every Pavê host app should have:

```txt
pave.lock
```

Purpose:

```txt
Gemfile.lock records Ruby dependencies.
pave.lock records the accepted Pavê runtime graph and product/plugin contract state.
```

Example:

```yaml
runtime:
  version: 0.4.0.internal.1
  source: git@github.com:pave-rb/pave.git
  tag: v0.4.0.internal.1
  ref: 8d41ab3

packages:
  pave: 0.4.0.internal.1
  pave-core: 0.4.0.internal.1
  pave-rails: 0.4.0.internal.1
  pave-tenancy: 0.4.0.internal.1
  pave-identity: 0.4.0.internal.1
  pave-billing: 0.4.0.internal.1
  pave-audit: 0.4.0.internal.1
  pave-backoffice: 0.4.0.internal.1

products:
  anella:
    source: local
    path: products/anella
    manifest_version: 1
```

The clean Pavê runtime repo must not include Anella-specific lock entries.

Anella may appear in external host app examples only if that host app is outside this repository.

---

## 20. Changelog Policy

Maintain:

```txt
CHANGELOG.md
```

Each release should include:

```txt
## 0.4.0.internal.1 - YYYY-MM-DD

### Runtime
### Generators
### CLI
### Backoffice
### Migrations
### Upgrade Notes
### Breaking Changes
### Deprecated
```

For internal releases, short entries are acceptable.

For public releases, upgrade notes must be explicit.

Do not tag a release with breaking changes unless the changelog includes an upgrade note.

---

## 21. Deprecation Policy

Before `1.0.0`, deprecations may be short-lived, but they must still be visible.

Use:

```txt
ActiveSupport::Deprecation
```

where Rails is available.

For pure Ruby packages, use a Pavê deprecation wrapper.

Deprecation entries should include:

```txt
old API
replacement API
first version deprecated
planned removal version if known
```

Example:

```txt
Deprecated in 0.5.0:
  Pave.registry.products

Use:
  Pave.runtime.products

Removal:
  no earlier than 0.7.0
```

---

## 22. Compatibility Policy

Runtime modules are lockstep.

Plugins and external product packages should declare compatibility against the Pavê runtime version.

Example:

```yaml
compatible_pave: ">= 0.4.0, < 0.5.0"
```

Do not make plugins declare compatibility against every internal Pavê gem unless there is a real need.

Host app compatibility check:

```bash
bin/pave doctor --compatibility
```

Target behavior:

```txt
- Verify runtime version.
- Verify product manifest versions.
- Verify plugin compatible_pave ranges.
- Fail before deploy if incompatible.
```

---

## 23. Agent Rules

Local agents must follow these rules.

### When changing runtime code

1. Identify which gem owns the change.
2. Do not update versions unless the task is explicitly a release/versioning task.
3. Do not introduce independent versions between first-party gems.
4. Update tests in the owning package.
5. Update public docs/context if the public runtime contract changes.

### When preparing a release

1. Ensure working tree is clean.
2. Update root `VERSION`.
3. Update all gem version constants.
4. Build all gems.
5. Run tests.
6. Run cleanliness checks.
7. Create one Git tag for the whole runtime.
8. Never retag a pushed version.
9. Do not publish to RubyGems unless the task explicitly asks for public publishing.

### When updating a host app

1. Use Bundler to update Pavê.
2. Use `bin/pave upgrade` to reconcile generated/runtime files.
3. Use `bin/pave doctor` to validate.
4. Run the host app test suite.
5. Do not modify Pavê runtime source from the host app.

---

## 24. Forbidden Actions

Agents must not:

```txt
Create one repo per Pavê gem.
Assign independent versions to first-party Pavê gems.
Use branch: "main" for production host app consumption.
Move or rewrite existing pushed tags.
Publish to RubyGems during internal cleanup.
Let runtime code depend on Anella or any host app.
Tag a release with failing tests.
Tag a release without building gems.
Silently overwrite host app config during upgrade.
```

---

## 25. First Internal Version Recommendation

For the clean Pavê repo split, start with:

```txt
0.1.0.internal.1
```

Tag:

```txt
v0.1.0.internal.1
```

Use this as the first tag that an external host app can consume.

Do not start at `1.0.0`.

Do not use `0.0.1` unless there is no usable runtime contract.

`0.1.0.internal.1` means:

```txt
The runtime has a recognizable package shape.
The gems build.
A host app can consume it.
The API is not stable.
Public release is not promised.
```

---

## 26. Exit Criteria for Release Readiness

A Pavê runtime tag is valid when:

```txt
1. All first-party gem versions match root VERSION.
2. All gemspecs build.
3. Tests pass.
4. repo-check-clean passes.
5. No Anella references exist in runtime code.
6. Smoke host install passes, if available.
7. CHANGELOG has an entry.
8. Git tag matches root VERSION.
9. Host apps can pin the tag through Bundler.
```

A public RubyGems release is valid only when:

```txt
1. A clean host app can install Pavê.
2. A clean host app can run bin/pave doctor.
3. A clean host app can create a product.
4. At least one upgrade path between two tags has been tested.
5. The meta-gem dependencies resolve from RubyGems.
6. Docs explain installation and upgrade.
```

---

## 27. One-Sentence Policy

Pavê uses one lockstep runtime version across all first-party gems, tags the whole runtime from one source monorepo, lets host apps consume releases through Bundler, and manages host app upgrades through `bin/pave upgrade` rather than copying or merging runtime source.

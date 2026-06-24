You are working inside the Pavê / Anella monorepo.

Your task is to implement exactly one Pavê backoffice runtime slice from the prepared implementation plans.

Do not implement the whole backoffice in one run.

Read: .agents/plans/backoffice-runtime-implementation/README.md

## Target execution model

This implementation is driven by the existing backoffice runtime plans.

The plan files are the source of truth:

```txt
.agents/plans/backoffice-runtime-implementation/01-foundation-routing-registry.md
.agents/plans/backoffice-runtime-implementation/02-auth-context-audit.md
.agents/plans/backoffice-runtime-implementation/03-platform-pages-settings.md
.agents/plans/backoffice-runtime-implementation/04-product-panels-legacy-migration.md
.agents/plans/backoffice-runtime-implementation/05-ux-components-hotwire.md
.agents/plans/backoffice-runtime-implementation/06-testing-rollout.md
```

Implement exactly one PR-sized slice from one plan file per run.

Do not treat the slice list as a replacement for the plan files. The slice list is only a sequencing aid.

## Target plan and slice

Set these before each run:

```txt
TARGET_PLAN=05-ux-components-hotwire
TARGET_SLICE=05
```

Valid `TARGET_PLAN` values:

```txt
01-foundation-routing-registry
02-auth-context-audit
03-platform-pages-settings
04-product-panels-legacy-migration
05-ux-components-hotwire
06-testing-rollout
```

The agent must first read:

```txt
.agents/plans/backoffice-runtime-implementation/${TARGET_PLAN}.md
```

Then read only the minimum supporting files needed for the selected slice.

## Required source files

Always read the selected plan file first.

Then read these shared source inputs only when relevant to the selected slice:

```txt
.agents/docs/BACKOFFICE_SYSTEM_DESIGN.md
.agents/ux/BACKOFFICE_UX.md
runtime/pave-backoffice/package.yml
runtime/pave-backoffice/lib/pave/backoffice/engine.rb
runtime/pave-backoffice/lib/pave/backoffice/breadcrumbs.rb
runtime/pave-backoffice/lib/pave/backoffice/navigation.rb
```

Relevant legacy areas:

```txt
app/controllers/backoffice
app/views/backoffice
config/products.rb
```

Relevant runtime packages may include:

```txt
runtime/pave-core
runtime/pave-identity
runtime/pave-tenancy
runtime/pave-audit
runtime/pave-billing
```

Do not scan the entire repository unless the selected slice requires it.

## Objective

Implement `runtime/pave-backoffice` as the runtime-level administration console for Pavê applications.

The backoffice must:

* Mount at `/admin` by default.
* Work with zero products installed.
* Use platform super-admin authentication only.
* Stay completely separate from product authentication and tenant sessions.
* Be driven by runtime, product, and plugin registration.
* Own its UI shell and reusable UI components.
* Write audit events for every state-mutating backoffice action.

## Non-negotiable constraints

These are hard rules.

* Only platform super admins can access `/admin`.
* A product user session must never grant access to `/admin`.
* A platform admin session must never sign the user into a product app.
* Backoffice authentication uses a dedicated platform admin session.
* The backoffice must never set or read active tenant scope.
* `Pave::Current.space` must remain `nil` during every backoffice request.
* Platform and Product contexts must be distinct in routes, controllers, navigation, page headers, and visual chrome.
* Platform pages must render with zero registered products.
* Product panels must be registered declaratively by products/plugins, not hardcoded into `pave-backoffice`.
* Every state-mutating backoffice action must write a `Pave::Audit` event.
* Backoffice UI components must live inside `runtime/pave-backoffice`, not host app shared partials.
* Controllers must stay thin.
* Collection queries must eager load rendered associations.
* Columns used for filtering, joining, ordering, or lookup must have indexes.
* Do not introduce global tenant switchers into backoffice.
* Do not depend on `config/products.rb` as the long-term registration source.
* Do not reintroduce product session state into admin controllers.

## Existing implementation inventory

Preserve and adapt:

```txt
runtime/pave-backoffice/lib/pave/backoffice/engine.rb
runtime/pave-backoffice/package.yml
runtime/pave-backoffice/lib/pave/backoffice/breadcrumbs.rb
runtime/pave-backoffice/lib/pave/backoffice/navigation.rb
Pave::Audit::AuditEvent
Pave::Identity::User
```

Replace:

```txt
flat Pave::Backoffice::Registry#register_panel
legacy /backoffice as the primary route
auth based on product authenticate_user!
host app shared shell partials
top-only shell
hardcoded product panels
```

Migrate or rehome only when the selected slice requires it:

```txt
Backoffice::ProductsController
Backoffice::UsersController
Backoffice::AuditLogsController
Backoffice::SpacesController
Backoffice::LogsController
Backoffice::BackupsController
Backoffice::RegistrationSettingsController
config/products.rb backoffice registrations
```

## Required route targets

The completed implementation must eventually support:

```txt
/admin/sign_in
/admin/sign_out
/admin
/admin/users
/admin/users/:id
/admin/audit
/admin/settings
/admin/:product
/admin/:product/:panel
```

For this run, implement only the subset required by `TARGET_PLAN` and `TARGET_SLICE`.

## PR-sized slice map

Use this map to keep each run small.

```txt
01-foundation-routing-registry
  01 engine mount, config, and base routes
  02 platform/product/plugin registry replacement
  03 route drawer and reserved route validation
  04 boot-time registration validation tests

02-auth-context-audit
  01 dedicated platform admin session
  02 base controller auth guard
  03 tenant-scope nil guard
  04 audit write helper/contract
  05 auth and tenant leak request tests

03-platform-pages-settings
  01 platform dashboard with zero-product empty state
  02 platform users index/detail
  03 super-admin access mutations with audit
  04 audit index filters
  05 audit inline detail drawer
  06 Pave::Settings interface
  07 DB-backed settings implementation
  08 settings UI with secret fields

04-product-panels-legacy-migration
  01 product dashboard route and controller
  02 product panel contract
  03 missing product/panel handling
  04 migrate first legacy panel
  05 plugin panel contribution hook
  06 cleanup or redirect legacy backoffice route

05-ux-components-hotwire
  01 runtime-owned backoffice layout
  02 top bar, sidebar, breadcrumbs, page header
  03 context badge and status rail
  04 reusable table/filter/pagination components
  05 reusable empty state, drawer, confirmation, secret field components
  06 Turbo/Stimulus behavior for drawers and filters

06-testing-rollout
  01 request test matrix
  02 system tests for critical Hotwire behavior
  03 bin/pave doctor backoffice validations
  04 rollout shims and compatibility checks
  05 final legacy cleanup verification
```

## Execution rule

For each run:

1. Read the selected plan file.
2. Identify the selected slice inside that plan.
3. Implement only that slice.
4. Preserve all non-negotiable constraints from the full backoffice implementation summary.
5. Add or update the narrowest meaningful tests.
6. Commit only the selected slice.

If the selected slice depends on earlier incomplete work, stop and report the missing dependency instead of silently implementing multiple slices.

## Slice acceptance guidance

### 01-foundation-routing-registry

Implement foundation only.

Expected outcomes across this plan:

* `Pave::Backoffice::Engine` owns `/admin` routes.
* Host app can mount the engine at `/admin` by default.
* Route structure separates auth, platform pages, product dashboard, and product panel routes.
* Explicit platform panel registration exists.
* Explicit product panel registration exists.
* Plugin/product declarations can contribute panels without hardcoding.
* Reserved names are validated.
* Duplicate route keys fail clearly.
* Registries are boot-time structures, not request-time filesystem scans.
* Tests cover route availability, duplicate keys, reserved keys, and empty registry behavior.

### 02-auth-context-audit

Implement authentication/context/audit foundation only.

Expected outcomes across this plan:

* `/admin` requires a platform admin session.
* Product sessions do not work for `/admin`.
* Platform admin sessions do not authenticate into products.
* `Pave::Current.space` is asserted nil for every request.
* Base controller is thin and explicit.
* Audit helper/contract exists for state-mutating admin actions.
* Request tests cover unauthorized, product-session-only, platform-session-only, tenant-scope leak, and audit cases.

### 03-platform-pages-settings

Implement platform pages and settings only.

Expected outcomes across this plan:

* Platform dashboard renders useful runtime diagnostics with zero products.
* Dashboard lists registered products/modules when present.
* `/admin/users` and `/admin/users/:id` use `Pave::Identity::User`.
* Platform super-admin access is separate from product membership.
* Super-admin access mutations write `Pave::Audit`.
* `/admin/audit` uses `Pave::Audit::AuditEvent`.
* Audit filters support actor, event/action, target, product/context, and time where the underlying model supports it.
* Audit detail drawer uses Hotwire/Turbo.
* `Pave::Settings` API exists in the appropriate runtime package.
* Settings support namespaces and secret handling.
* `/admin/settings` writes audit events on mutation.

### 04-product-panels-legacy-migration

Implement product panel runtime and legacy migration only.

Expected outcomes across this plan:

* `/admin/:product` is distinct from `/admin`.
* Product context is explicit in route, controller, navigation, and chrome.
* Product panels are declarative.
* Missing product/panel returns a safe not-found response.
* Product dashboard works when no panels exist.
* No active tenant scope is set.
* First migrated legacy panel is product-owned, not hardcoded in `pave-backoffice`.
* Tenant records are treated as records, not active context.
* Mutations write audit events.
* Plugins can register panels declaratively when the selected slice requires it.
* Legacy `/backoffice` is removed, redirected, or shimmed only after replacement pages pass acceptance criteria.

### 05-ux-components-hotwire

Implement backoffice-owned UI components only.

Expected outcomes across this plan:

* Dedicated layout lives in `runtime/pave-backoffice`.
* Shell includes top bar, sidebar, breadcrumbs, page header, context badge, and status rail.
* Platform/Product context is visually explicit.
* No dependency on host shared partials.
* Components/partials are reusable and small.
* Reusable table/filter/pagination components exist where required.
* Reusable empty state, drawer, confirmation, and secret field components exist where required.
* Turbo/Stimulus behavior is narrow and owned by `runtime/pave-backoffice`.

### 06-testing-rollout

Implement testing, doctor checks, and rollout safety only.

Expected outcomes across this plan:

* Request/integration tests cover security and route contracts.
* System tests cover critical Hotwire behavior only where request tests are insufficient.
* `bin/pave doctor` validates backoffice registration contracts.
* Doctor detects duplicate panel keys.
* Doctor detects reserved route names.
* Doctor detects missing panel controllers/views.
* Doctor detects unsafe tenant-scope patterns where feasible.
* Rollout shims are explicit and documented.
* Legacy cleanup happens only after replacement behavior is verified.

## Implementation rules

Before coding:

1. Identify the exact files needed for `TARGET_PLAN` and `TARGET_SLICE`.
2. Summarize the intended change in 5 bullets or fewer.
3. Inspect existing tests and conventions.
4. Prefer extending existing runtime architecture over inventing parallel structures.

While coding:

* Keep controllers thin.
* Put domain logic in small Ruby objects/services/registries.
* Keep view partials small and backoffice-owned.
* Use Rails conventions unless the runtime contract requires a custom abstraction.
* Avoid request-time filesystem scanning.
* Avoid dynamic constant lookup on hot paths.
* Avoid cross-product joins.
* Avoid hardcoded product-specific behavior inside `runtime/pave-backoffice`.
* Add indexes with migrations when new filters/lookups/orderings require them.
* Add audit writes for every mutation.
* Add explicit tests for security boundaries.

Do not:

* Rewrite unrelated runtime packages.
* Implement multiple slices.
* Rename large namespaces.
* Convert products to Rails engines unless the existing architecture already requires it.
* Introduce React or a separate frontend stack.
* Add speculative abstractions not needed by the selected slice.
* Silently depend on host app partials.
* Use `Pave::Current.space` in backoffice.
* Set a current product as a tenant-like global.

## Testing requirements

For the selected slice, add or update the narrowest meaningful tests.

Prioritize:

```txt
request/integration tests
routing tests
registry unit tests
system tests only when needed for Hotwire/UI behavior
```

Security tests must cover the relevant subset of:

```txt
product session cannot access admin
platform admin session can access admin
platform admin session does not sign into product app
Pave::Current.space remains nil in admin requests
state mutation writes Pave::Audit event
```

Only include the tests relevant to the selected slice.

Run the smallest useful test command first. Then run the broader relevant suite if feasible.

## Completion checklist

Before finishing, verify:

* The selected `TARGET_PLAN` and `TARGET_SLICE` are implemented and only that slice.
* The selected plan file was followed as the source of truth.
* `/admin` behavior introduced by this slice matches the docs.
* No product auth grants admin access.
* No tenant scope is used.
* Platform/Product context separation is preserved.
* Mutations write audit events where applicable.
* Backoffice UI lives in `runtime/pave-backoffice`.
* Tests pass for the changed area.
* No unrelated formatting churn.
* No unrelated files were modified.

## Git behavior

Work on the current branch unless instructed otherwise.

Commit only after tests for the selected slice pass.

Use a concise commit message:

```txt
Implement backoffice <plan-or-slice-name>
```

Examples:

```txt
Implement backoffice routing foundation
Implement backoffice platform admin session
Implement backoffice product panel contract
```

If tests cannot be run or fail because of pre-existing issues, do not hide that. Report:

* What was implemented.
* What tests were run.
* What failed.
* Whether the failure appears related to this slice.

## Final response format

Return a concise handoff:

```md
## Implemented

- ...

## Tests

- ...

## Files changed

- ...

## Notes / follow-ups

- ...
```

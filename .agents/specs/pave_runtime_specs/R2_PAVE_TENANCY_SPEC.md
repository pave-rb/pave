# R2 — pave-tenancy Specification

## Intent

Extract generic tenancy primitives into `pave-tenancy` while keeping Anella-specific space/profile concerns in Anella.

This is the first move-based runtime extraction phase.

## Dependencies

- R0 complete.
- R1 complete.
- `pave-core` public APIs stable.

`pave-tenancy` depends on `pave-core` only.

## Outcome

Generic space and membership concepts live in `pave-tenancy`. Products can resolve and scope tenant-owned data through a stable runtime interface.

## Scope

Move or create generic equivalents for:

```text
Pave::Tenancy::Space
Pave::Tenancy::SpaceMembership
Pave::Tenancy::BaseController
Pave::Tenancy.with_space
Pave::Tenancy.current_space
Pave::Tenancy.space_required!
Pave::Current.space wiring
```

The roadmap names `Space` and `SpaceMembership`. Prefer canonical runtime classes under `Pave::Tenancy::*`. If existing application code requires top-level `Space` / `SpaceMembership` during migration, provide temporary compatibility aliases and mark them as transitional.

## Data model contract

`Space` may include only generic tenancy fields.

Allowed examples:

```text
id
name
slug
status
created_at
updated_at
```

`SpaceMembership` may include only generic membership fields.

Allowed examples:

```text
id
space_id
user_id
role
status
created_at
updated_at
```

Use existing tables when possible to avoid destructive migrations. If table names are currently generic (`spaces`, `space_memberships`), keep them. If names are product-specific, introduce compatibility carefully and preserve data.

## Required split

Before moving `Space`, audit all current `spaces` columns and methods.

Move Anella-specific fields and methods into:

```text
products/anella/app/models/anella/space_profile.rb
```

or an equivalent existing Anella namespace.

Examples of fields/methods that must not stay in runtime `Space`:

- booking page slug or public booking configuration
- appointment defaults
- WhatsApp settings
- clinic/salon/business vertical fields
- Anella onboarding state
- CRM preferences
- notification copy or templates

The runtime can expose a generic extension association if needed:

```ruby
has_one :profile, class_name: "Anella::SpaceProfile"
```

But prefer defining product associations from the product side when possible, so runtime does not reference Anella constants.

## Controller contract

`Pave::Tenancy::BaseController` may provide:

- current space lookup hook
- `require_space!`
- assignment to `Pave::Current.space`
- tenant mismatch guard

It must not assume Devise or a specific authentication package yet. R4 owns identity.

Use overridable methods:

```ruby
def resolve_current_space
  # host/product override
end

def current_actor
  Pave::Current.actor || Pave::Current.user
end
```

## Tenant scoping contract

Provide an explicit API:

```ruby
Pave::Tenancy.with_space(space) { ... }
Pave::Tenancy.current_space
Pave::Tenancy.space_required!
Pave::Tenancy.assert_same_space!(record, space)
```

Do not make background jobs depend on implicit `Current.space`. Jobs must pass explicit IDs and establish context inside `perform` when required.

## Non-goals

- Do not implement identity extraction.
- Do not implement billing plans per space.
- Do not implement audit events beyond any generic tenant lifecycle events absolutely required.
- Do not implement product-specific profiles inside runtime.
- Do not introduce organization/team complexity beyond what current app already needs.

## Expected files touched

Likely files:

```text
runtime/pave-tenancy/app/models/pave/tenancy/space.rb
runtime/pave-tenancy/app/models/pave/tenancy/space_membership.rb
runtime/pave-tenancy/app/controllers/pave/tenancy/base_controller.rb
runtime/pave-tenancy/lib/pave/tenancy.rb
runtime/pave-tenancy/lib/pave/tenancy/*
products/anella/app/models/anella/space_profile.rb
products/anella/db/migrate/*create_or_backfill_space_profiles*.rb
app/models/space.rb                         # compatibility shim only if required
app/models/space_membership.rb              # compatibility shim only if required
```

## Tests

Add or preserve tests for:

- current space assignment
- tenant mismatch protection
- membership lookup
- compatibility aliases, if added
- Anella profile split
- no loss of existing Anella behavior
- no product-specific columns expected by runtime model

## Data migration safety

If profile split requires migration:

1. Create Anella profile table.
2. Backfill from existing `spaces` columns.
3. Update code to read from profile.
4. Keep old columns temporarily only if needed for safe deploy.
5. Drop old product-specific columns only in a later cleanup after validation.

Do not drop data in the same phase unless the field is proven unused and covered by tests.

## Acceptance criteria

- Runtime owns generic space/membership behavior.
- Anella-specific space concerns live under `products/anella`.
- `Pave::Current.space` is wired through tenancy.
- Existing Anella tenant flows still work.
- Tests remain green.
- No runtime file references `Anella::SpaceProfile` directly unless explicitly isolated in a compatibility adapter outside the runtime package.

## Contamination checks

Run:

```bash
grep -R "booking_page\|appointment\|whatsapp\|clinic\|salon\|Anella" runtime/pave-tenancy || true
```

Expected result: no product-domain hits.

## Handoff note

The R2 handoff must include:

- list of moved tenancy files
- list of fields left on runtime `Space`
- list of fields moved to Anella profile
- compatibility shims added, if any
- migration/backfill status
- tenant safety tests added

# R2 — pave-tenancy Implementation Plan

## 1. Purpose

Extract generic tenant space and membership behavior into `pave-tenancy` while moving Anella-specific space data behind product-owned profile code.

## 2. Preconditions

- R0 and R1 are complete and green.
- `Pave::Current` and core errors/services are available.
- Baseline tenant flows and Anella product tests are green before moving code.

## 3. Non-goals

- Do not extract identity, billing, audit UI, or backoffice shell.
- Do not implement organization/team complexity beyond existing spaces and memberships.
- Do not put booking, appointments, CRM, inbox, WhatsApp, salon/clinic, or onboarding fields into runtime tenancy.
- Do not drop `spaces` columns in this phase.
- Do not make jobs depend on implicit `Current.space`.

## 4. Repo observations

- `app/models/space.rb` is heavily contaminated: it includes `Schedulable`, business vertical constants, appointment automation, booking/scheduling fields, CRM profile, inbox assignee, WhatsApp associations, billing associations, appointments, customers, conversations, and onboarding state.
- `app/models/space_membership.rb` is generic and maps `user_id` to `space_id` with a uniqueness validation.
- `app/controllers/spaces/base_controller.rb` authenticates with Devise, checks product permissions, assigns `Current.space`, and includes billing subscription enforcement.
- `app/models/current.rb` stores `space` and `subscription`; R2 should move only the space slot to `Pave::Current` usage.
- The `spaces` table has many product columns including address, phone, email, social URLs, business hours, appointment policies, booking success message, onboarding fields, automation flags, default inbox assignee, and vertical type.

## 5. Planned changes

### Runtime/package structure

- Add `Pave::Tenancy` under `runtime/pave-tenancy/lib/pave/tenancy.rb`.
- Add `Pave::Tenancy::Space` and `Pave::Tenancy::SpaceMembership` under `runtime/pave-tenancy/app/models/pave/tenancy/` using existing `spaces` and `space_memberships` tables.
- Add `Pave::Tenancy::BaseController` under `runtime/pave-tenancy/app/controllers/pave/tenancy/base_controller.rb` with overridable lookup hooks.

### Rails integration

- Keep top-level `Space` and `SpaceMembership` compatibility shims in `app/models` while legacy Anella constants and routes still require them.
- Update current context wiring from `Current.space` toward `Pave::Current.space`; keep `Current` as a shim if needed.
- Do not make `Pave::Tenancy::BaseController` assume Devise; host/product controllers override `resolve_current_space` and `current_actor`.

### Models/migrations

- Runtime `Space` should initially expose only generic fields needed by cross-product code: `id`, `name`, `timezone` if retained as generic tenant preference, timestamps, and any minimal status/ownership field already required.
- Runtime `SpaceMembership` should expose `id`, `space_id`, `user_id`, timestamps, and role/status only if added or already present generically.
- Create `products/anella/app/models/anella/space_profile.rb` or equivalent product-owned model.
- Add an Anella migration to create/backfill `anella_space_profiles` from existing `spaces` product columns.
- Product profile data should include existing Anella fields such as address, phone, email, social URLs, `business_type`, business hours/schedules, appointment policy fields, booking success message, onboarding state, default inbox assignee, automation flags, personalized slug counters, and any CRM/public profile settings that are not already separate.
- Keep old `spaces` columns temporarily for compatibility; do not drop them until a later cleanup after validation.

### Controllers/routes

- Keep current Anella routes intact.
- Update `Spaces::BaseController` to inherit from or delegate to `Pave::Tenancy::BaseController` only when behavior is equivalent.
- Ensure product-specific permission and billing checks remain in Anella/product controllers, not runtime tenancy.

### Services/commands

- Implement `Pave::Tenancy.with_space(space) { ... }`.
- Implement `Pave::Tenancy.current_space`.
- Implement `Pave::Tenancy.space_required!`.
- Implement `Pave::Tenancy.assert_same_space!(record, space)` without relying on product associations.

### Tests

- Add tests for `with_space` reset behavior, `space_required!`, tenant mismatch protection, membership lookup, compatibility shims, and Anella profile backfill.
- Preserve existing Anella booking/dashboard/settings flows.

### Documentation/agent context

- Document the final runtime `Space` field list and the product profile split in the R2 handoff.

## 6. Public contracts introduced or changed

- `Pave::Tenancy`.
- `Pave::Tenancy::Space`.
- `Pave::Tenancy::SpaceMembership`.
- `Pave::Tenancy::BaseController`.
- `Pave::Tenancy.with_space`.
- `Pave::Tenancy.current_space`.
- `Pave::Tenancy.space_required!`.
- `Pave::Tenancy.assert_same_space!`.
- Temporary top-level `Space` and `SpaceMembership` shims remain app-owned compatibility contracts.
- Product-owned `Anella::SpaceProfile` owns Anella-specific space data.

## 7. Migration strategy

R2 is compatibility-preserving extraction.

- Source location: `app/models/space.rb`, `app/models/space_membership.rb`, `app/controllers/spaces/base_controller.rb`, `app/models/current.rb`, and `app/models/concerns/space_scoped.rb`.
- Target location: `runtime/pave-tenancy/app/models/pave/tenancy/*`, `runtime/pave-tenancy/app/controllers/pave/tenancy/base_controller.rb`, and `runtime/pave-tenancy/lib/pave/tenancy*`.
- Compatibility shim: keep top-level `Space`, `SpaceMembership`, and `Current` behavior until all Anella call sites are updated.
- Deletion timing: remove old product-specific columns and shims only after R7 boundary enforcement and separate cleanup validation.

## 8. Anti-contamination checks

- Runtime `Space` must not include `BUSINESS_TYPES`, `Schedulable`, booking fields, appointment defaults, CRM associations, WhatsApp associations, inbox settings, or Anella onboarding methods.
- Runtime tenancy must not reference `Anella::SpaceProfile` directly; product code should define product associations from the product side.
- Tenant scoping APIs must require explicit space in jobs.
- If `timezone` remains in runtime, document it as a generic tenant preference, not a scheduling feature.

## 9. Validation commands

```bash
git status --short
bundle exec rails zeitwerk:check
bin/pave doctor
bin/rails test test products/anella/test
bundle exec packwerk check
grep -R "booking_page\|booking\|appointment\|whatsapp\|WhatsApp\|clinic\|salon\|Anella\|CRM\|customer" runtime/pave-tenancy || true
```

## 10. Commit plan

```txt
1. R2: add generic tenancy runtime models
2. R2: add tenancy current-space APIs
3. R2: split Anella space profile data
4. R2: add tenancy compatibility shims
5. R2: cover tenant scoping and profile split
```

## 11. Handoff criteria

- Generic space/membership behavior lives in `pave-tenancy`.
- Product-specific space fields are read from Anella-owned profile code or clearly queued for cleanup with compatibility still intact.
- Existing Anella tenant flows remain green.
- Runtime tenancy contamination search has no unapproved hits.
- Handoff lists moved files, runtime `Space` fields, Anella profile fields, shims, and backfill status.

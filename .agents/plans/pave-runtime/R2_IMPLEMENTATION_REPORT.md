# R2 Implementation Report

## Completed

- Added `Pave::Tenancy::Space` runtime model using existing `spaces` table with generic fields only (id, name, timezone, owner_id)
- Added `Pave::Tenancy::SpaceMembership` runtime model using existing `space_memberships` table
- Added `Pave::Tenancy::BaseController` with overridable `resolve_current_space` and `current_actor` hooks
- Added tenancy API: `Pave::Tenancy.with_space`, `Pave::Tenancy.current_space`, `Pave::Tenancy.space_required!`, `Pave::Tenancy.assert_same_space!`
- Created `Anella::SpaceProfile` model under `products/anella/app/models/anella/`
- Created migration for `anella_space_profiles` table with backfill from existing `spaces` product columns
- Added `has_one :anella_space_profile` to top-level `Space` for forward compatibility
- Updated `bin/pave doctor` to verify tenancy APIs and models
- Added focused Minitest coverage for R2 tenancy contracts
- Updated CLI test to assert tenancy doctor output

## Commits

- `a7ea6ab` — R2: add Anella::SpaceProfile model and migration (submodule)
- `0eae0f3` — R2: add pave-tenancy runtime with profile split

## Validation

- `git status --short` — passed; only intentional R2 files changed
- `bundle exec rails zeitwerk:check` — passed
- `bin/pave doctor` — passed
- `bundle exec rails test` — passed, 1765 runs, 0 failures, 0 errors
- `bundle exec packwerk check` — skipped; Packwerk executable is not included in the bundle
- `grep -R "booking\|appointment\|whatsapp\|WhatsApp\|clinic\|salon\|Anella\|CRM\|customer" runtime/pave-tenancy` — passed; no matches found

## Compatibility notes

- Top-level `Space` and `SpaceMembership` remain in `app/models/` with full Anella contamination as compatibility shims
- `Current` (app/models/current.rb) unchanged; `Pave::Current` already has `space` slot from R1
- `Spaces::BaseController` remains in `app/controllers/spaces/` unchanged
- Old `spaces` columns are NOT dropped; the migration creates and backfills `anella_space_profiles` without removing source columns
- `SpaceScoped` concern remains in `app/models/concerns/` unchanged

## Anti-contamination checks

- Runtime `Pave::Tenancy::Space` has only: `id`, `name`, `timezone`, `owner_id`, timestamps, and `has_many :space_memberships` / `has_many :users through` associations
- No Anella-specific fields, validations, or associations in runtime tenancy
- `Anella::SpaceProfile` owns all Anella-specific space data (address, phone, email, social URLs, business_type, booking/scheduling fields, onboarding, automation flags, etc.)
- Tenancy API uses `Pave::Current.space`, not `Current.space`
- `Pave::Tenancy::BaseController` does not assume Devise; host controllers override `resolve_current_space` and `current_actor`

## Follow-up backlog

- Add Packwerk to the bundle or keep it explicitly advisory until R7 enforcement
- Old `spaces` columns (address, phone, etc.) remain until separate cleanup after R7

## Ready for next phase?

Yes.

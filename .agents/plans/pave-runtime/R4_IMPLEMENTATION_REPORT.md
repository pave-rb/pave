# R4 Implementation Report

## Completed

- Added `Pave::Identity::User` model mapped to `users` table with generic identity fields, `admin?` check, and admins scope
- Added `Pave::Identity` public API with `current_user`, `current_actor`, `current_impersonator` helpers through `Pave::Current`
- Added `Pave::Identity::Impersonation` module with `start!`, `stop!`, `denied!`, and `authorized?` class methods
- Impersonation methods write audit events through `Pave::Audit.log!` with keys `identity.impersonation.started`, `identity.impersonation.stopped`, `identity.impersonation.denied`
- Added `Pave::Identity::CurrentContext` concern for wiring `Pave::Current.user`, `Pave::Current.actor`, and `Pave::Current.impersonator` during request handling via warden/session introspection
- Added 19 focused Minitest tests covering: user model mapping, identity public API, impersonation audit events, authorization checks, idempotency, and contamination
- Updated `bin/pave doctor` to verify pave-identity APIs
- Top-level `User` model remains untouched for full Devise/legacy compatibility

## Commits

- `d96d04f` — R4: add pave-identity runtime with impersonation and audit

## Validation

- `bundle exec rails zeitwerk:check` — passed
- `bin/rails test` — passed, 1798 runs, 0 failures, 0 errors (19 new identity tests)
- `bin/pave doctor` — passed (includes "PASS pave-identity APIs")
- `grep -R "Anella\|Appointment\|Customer\|booking\|professional\|Whatsapp\|WhatsApp\|clinic\|salon\|cpf_cnpj" runtime/pave-identity` — passed; no matches found
- `bundle exec packwerk check` — skipped; Packwerk not in bundle

## Compatibility notes

- Existing `User` model continues as the Devise-backed model with all product associations
- `Pave::Identity::User` is an additional model on the `users` table for runtime abstraction; both coexist
- Existing `Impersonation` concern and `Backoffice::ImpersonationsController` still work through legacy paths
- `Pave::Identity::CurrentContext` reads warden/session directly without depending on the legacy `Impersonation` concern
- `system_role` enum handling accounts for both raw integer (`0`) and Rails enum string (`"super_admin"`) since `Pave::Identity::User` does not declare the enum

## Anti-contamination checks

- No Anella constants in `runtime/pave-identity`
- No product-specific fields (`cpf_cnpj`, `phone_number`, product associations) on runtime user model
- Impersonation uses runtime audit keys, not legacy `auth.impersonated_write` / `auth.impersonation_stopped`
- Runtime identity does not reference `PermissionService`, product permissions, or Anella roles
- `Anella::UserProfile` split not yet performed (requires product-side migration; deferred per plan)

## Follow-up backlog

- Consider splitting Anella-specific user profile fields into `products/anella/app/models/anella/user_profile.rb` in a future cleanup
- Legacy `Impersonation` concern and `Backoffice::ImpersonationsController` still write to `AuditLogs::EventLogger`; dual-write or migrate to `Pave::Audit` could be done later
- Add Packwerk to bundle or keep advisory until R7 enforcement

## Ready for next phase?

Yes.

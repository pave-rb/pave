# R4 — pave-identity Implementation Plan

## 1. Purpose

Extract generic identity, session context, role lookup, and impersonation primitives into `pave-identity`, with security events written through `Pave::Audit`.

## 2. Preconditions

- R0 through R3 are complete and green.
- `Pave::Audit.log!` is stable and tested.
- Existing Devise login/session/MFA/impersonation flows have a green baseline.

## 3. Non-goals

- Do not replace Devise or redesign authentication.
- Do not build a full RBAC/ABAC DSL.
- Do not add identity provider integrations.
- Do not build new user-management UI.
- Do not define Anella roles, booking/provider profile fields, or product-specific permissions inside runtime.

## 4. Repo observations

- `app/models/user.rb` owns Devise auth, encrypted phone/CPF-CNPJ/TOTP fields, MFA helpers, legal acceptance fields, space membership helpers, permission sync, product associations to customers/appointments/messages, and owner-space provisioning.
- `app/controllers/concerns/impersonation.rb` overrides `current_user`, stores `session[:impersonated_user_id]`, and writes legacy audit logs.
- `app/controllers/backoffice/impersonations_controller.rb` stops impersonation and writes legacy audit logs.
- `PermissionService` has Anella permissions such as appointment/customer/scheduling/inbox permissions.
- `SpaceMembership` has no role/status columns today; role resolution may need to preserve current permission behavior while introducing generic membership lookup.

## 5. Planned changes

### Runtime/package structure

- Add `Pave::Identity` under `runtime/pave-identity/lib/pave/identity.rb`.
- Add `Pave::Identity::User` under `runtime/pave-identity/app/models/pave/identity/user.rb`, mapped to `users`.
- Add impersonation service/session objects under `runtime/pave-identity/lib/pave/identity/`.
- Add `Pave::Identity::ImpersonationsController` only if it can preserve current route/session behavior safely.

### Rails integration

- Keep Devise integration minimal and compatible.
- Keep top-level `User` as a compatibility shim/subclass/facade for Devise and legacy constants until all call sites can use runtime APIs.
- Wire `Pave::Current.user`, `Pave::Current.actor`, and `Pave::Current.impersonator` during request handling.
- Ensure identity depends only on `pave-core`, `pave-tenancy`, and `pave-audit`.

### Models/migrations

- Runtime `User` may own generic auth/profile fields already required by login: `id`, `email`, `name`, Devise columns, MFA/passkey/social identity associations if treated as generic auth, locale/time zone if present, platform admin flag, timestamps.
- Move or wrap product/provider-specific fields in `products/anella/app/models/anella/user_profile.rb` where needed.
- Treat `cpf_cnpj` as product/legal/provider-specific unless the implementation records a generic runtime legal identity reason.
- Move product associations such as customers, appointments, sent/received messages, and owner-space provisioning out of runtime user behavior.
- Do not add role/status columns to memberships unless needed; if added, use generic roles only: `owner`, `admin`, `member`.

### Controllers/routes

- Preserve existing Devise routes and helpers.
- Preserve existing impersonation stop/start routes through compatibility routes or controller shims.
- Move generic impersonation authorization/session mechanics to runtime; leave Anella/backoffice copy and product screens outside runtime.

### Services/commands

- Implement `Pave::Identity.current_user` and `Pave::Identity.current_actor` helpers using `Pave::Current`.
- Implement generic impersonation start/stop/deny services.
- Emit `identity.impersonation.started`, `identity.impersonation.stopped`, and `identity.impersonation.denied` through `Pave::Audit.log!`.
- Keep product permission names in product code; runtime capabilities should be generic strings such as `identity.impersonate` and `backoffice.access`.

### Tests

- Add tests for current user/actor wiring, impersonator preservation, impersonation start/stop/deny, audit events, membership role lookup if introduced, Devise compatibility, and user profile split.
- Preserve existing auth, MFA, and Anella flow tests.

### Documentation/agent context

- Document final user field split, auth integration strategy, and compatibility shims in the R4 handoff.

## 6. Public contracts introduced or changed

- `Pave::Identity`.
- `Pave::Identity::User`.
- `Pave::Identity.current_user`.
- `Pave::Identity.current_actor`.
- `Pave::Identity::Impersonation` service/session contract.
- `Pave::Current.user`, `Pave::Current.actor`, and `Pave::Current.impersonator` become live request context.
- Audit keys: `identity.impersonation.started`, `identity.impersonation.stopped`, `identity.impersonation.denied`.
- Temporary top-level `User` remains for Devise/legacy compatibility.

## 7. Migration strategy

R4 is compatibility-preserving extraction.

- Source location: `app/models/user.rb`, `app/controllers/concerns/impersonation.rb`, `app/controllers/backoffice/impersonations_controller.rb`, `app/models/user_identity.rb`, `app/models/user_passkey.rb`, `app/models/user_recovery_code.rb`, `app/models/user_permission.rb`, and `app/services/permission_service.rb`.
- Target location: `runtime/pave-identity/app/models/pave/identity/*`, `runtime/pave-identity/app/controllers/pave/identity/*`, and `runtime/pave-identity/lib/pave/identity*`.
- Compatibility shim: keep top-level `User` and current route helpers until Devise and Anella call sites are updated.
- Deletion timing: remove legacy identity shims and product associations from runtime only after R7 cleanup confirms boundaries.

## 8. Anti-contamination checks

- Runtime identity must not reference `Anella`, appointments, customers, WhatsApp, booking, professional profile fields, clinic/salon terms, or Anella onboarding.
- Do not hard-code `manage_appointments`, `manage_customers`, `read_inbox`, `write_inbox`, or other product permissions in runtime.
- `cpf_cnpj` and provider billing identifiers must not become generic runtime identity fields without an explicit revised spec.
- Impersonation copy/screens stay outside runtime; runtime owns only mechanics and audit.

## 9. Validation commands

```bash
git status --short
bundle exec rails zeitwerk:check
bin/pave doctor
bin/rails test test products/anella/test
bundle exec packwerk check
grep -R "Anella\|Appointment\|Customer\|booking\|professional\|Whatsapp\|WhatsApp\|clinic\|salon\|cpf_cnpj" runtime/pave-identity || true
```

## 10. Commit plan

```txt
1. R4: add generic identity user contract
2. R4: wire current user and actor context
3. R4: extract impersonation mechanics with audit
4. R4: split Anella user profile data
5. R4: cover identity compatibility paths
```

## 11. Handoff criteria

- Existing login/logout/session/MFA behavior remains green.
- Impersonation writes runtime audit events.
- Runtime identity contains only generic identity behavior.
- Product profile data and product associations are product-owned or explicitly queued for cleanup.
- Handoff lists field split, shims, audit proof, and tests.

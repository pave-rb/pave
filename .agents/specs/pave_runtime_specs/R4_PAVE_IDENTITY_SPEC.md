# R4 — pave-identity Specification

## Intent

Extract generic identity, session, role resolution, and impersonation primitives into `pave-identity`, using `pave-audit` for security-relevant events.

## Dependencies

- R0 complete.
- R1 complete.
- R2 complete.
- R3 complete.

`pave-identity` depends on:

```text
pave-core
pave-tenancy
pave-audit
```

## Outcome

Runtime owns generic user/session/impersonation behavior. Products own profile fields and product-specific roles or capabilities.

## Scope

Move or create generic equivalents for:

```text
Pave::Identity::User
Pave::Identity::Session or session abstraction
Pave::Identity::Impersonation
Pave::Identity::ImpersonationsController
Pave::Identity.current_user / current_actor helpers
Role resolution through Pave::Tenancy::SpaceMembership
```

If current auth is Devise-based, preserve behavior. Do not rewrite authentication unless the current implementation already requires it.

## User model contract

Runtime `User` may include only generic identity fields.

Allowed examples:

```text
id
email
name
status
time_zone
locale
admin/platform_admin flag only if already generic
created_at
updated_at
```

Product-specific user fields must move to:

```text
products/anella/app/models/anella/user_profile.rb
```

or equivalent existing Anella namespace.

Examples that must not live in runtime `User`:

- professional biography
- booking display name
- service provider settings
- WhatsApp signature
- appointment color preferences
- clinic/salon role details
- Anella onboarding preferences

## Role/capability contract

Role resolution should flow through memberships:

```ruby
membership = Pave::Tenancy::SpaceMembership.find_by(user:, space:)
membership.role
```

Do not hard-code Anella roles in runtime.

Allowed generic roles only if already present and truly cross-product:

```text
owner
admin
member
```

Prefer capabilities for runtime checks:

```text
platform.manage
spaces.manage
identity.impersonate
billing.manage
backoffice.access
```

## Impersonation contract

Implement impersonation as a generic security feature.

Required behavior:

- start impersonation only from authorized platform actor
- store original actor separately from impersonated user
- expose `Pave::Current.impersonator`
- expose `Pave::Current.actor` as effective actor if needed
- stop impersonation and restore original actor
- write audit events through `Pave::Audit.log!`

Audit keys:

```text
identity.impersonation.started
identity.impersonation.stopped
identity.impersonation.denied
```

Do not make impersonation depend on Anella support flows or copy.

## Session contract

If the current app uses Devise or Rails auth generator, keep integration minimal:

- runtime may own generic current-user helpers
- runtime should not force a new auth stack
- runtime should not break existing login/logout/password flows

R4 is extraction, not auth product redesign.

## Non-goals

- Do not build full RBAC/ABAC DSL yet.
- Do not build identity provider integrations.
- Do not build user management UI beyond what already exists generically.
- Do not move Anella user profile fields into runtime.
- Do not define product-specific roles.

## Expected files touched

```text
runtime/pave-identity/app/models/pave/identity/user.rb
runtime/pave-identity/app/models/pave/identity/impersonation.rb       # if persistence needed
runtime/pave-identity/app/controllers/pave/identity/impersonations_controller.rb
runtime/pave-identity/lib/pave/identity.rb
runtime/pave-identity/lib/pave/identity/*
products/anella/app/models/anella/user_profile.rb
app/models/user.rb                                                    # compatibility shim only if required
```

## Tests

Add tests for:

- current user/current actor wiring
- role lookup through memberships
- impersonation start success
- impersonation stop success
- unauthorized impersonation denied
- audit events written for impersonation
- user profile split
- no Anella constants in runtime identity

## Acceptance criteria

- Existing login/session behavior still works.
- Generic user behavior lives in runtime.
- Anella profile behavior lives in product code.
- Impersonation writes to audit.
- R5 can use identity actor context for billing audit events.
- Tests and Packwerk remain green.

## Contamination checks

Run:

```bash
grep -R "Anella\|Appointment\|booking\|professional\|Whatsapp\|clinic\|salon" runtime/pave-identity || true
```

Expected result: no product-domain hits except generic words that are justified in comments/tests.

## Handoff note

The R4 handoff must include:

- final user field split
- auth integration approach retained
- impersonation audit proof
- compatibility aliases/shims added, if any
- tests added

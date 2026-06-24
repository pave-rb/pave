# R3 — pave-audit Specification

## Intent

Extract a generic audit trail module before identity and billing so impersonation and billing state transitions can write to a stable runtime audit interface.

## Dependencies

- R0 complete.
- R1 complete.
- R2 complete.

`pave-audit` depends on:

```text
pave-core
pave-tenancy
```

## Outcome

Runtime has a generic `AuditEvent` model and a stable `Pave::Audit.log` API.

## Scope

Implement:

```text
Pave::Audit
Pave::Audit::AuditEvent
Pave::Audit.log
Pave::Audit.log!
Pave::Audit::EventBuilder or equivalent small internal object
```

## Public API

Expected use:

```ruby
Pave::Audit.log(
  key: "identity.impersonation.started",
  actor: current_user,
  target: target_user,
  space: Pave::Current.space,
  metadata: { reason: "support" },
  idempotency_key: request.uuid
)
```

`log` should return a result object or audit event without raising for validation failures if that matches current service conventions.

`log!` should raise `Pave::ValidationError` or a domain-specific audit error on failure.

## Data model contract

`AuditEvent` should store generic references only.

Suggested columns:

```text
id
space_id
key
actor_type
actor_id
actor_label
target_type
target_id
target_label
metadata json/jsonb
request_id
idempotency_key
source
occurred_at
created_at
updated_at
```

Indexes:

```text
space_id, occurred_at
key, occurred_at
actor_type, actor_id, occurred_at
target_type, target_id, occurred_at
idempotency_key unique where present, if supported
```

Do not store Anella-specific fields.

## Event naming

Use namespaced event keys:

```text
tenancy.space.created
identity.impersonation.started
billing.subscription.changed
billing.credit.debited
```

Do not use human copy as event keys.

## Metadata rules

`metadata` must be JSON-serializable and safe.

Do not store:

- raw access tokens
- webhook secrets
- full payment payloads unless redacted
- full message bodies unless explicitly required by a product module
- personally unnecessary sensitive fields

## Controller/job usage

Audit logging must accept explicit `actor`, `target`, and `space`. It may default from `Pave::Current`, but the public API should not require implicit context.

Background jobs must pass explicit IDs or prebuilt safe metadata.

## Non-goals

- Do not build audit UI yet. R6 owns shell; module panels later own content.
- Do not implement event bus or notifications.
- Do not make audit a replacement for application logs.
- Do not add billing or identity behavior.
- Do not add product-specific event schemas.

## Expected files touched

```text
runtime/pave-audit/app/models/pave/audit/audit_event.rb
runtime/pave-audit/db/migrate/*create_pave_audit_events*.rb
runtime/pave-audit/lib/pave/audit.rb
runtime/pave-audit/lib/pave/audit/*
runtime/pave-audit/package.yml
```

If there is an existing audit model in Anella, move only generic behavior and leave product-specific presentation/content under Anella.

## Tests

Add tests for:

- successful generic audit write
- system actor logging
- nil space behavior if platform-level event is allowed
- idempotency behavior
- metadata serialization
- no Anella dependencies
- audit events scoped by space

## Acceptance criteria

- `Pave::Audit.log` works from app code.
- Audit event table exists and is indexed.
- No Anella-specific fields or constants in `pave-audit`.
- R4 and R5 can depend on audit without defining their own audit interfaces.
- Existing test suite remains green.

## Contamination checks

Run:

```bash
grep -R "Anella\|Appointment\|Whatsapp\|Asaas\|booking\|clinic\|salon" runtime/pave-audit || true
```

Expected result: no product-domain hits.

## Handoff note

The R3 handoff must include:

- final audit event schema
- public audit API examples
- redaction/idempotency behavior
- tests added
- known future UI hooks for R6/modules

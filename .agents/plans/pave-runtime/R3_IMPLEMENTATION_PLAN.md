# R3 — pave-audit Implementation Plan

## 1. Purpose

Introduce a generic audit event runtime and stable `Pave::Audit` API before identity and billing start emitting security and state-transition events.

## 2. Preconditions

- R0, R1, and R2 are complete and green.
- `Pave::Current.space` and `Pave::Tenancy` are available.
- Existing audit behavior has a baseline from current tests/backoffice flows.

## 3. Non-goals

- Do not build audit UI.
- Do not implement an event bus, notifications, or application log replacement.
- Do not add identity or billing behavior beyond generic audit API support.
- Do not add product-specific event schemas.
- Do not store raw secrets, provider payloads, or full message bodies.

## 4. Repo observations

- Existing `app/models/audit_log.rb` is append-only and belongs to top-level `User`, `Space`, polymorphic `subject`, and polymorphic `auditable`.
- Existing `audit_logs` table stores event type, actor user id, space, subject/auditable polymorphic refs, request id, IP address, impersonation flag, metadata, and subject fingerprints.
- `app/services/audit_logs/event_logger.rb` references `User` and product-owned `Customer`, so it cannot move directly into runtime.
- Existing backoffice audit views/controllers read `AuditLog` and must remain working until R6 moves shell/content boundaries.

## 5. Planned changes

### Runtime/package structure

- Add `Pave::Audit` under `runtime/pave-audit/lib/pave/audit.rb`.
- Add `Pave::Audit::AuditEvent` under `runtime/pave-audit/app/models/pave/audit/audit_event.rb`.
- Add small internal builder/normalizer objects under `runtime/pave-audit/lib/pave/audit/`.

### Rails integration

- Add `pave-audit` dependency on `pave-core` and `pave-tenancy` only.
- Ensure audit can default request/space from `Pave::Current` but every public call accepts explicit `actor`, `target`, and `space`.

### Models/migrations

- Create `pave_audit_events` table with generic columns: `space_id`, `key`, `actor_type`, `actor_id`, `actor_label`, `target_type`, `target_id`, `target_label`, `metadata`, `request_id`, `idempotency_key`, `source`, `occurred_at`, timestamps.
- Add indexes for space/time, key/time, actor/time, target/time, and unique `idempotency_key` where present.
- Keep existing `audit_logs` table in place for legacy UI and compatibility.
- Do not migrate product fingerprints into runtime audit unless implemented as generic safe labels/metadata.

### Services/commands

- Implement `Pave::Audit.log` returning a `Pave::Result` or event according to the R1 service convention.
- Implement `Pave::Audit.log!` raising `Pave::ValidationError` or `Pave::Audit::Error` on failure.
- Normalize metadata to JSON-safe hashes and reject unserializable data.
- Add idempotency handling.
- Convert `AuditLogs::EventLogger` into a compatibility adapter or dual writer only if needed to preserve existing `AuditLog` behavior.

### Tests

- Add tests for successful writes, system/nil actors, nil platform space if allowed, idempotency, metadata serialization, space scoping, and absence of Anella dependencies.
- Add compatibility tests if `AuditLogs::EventLogger` delegates or dual-writes.

### Documentation/agent context

- Document event naming, metadata rules, redaction rules, and compatibility status in the R3 handoff.

## 6. Public contracts introduced or changed

- `Pave::Audit`.
- `Pave::Audit::AuditEvent`.
- `Pave::Audit.log`.
- `Pave::Audit.log!`.
- Event keys are namespaced strings such as `tenancy.space.created`, `identity.impersonation.started`, and `billing.subscription.changed`.
- Existing `AuditLog`/`AuditLogs::EventLogger` remain legacy compatibility, not runtime public API.

## 7. Migration strategy

R3 is additive with compatibility preservation.

- Source location: `app/models/audit_log.rb` and `app/services/audit_logs/event_logger.rb` for behavior reference only.
- Target location: `runtime/pave-audit/app/models/pave/audit/audit_event.rb` and `runtime/pave-audit/lib/pave/audit*`.
- Compatibility shim: keep `AuditLog` and `AuditLogs::EventLogger`; optionally delegate new runtime writes without removing old rows/UI.
- Deletion timing: delete legacy audit paths only after R6/R7 and a separate migration plan for backoffice audit content.

## 8. Anti-contamination checks

- Runtime audit must not reference `Anella`, `Customer`, `Appointment`, `Whatsapp`, `WhatsApp`, `Asaas`, booking, salon, or clinic.
- Actor/target labels must be generic and safe; product-specific fingerprinting remains outside runtime.
- Metadata redaction must reject raw access tokens, webhook secrets, full provider payloads, and full message bodies.
- Audit API cannot require implicit current space or current user.

## 9. Validation commands

```bash
git status --short
bundle exec rails zeitwerk:check
bin/pave doctor
bin/rails test test products/anella/test
bundle exec packwerk check
grep -R "Anella\|Customer\|Appointment\|Whatsapp\|WhatsApp\|Asaas\|booking\|clinic\|salon" runtime/pave-audit || true
```

## 10. Commit plan

```txt
1. R3: add generic audit event schema
2. R3: add Pave audit logging API
3. R3: bridge legacy audit logger safely
4. R3: cover audit logging contracts
```

## 11. Handoff criteria

- `Pave::Audit.log` and `Pave::Audit.log!` are tested and usable by R4/R5.
- Audit event schema and indexes are documented.
- Existing audit/backoffice behavior remains green.
- Runtime audit contamination search has no unapproved hits.
- Handoff states redaction, idempotency, compatibility, and future UI ownership.

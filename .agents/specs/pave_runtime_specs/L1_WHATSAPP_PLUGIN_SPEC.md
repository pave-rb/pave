# Later L1 — WhatsApp Plugin Specification

## Intent

Use WhatsApp as the first adversarial plugin to validate Pavê runtime contracts end-to-end before external adopters rely on them.

This plugin must exercise:

- plugin dependency declaration
- backoffice panel registration
- billing credit debit
- audit event emission
- webhook handling
- product/runtime boundary discipline

## Dependencies

- R0 through R7 complete.
- Runtime boundaries enforced.
- `Pave::Plugin` DSL stable enough to register metadata.
- `pave-backoffice`, `pave-billing`, and `pave-audit` available.

## Outcome

WhatsApp integration lives outside core runtime as a plugin. Runtime contracts prove sufficient without hard-coding WhatsApp into `pave-billing`, `pave-audit`, `pave-backoffice`, or Anella core.

## Proposed location

```text
plugins/pave-whatsapp/
```

or, if it remains private/product-bound first:

```text
products/anella/plugins/whatsapp/
```

Prefer `plugins/pave-whatsapp` if it can be generic. Keep Anella-specific copy/configuration in Anella.

## Required declarations

The plugin should declare:

```text
name: whatsapp
dependencies:
  - pave-core
  - pave-audit
  - pave-billing
  - pave-backoffice
capabilities:
  - whatsapp.manage
  - whatsapp.send_message
  - whatsapp.manage_templates
events emitted:
  - whatsapp.webhook.received
  - whatsapp.message.sent
  - whatsapp.message.failed
  - whatsapp.template.synced
billing meters:
  - messages
backoffice panels:
  - whatsapp.settings
  - whatsapp.templates
  - whatsapp.webhooks
```

## Runtime contract tests

The plugin should prove:

- a plugin can declare dependencies and fail boot if missing
- a plugin can register backoffice panels without runtime knowing the panel content
- a plugin can debit billing credits through generic meter keys
- a plugin can emit audit events without audit knowing WhatsApp schema
- webhook handling can be isolated behind plugin routes/controllers

## Anti-contamination rule

Do not move WhatsApp concepts into:

```text
runtime/pave-core
runtime/pave-billing
runtime/pave-audit
runtime/pave-backoffice
products/anella core models unless Anella-specific orchestration is required
```

Billing sees `meter: "messages"`, not WhatsApp.

Audit sees event keys and metadata, not provider-specific behavior.

Backoffice sees panel registration, not WhatsApp UI internals.

## Non-goals

- Do not make WhatsApp required for Anella to boot.
- Do not implement multi-provider messaging abstraction unless another provider exists.
- Do not turn this into a generic communications platform yet.
- Do not publish plugin externally before runtime contracts stabilize.

## Acceptance criteria

- Plugin can be enabled/disabled without breaking core runtime.
- Plugin declares dependencies.
- Plugin panels appear through `pave-backoffice` registration.
- Sending/delivery flows debit generic billing credits.
- Webhook flows write audit events.
- Runtime packages contain no WhatsApp references.
- Tests cover plugin registration, billing debit, audit emission, and panel registration.

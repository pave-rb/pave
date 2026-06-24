# Later Runtime Validation Plan

## Purpose

Use L1-L8 only after R0-R7 are complete to prove the runtime is generic, enforceable, and useful outside Anella-specific assumptions. Do not treat these as full implementation plans yet.

## Preconditions

- R0-R7 complete and green.
- Packwerk dependency/privacy enforcement is on.
- `bin/pave doctor`, `bundle exec packwerk check`, `bundle exec rails zeitwerk:check`, and `bin/rails test test products/anella/test` are green.
- Runtime packages expose documented public APIs.

## Validation order

1. L1 WhatsApp plugin: adversarial plugin boundary test.
2. L2 Full `bin/pave` CLI: architecture inspection and generation guardrails.
3. L4 Agent context files: bounded agent context from real package/registry data.
4. L5 Agent workflow templates: repeatable implementation workflows that respect package ownership.
5. L3 Observability stack: optional runtime instrumentation and deploy visibility.
6. L8 Kamal deploy templates: opt-in production template validation.
7. L7 Second product: proof Pavê is not Anella-shaped.
8. L6 External distribution: only after plugin and second-product proof.

## L1 WhatsApp plugin validation

WhatsApp is the first adversarial test because the current repo already has WhatsApp models, routes, services, tests, billing credit usage, and webhooks under Anella. The validation goal is to prove those concepts can move behind a plugin boundary without leaking into runtime modules.

Required proof points:

- Plugin dependency declaration: plugin declares `pave-core`, `pave-audit`, `pave-billing`, and `pave-backoffice`; boot fails clearly if a dependency is missing.
- Backoffice panel registration: plugin registers `whatsapp.settings`, `whatsapp.templates`, and `whatsapp.webhooks` through `Pave::Backoffice.register_panel`; runtime stores metadata only.
- Billing credit deduction: outbound sends call `Pave::Billing.debit_credit!` with `meter: "messages"`; billing runtime never sees WhatsApp templates, phone numbers, Meta payloads, or conversation semantics.
- Audit event emission: plugin emits `whatsapp.webhook.received`, `whatsapp.message.sent`, `whatsapp.message.failed`, and `whatsapp.template.synced` through `Pave::Audit`; audit runtime stores generic keys/metadata only.
- Product/runtime boundary enforcement: plugin routes/controllers/services live under `plugins/pave-whatsapp` or `products/anella/plugins/whatsapp`; runtime packages contain no WhatsApp references.
- No core leakage: `pave-core`, `pave-tenancy`, `pave-audit`, `pave-identity`, `pave-billing`, and `pave-backoffice` remain free of WhatsApp names and behavior.

Suggested validation commands:

```bash
bin/pave doctor
bin/pave plugins
bundle exec packwerk check
bin/rails test test products/anella/test
grep -R "Whatsapp\|WhatsApp\|whatsapp" runtime || true
```

Expected result: no runtime hits except explicitly documented test fixtures, if any.

## L2 CLI validation

- `bin/pave doctor` remains canonical architecture validation.
- Metadata commands such as `packages`, `products`, `plugins`, `explain`, and `context` avoid Rails boot unless required.
- Mutating commands print changed files and do not write outside the requested generator scope.
- Errors use `Pave::Error` codes.

## L3 Observability validation

- Existing `observability/` and any future `ops/observability/` templates remain optional.
- Instrumentation points are generic: request lifecycle, service execution, audit writes, billing transitions, plugin webhooks, and jobs.
- Disabled observability has negligible overhead and does not block Anella boot/deploy.
- No vendor-specific SaaS lock-in is introduced.

## L4 Agent context validation

- Context files are generated from actual package/registry data, not copied strategy prose.
- Each context file states public APIs, owned files, forbidden dependencies, extension points, validation commands, and known traps.
- Files stay concise enough for local coding agents to use before editing.

## L5 Workflow template validation

- Templates name forbidden packages and validation commands.
- Templates do not bypass specs, tests, or Packwerk.
- Initial templates cover billing gates, jobs, service extraction, module panels, plan features, audit events, and plugin capabilities.

## L6 External distribution validation

- Do not publish until L1 and L7 prove the runtime outside Anella assumptions.
- Local gem builds pass.
- Public API docs, versioning policy, migration policy, and compatibility matrix exist.
- No private Anella code is packaged.

## L7 Second product validation

- Choose a product that is not scheduling-first.
- It registers as a product, owns at least one tenant-scoped model, registers one backoffice panel, writes one audit event, and has no dependency on `products/anella`.
- Anella must not depend on the second product.
- Packwerk must catch cross-product leakage.

## L8 Kamal deploy template validation

- Templates are opt-in and do not replace current Anella deploy config.
- `bin/pave deploy doctor` checks env vars, registry config, database accessory config, secret references, production-like boot, and runtime eager loading.
- No secrets are committed.

## Stop conditions

- Stop if a later item requires adding product-specific names to runtime packages.
- Stop if WhatsApp cannot be implemented through generic billing meter, audit event, plugin dependency, and backoffice panel contracts.
- Stop if second-product work reveals runtime abstractions that assume appointments, booking, CRM, WhatsApp, salons, clinics, or Anella pricing.
- Stop if external distribution requires exposing private internals instead of stable public APIs.

# R5 — pave-billing Implementation Plan

## 1. Purpose

Extract generic billing primitives into `pave-billing` while keeping Anella pricing, Asaas integration, WhatsApp semantics, and product-specific entitlement meanings outside runtime.

## 2. Preconditions

- R0 through R3 are complete and green.
- R3 audit API is stable for billing state transitions.
- R4 may be complete for actor context, but `pave-billing` must not depend on identity internals unless explicitly needed.
- Existing billing tests and Anella billing flows have a baseline.

## 3. Non-goals

- Do not implement Asaas, Stripe, invoices, NFe, or provider-specific checkout inside runtime.
- Do not encode WhatsApp template/message semantics in runtime billing.
- Do not encode Anella plan names, marketing copy, appointment limits, salon/clinic tiers, or CRM copy in runtime code.
- Do not build billing UI beyond metadata hooks needed later by R6.
- Do not drop existing billing columns in this phase.

## 4. Repo observations

- Root `app/models/billing/*` contains generic billing models mixed with product/provider details.
- `Billing::Plan` includes Anella feature names such as `personalized_booking_page`, `custom_appointment_policies`, and `whatsapp_included_quota`, plus `whatsapp_monthly_quota`.
- `Billing::Subscription` includes `asaas_customer_id`, `asaas_subscription_id`, payment method enums, `platform_monthly_message_quota`, and demo automation behavior.
- `Billing::BillingEvent` has an Asaas metadata index.
- `Billing::MessageCredit` is message-specific but can map to a generic usage credit ledger.
- Anella product services under `products/anella/app/services/billing/*` use legacy `Billing::*` constants and contain Asaas behavior.

## 5. Planned changes

### Runtime/package structure

- Add `Pave::Billing` under `runtime/pave-billing/lib/pave/billing.rb`.
- Add runtime models under `runtime/pave-billing/app/models/pave/billing/`: `Plan`, `Subscription`, `BillingEvent`, and credit ledger/transaction models.
- Add provider adapter, webhook handler, entitlement, and plan enforcement services under `runtime/pave-billing/lib/pave/billing/`.
- Keep legacy top-level `Billing::*` constants as compatibility facades while Anella product code is updated.

### Rails integration

- Make `pave-billing` depend on `pave-core`, `pave-tenancy`, and `pave-audit` only.
- Use `Pave::Current.actor` only as optional actor metadata for audit events.
- Preserve current Anella product routes and settings billing routes.

### Models/migrations

- Runtime `Plan` should use generic fields: key/slug, name, status/active, price cents, currency if added, interval if added, metadata, timestamps.
- Move product entitlement meanings into generic metadata or product-owned config such as `products/anella/config/billing_plans.yml`.
- Runtime `Subscription` should use generic provider columns (`provider`, provider customer/subscription ids, period dates, trial/cancel dates, status, metadata) while preserving existing Asaas columns until cleanup.
- Runtime `BillingEvent` should store normalized event key/status/provider data and redacted metadata, not raw provider payloads.
- Introduce `Pave::Billing::CreditTransaction` or equivalent ledger table for generic meters.
- Treat `Billing::MessageCredit` as a compatibility facade over a generic meter such as `messages`, not a WhatsApp concept.

### Controllers/routes

- Do not move product billing controllers/routes into runtime.
- Keep `products/anella/config/routes.rb` billing settings/webhook routes product-owned.

### Services/commands

- Implement `Pave::Billing.allowed?(space:, capability:)`.
- Implement `Pave::Billing.enforce!(space:, capability:, actor: nil, metadata: {})`.
- Implement `Pave::Billing.debit_credit!(space:, meter:, amount:, source:, idempotency_key:)` and grant/refund equivalents only as needed by current behavior.
- Implement abstract `Pave::Billing::ProviderAdapter` with the specified method contract.
- Implement a null/fake adapter for tests only.
- Move/keep Asaas client and provider-specific subscription workflows in Anella product code, preferably `products/anella/app/services/anella/billing/asaas_adapter.rb` or legacy-compatible product namespace.
- Emit audit events for subscription changes, plan enforcement, credit grants/debits, and webhook accepted/rejected states.

### Tests

- Add tests for plan lookup, subscription state transitions, entitlement allowed/denied, audit emission, generic credit grant/debit/idempotency, provider adapter contract, webhook normalization, and no Asaas/WhatsApp leakage.
- Preserve existing Anella billing and WhatsApp credit tests.

### Documentation/agent context

- Document provider adapter contract, plan storage strategy, credit ledger naming, and legacy facade status in the R5 handoff.

## 6. Public contracts introduced or changed

- `Pave::Billing`.
- `Pave::Billing::Plan`.
- `Pave::Billing::Subscription`.
- `Pave::Billing::BillingEvent`.
- `Pave::Billing::ProviderAdapter`.
- `Pave::Billing::WebhookHandler`.
- `Pave::Billing::CreditLedger` or `Pave::Billing::CreditTransaction`.
- `Pave::Billing.allowed?`.
- `Pave::Billing.enforce!`.
- `Pave::Billing.debit_credit!`.
- Audit keys: `billing.subscription.created`, `billing.subscription.changed`, `billing.subscription.canceled`, `billing.plan.enforced`, `billing.credit.granted`, `billing.credit.debited`, `billing.webhook.processed`, `billing.webhook.rejected`.
- Legacy `Billing::*` remains compatibility for Anella until cleanup.

## 7. Migration strategy

R5 is extraction with compatibility preservation.

- Source location: `app/models/billing/*`, `app/mailers/billing/*`, product billing services under `products/anella/app/services/billing/*`, and billing references in product services.
- Target location: `runtime/pave-billing/app/models/pave/billing/*`, `runtime/pave-billing/lib/pave/billing*`, and product-owned Asaas adapter/config under `products/anella`.
- Compatibility shim: keep top-level `Billing::*` facades for current Anella code and tests.
- Deletion timing: remove Asaas-specific columns/facades and WhatsApp quota columns only in later cleanup after product code reads generic provider/metadata/ledger fields.

## 8. Anti-contamination checks

- Runtime billing must not reference `Asaas`, `Whatsapp`, `WhatsApp`, `Anella`, `Appointment`, booking, clinic, salon, CRM plan copy, CPF/CNPJ, or Brazilian invoice semantics.
- Capabilities are opaque keys; runtime must not know what `appointments.manage` or `messages.send` does.
- `MessageCredit` compatibility must mean generic message-meter credits, not WhatsApp templates or phone-number billing.
- Provider payloads must be redacted or digested before persistence.

## 9. Validation commands

```bash
git status --short
bundle exec rails zeitwerk:check
bin/pave doctor
bin/rails test test products/anella/test
bundle exec packwerk check
grep -R "Asaas\|asaas\|Whatsapp\|WhatsApp\|Anella\|Appointment\|clinic\|salon\|booking\|cpf_cnpj" runtime/pave-billing || true
```

## 10. Commit plan

```txt
1. R5: add generic billing runtime models
2. R5: add billing entitlement and enforcement APIs
3. R5: add provider adapter and webhook contracts
4. R5: add generic credit ledger APIs
5. R5: bridge Anella billing compatibility
6. R5: cover billing contracts and contamination checks
```

## 11. Handoff criteria

- Billing state transitions write runtime audit events.
- Anella billing gates and credit flows remain green.
- Asaas adapter behavior is product-owned.
- Runtime billing contamination search has no unapproved hits.
- Handoff lists public APIs, adapter interface, plan/entitlement strategy, credit ledger name, emitted audit keys, and shims.

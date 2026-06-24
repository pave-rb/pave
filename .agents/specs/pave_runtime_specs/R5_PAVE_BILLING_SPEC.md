# R5 — pave-billing Specification

## Intent

Extract generic billing primitives into `pave-billing` without coupling the runtime to Anella pricing, Asaas, WhatsApp, Brazilian tax specifics, or any single payment provider.

## Dependencies

- R0 complete.
- R1 complete.
- R2 complete.
- R3 complete.

`pave-billing` depends on:

```text
pave-core
pave-tenancy
pave-audit
```

It may read identity actor context through `Pave::Current`, but should avoid hard dependency on identity internals unless required.

## Outcome

Runtime owns generic plan, subscription, billing event, entitlement, usage-credit, adapter, and webhook contracts. Anella owns provider adapters and product-specific plan definitions.

## Scope

Implement or move generic equivalents for:

```text
Pave::Billing::Plan
Pave::Billing::Subscription
Pave::Billing::BillingEvent
Pave::Billing::PlanEnforcer
Pave::Billing::ProviderAdapter
Pave::Billing::WebhookHandler
Pave::Billing::CreditLedger or UsageCredit
```

The roadmap names `MessageCredit`. Treat this carefully: runtime may support a generic credit ledger with a meter key such as `messages`. Do not encode WhatsApp semantics in `pave-billing`.

Preferred naming:

```text
Pave::Billing::UsageCredit
Pave::Billing::CreditLedger
Pave::Billing::CreditTransaction
```

Only expose `MessageCredit` as a compatibility facade if current Anella code requires it. If added, it must mean generic billable message credits, not WhatsApp template credits.

## Plan contract

A plan is a generic product entitlement bundle.

Allowed fields/examples:

```text
id
key
name
status
price_cents
currency
interval
metadata json/jsonb
created_at
updated_at
```

Do not put Anella marketing copy or vertical-specific plan descriptions into runtime records unless stored as generic metadata owned by product seed data.

## Subscription contract

A subscription connects a tenant to a plan and provider state.

Suggested fields:

```text
id
space_id
plan_id
status
provider
provider_customer_id
provider_subscription_id
current_period_start
current_period_end
trial_ends_at
cancel_at
canceled_at
metadata json/jsonb
created_at
updated_at
```

Allowed generic statuses:

```text
trialing
active
past_due
paused
canceled
expired
```

## Billing event contract

`BillingEvent` stores normalized provider/runtime events, not raw provider payloads as primary behavior.

Suggested fields:

```text
id
space_id
subscription_id
provider
provider_event_id
event_key
status
payload_digest
metadata json/jsonb
occurred_at
processed_at
created_at
updated_at
```

Raw payload storage must be redacted or isolated if kept.

Billing state transitions must write audit events through `Pave::Audit`.

Audit keys:

```text
billing.subscription.created
billing.subscription.changed
billing.subscription.canceled
billing.plan.enforced
billing.credit.granted
billing.credit.debited
billing.webhook.processed
billing.webhook.rejected
```

## Provider adapter interface

Define an abstract adapter contract:

```ruby
class Pave::Billing::ProviderAdapter
  def create_checkout(space:, plan:, success_url:, cancel_url:); end
  def cancel_subscription(subscription:); end
  def sync_subscription(subscription:); end
  def verify_webhook!(request:); end
  def parse_webhook(request:); end
end
```

`pave-billing` may include a fake/null adapter for tests.

Do not implement Asaas inside runtime.

Anella provider adapters must live under:

```text
products/anella/app/services/anella/billing/asaas_adapter.rb
```

or equivalent product namespace.

## Plan enforcement contract

Provide:

```ruby
Pave::Billing.enforce!(space:, capability:, actor: nil, metadata: {})
Pave::Billing.allowed?(space:, capability:)
```

This should check plan entitlements without knowing product domain behavior.

Capabilities are string/symbol keys, for example:

```text
appointments.manage
messages.send
backoffice.access
```

The meaning of a product capability belongs to the product/module.

## Usage credit contract

Runtime should support generic credit debits:

```ruby
Pave::Billing.debit_credit!(space:, meter: "messages", amount: 1, source: "whatsapp.outbound_message", idempotency_key: ...)
```

Rules:

- use idempotency keys for external events
- write audit events for grants/debits
- never let credits go negative unless plan explicitly allows overdraft
- do not know WhatsApp template categories or phone numbers

## Non-goals

- Do not implement Asaas adapter in runtime.
- Do not implement Stripe/Asaas full checkout unless already present and generic.
- Do not implement invoices/NFe in runtime.
- Do not implement Anella pricing tiers in runtime code.
- Do not implement WhatsApp-specific billing in runtime.
- Do not build billing UI beyond generic surfaces needed for R6 registration.

## Expected files touched

```text
runtime/pave-billing/app/models/pave/billing/plan.rb
runtime/pave-billing/app/models/pave/billing/subscription.rb
runtime/pave-billing/app/models/pave/billing/billing_event.rb
runtime/pave-billing/app/models/pave/billing/credit_transaction.rb
runtime/pave-billing/lib/pave/billing.rb
runtime/pave-billing/lib/pave/billing/*
products/anella/app/services/anella/billing/asaas_adapter.rb
products/anella/config/billing_plans.yml or equivalent product-owned plan seed
```

## Tests

Add tests for:

- plan lookup
- subscription state transition
- plan enforcement allowed/denied
- billing audit event writes
- generic credit grant/debit
- idempotent credit debit
- provider adapter abstract contract
- webhook handler normalization
- no Asaas reference in runtime

## Acceptance criteria

- Billing state transitions write audit events.
- Anella can still enforce billing gates.
- Provider-specific adapter lives in Anella.
- Runtime billing does not mention Asaas, WhatsApp, salons, clinics, appointments, or Anella pricing.
- Tests and Packwerk remain green.

## Contamination checks

Run:

```bash
grep -R "Asaas\|Whatsapp\|WhatsApp\|Anella\|Appointment\|clinic\|salon\|booking" runtime/pave-billing || true
```

Expected result: no product/provider hits.

## Handoff note

The R5 handoff must include:

- billing public API
- provider adapter interface
- where Anella provider code now lives
- plan/entitlement storage strategy
- credit ledger naming decision
- audit events emitted
- tests added

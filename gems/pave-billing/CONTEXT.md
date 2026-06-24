# pave-billing — Billing Primitives

## Purpose

Provider-neutral billing abstractions. Plans, subscriptions, billing events, credit tracking, and plan enforcement.

## Public API

```ruby
Pave::Billing.allowed?(capability, space)           # Check capability
Pave::Billing.enforce!(capability, space)            # Enforce capability
Pave::Billing.debit_credit!(space, amount, reason)   # Debit credits
Pave::Billing.grant_credit!(space, amount, reason)   # Grant credits
Pave::Billing.current_balance(space)                 # Current credit balance
Pave::Billing::Plan                                   # Plan model
Pave::Billing::Subscription                           # Subscription model
Pave::Billing::BillingEvent                           # Billing event log
Pave::Billing::CreditTransaction                      # Credit transaction
Pave::Billing::ProviderAdapter                        # Provider interface
Pave::Billing::WebhookHandler                         # Webhook base
Pave::Billing::NullAdapter                            # No-op adapter
```

## Dependencies

- pave-core
- pave-tenancy
- pave-audit

## Testing

Tests use `DemoScheduling` as a dummy product context.

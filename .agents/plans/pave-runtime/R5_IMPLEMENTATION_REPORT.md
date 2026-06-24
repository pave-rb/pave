# R5 Implementation Report

## Completed

- Added `Pave::Billing` runtime APIs: `allowed?`, `enforce!`, `debit_credit!`, `grant_credit!`, and `current_balance`.
- Added runtime billing models for `Plan`, `Product`, `Subscription`, `BillingEvent`, and generic `CreditTransaction`.
- Added `billing_credit_transactions` ledger table for generic metered credits.
- Added provider contracts: `ProviderAdapter`, `WebhookHandler`, and test-only `NullAdapter`.
- Wired `bin/pave doctor` to verify R5 APIs.
- Added billing runtime contract tests and contamination checks.

## Commits

- `5969b71` — R5: add pave-billing runtime contracts

## Validation

- `bundle exec rails zeitwerk:check` — passed
- `bin/rails test test/lib/pave_billing_contracts_test.rb` — passed, 38 runs, 108 assertions
- `bin/rails test test/lib/pave_billing_contracts_test.rb test/models/billing/billing_event_test.rb` — passed, 45 runs, 116 assertions
- `bin/rails test test` — passed, 521 runs, 1738 assertions
- `bin/pave doctor` — passed, includes `PASS pave-billing APIs`
- `grep -R "Asaas\|asaas\|Whatsapp\|WhatsApp\|Anella\|Appointment\|clinic\|salon\|booking\|cpf_cnpj" runtime/pave-billing || true` — passed, no matches
- `bin/rails test test products/anella/test` — failed in unrelated Anella product system tests: inbox layout, inbox start conversation, dock navigation
- `bundle exec packwerk check` — skipped/failed unavailable; Packwerk executable is not included in the bundle

## Compatibility notes

- Legacy top-level `Billing::*` models remain in place for current Anella code.
- Runtime billing models map to existing billing tables where possible.
- Generic credit ledger is additive and does not remove or rewrite existing `message_credits` behavior.
- Runtime `Subscription` exposes generic provider accessors without referencing provider-specific column names.

## Anti-contamination checks

- No Anella constants or product namespaces in `runtime/pave-billing`.
- No provider-specific terms in `runtime/pave-billing`.
- No WhatsApp, appointment, clinic, salon, booking, or CPF/CNPJ terms in `runtime/pave-billing`.
- Capabilities remain opaque feature keys checked through plan metadata/features.
- R5 does not depend on `pave-identity`; actor is optional audit metadata and `actor_id` on credit transactions.

## Follow-up backlog

- Add real product-owned provider adapters under Anella when billing workflows are migrated.
- Bridge `Billing::MessageCredit` to generic meter credits in a later compatibility cleanup.
- Decide whether to add generic provider columns to `subscriptions` after product code stops depending on provider-specific columns.
- Re-run and fix/triage unrelated Anella system failures before using `bin/rails test test products/anella/test` as a green gate.
- Add Packwerk to the bundle or keep advisory until R7 enforcement.

## Ready for next phase?

No.

R5 runtime validation is green, but the full planned Rails command that includes `products/anella/test` is not green due unrelated Anella product system failures. R6 should not start until those failures are resolved or accepted as a documented baseline.

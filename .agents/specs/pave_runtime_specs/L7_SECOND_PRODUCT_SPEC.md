# Later L7 — Second Product Specification

## Intent

Validate that Pavê is a runtime, not a renamed Anella.

## Dependencies

- R0 through R7 complete.
- Anella stable on runtime.
- At least core/tenancy/audit/identity/backoffice contracts are usable by a product that is not scheduling-first.

## Outcome

A second product package runs in the same runtime using shared Pavê modules without importing Anella domain assumptions.

## Candidate products

Choose one small but meaningfully different product:

```text
content/pages/blog
education/courses
lightweight CRM
artist portfolio/store backoffice
```

Avoid another scheduling product as the first proof, because it will not stress Anella contamination enough.

## Validation targets

The second product should prove:

- product package registration works
- tenant scoping works without appointment assumptions
- backoffice panels register independently
- audit events are generic
- identity/membership roles are reusable
- billing gates are reusable if needed
- Packwerk prevents cross-product leakage

## Non-goals

- Do not build a large second SaaS.
- Do not distract from Anella revenue.
- Do not copy Anella patterns blindly.

## Acceptance criteria

- Second product boots and has at least one useful backoffice panel.
- It has at least one tenant-owned model.
- It writes at least one audit event.
- It has no dependency on `products/anella`.
- Anella has no dependency on the second product.

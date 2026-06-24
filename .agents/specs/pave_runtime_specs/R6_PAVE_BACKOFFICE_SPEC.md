# R6 — pave-backoffice Specification

## Intent

Extract the generic backoffice shell into `pave-backoffice` while leaving all product/module panel content in the product or module that owns it.

## Dependencies

- R0 complete.
- R1 complete.
- R2 complete.
- R3 complete.
- R4 complete.
- R5 complete.

`pave-backoffice` depends on:

```text
pave-core
pave-tenancy
pave-audit
pave-identity
pave-billing
```

## Outcome

Runtime owns platform backoffice chrome, base controller, navigation contract, breadcrumb contract, panel registration, and layout surfaces.

Products/modules register panels. Runtime does not own their content.

## Scope

Implement or move generic equivalents for:

```text
Pave::Backoffice
Pave::Backoffice::BaseController
Pave::Backoffice::Panel
Pave::Backoffice::Navigation
Pave::Backoffice::Breadcrumbs
Pave::Backoffice.register_panel
Pave::Backoffice.panels
Generic layout/chrome partials
```

Panel classes or metadata should define:

```text
key
title
namespace
route/helper
required_capability
position/group
icon optional
owner package/product/module
```

## Shell surfaces

Runtime may own shells for:

```text
Platform backoffice
Product backoffice
Module panel container
```

Runtime may render:

- outer layout
- sidebar/nav container
- breadcrumb container
- page heading slot
- panel slot
- empty/unauthorized state

Runtime must not render Anella-specific dashboards, appointment charts, WhatsApp data, customer lists, schedules, or billing copy.

## Controller contract

`Pave::Backoffice::BaseController` should provide:

- authentication hook
- authorization hook
- current space requirement where relevant
- layout selection
- breadcrumb helper
- panel lookup

Identity integration must use runtime identity/capability APIs, not Anella role checks.

Example hooks:

```ruby
def require_backoffice_access!
  # generic capability check
end

def current_backoffice_space
  Pave::Current.space
end
```

## Panel registration contract

Expected use from product/module code:

```ruby
Pave::Backoffice.register_panel(
  key: "anella.appointments",
  title: "Appointments",
  owner: "products/anella",
  route: :anella_backoffice_appointments_path,
  capability: "appointments.manage",
  group: "Operations"
)
```

R6 should validate metadata but not invoke route helpers at boot if that creates load-order problems. Store route references safely.

## Non-goals

- Do not build a full admin framework.
- Do not implement CRUD generation.
- Do not move Anella panel content into runtime.
- Do not implement Avo-like resource screens.
- Do not build public marketplace/module browser.
- Do not implement Hotwire UI derivation from resources yet.

## Expected files touched

```text
runtime/pave-backoffice/app/controllers/pave/backoffice/base_controller.rb
runtime/pave-backoffice/app/controllers/pave/backoffice/*
runtime/pave-backoffice/app/views/layouts/pave/backoffice.html.erb
runtime/pave-backoffice/app/views/pave/backoffice/shared/*
runtime/pave-backoffice/lib/pave/backoffice.rb
runtime/pave-backoffice/lib/pave/backoffice/*
products/anella/app/controllers/anella/backoffice/*
products/anella/app/views/anella/backoffice/*
```

## Tests

Add tests for:

- panel registration validation
- duplicate panel keys rejected
- panel ordering/grouping
- unauthorized access denied
- breadcrumb rendering contract
- Anella panel remains product-owned
- runtime shell renders without product content

## Acceptance criteria

- Backoffice shell loads from runtime.
- Anella panels register into shell from Anella code.
- Runtime backoffice does not reference Anella constants.
- Existing backoffice user flows still work.
- Tests and Packwerk remain green.

## Contamination checks

Run:

```bash
grep -R "Anella\|Appointment\|Whatsapp\|Asaas\|booking\|clinic\|salon\|customer" runtime/pave-backoffice || true
```

Expected result: no product-domain hits except generic fixture strings if explicitly justified.

## Handoff note

The R6 handoff must include:

- final shell/panel API
- list of Anella panels and where they register
- authorization model used
- views/layouts moved
- tests added

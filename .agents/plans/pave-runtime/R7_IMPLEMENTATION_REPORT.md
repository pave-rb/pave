# R7 Implementation Report

## Completed

- Installed and configured Packwerk enforcement.
- Enabled dependency enforcement for runtime packages according to the R7 graph.
- Enabled Anella package dependency enforcement with all runtime package dependencies declared.
- Removed runtime model dependency checks on root `ApplicationRecord`, top-level `User`, and top-level `Space` where feasible.
- Extended `bin/pave doctor` to enforce package presence, dependency graph, Anella package dependencies, runtime anti-contamination checks, Packwerk validation, and Packwerk check.
- Added CI workflow commands for Zeitwerk, doctor, Packwerk, and Rails/product tests.
- Preserved legacy backoffice shim inheritance and existing Anella behavior.

## Commits

- `01b17ee` — R7: enforce Anella package dependencies
- `c0dd888` — R7: enforce Packwerk runtime boundaries
- `1660f19` — R7: document Packwerk enforcement handoff

## Validation

- `bundle exec rails zeitwerk:check` — passed
- `bin/pave doctor` — passed
- `bundle exec packwerk check` — passed
- `bin/rails test test products/anella/test` — passed, 1869 runs, 6380 assertions, 0 failures, 0 errors
- `bundle exec rspec` — skipped/failed unavailable; RSpec executable is not included in the bundle
- runtime contamination search for `Anella|Appointment|Customer|Whatsapp|WhatsApp|Asaas|booking|clinic|salon|CRM` under `runtime` — passed

## Compatibility notes

- `Backoffice::BaseController < Pave::Backoffice::BaseController` remains intact for R6 compatibility.
- `Pave::Backoffice::BaseController` still inherits `ApplicationController` for legacy Devise/helper behavior and is excluded from Packwerk scanning until the backoffice shell can be separated from root controller helpers.
- `products/anella/package.yml` includes a temporary explicit `.` dependency because Anella still references legacy root constants such as `User`, `Space`, `Billing::*`, `Current`, and root backoffice shims.
- Runtime billing credit transactions accept legacy `Space` objects by assigning `space_id`, avoiding a runtime dependency on the top-level `Space` class.

## Anti-contamination checks

- Runtime packages contain no Anella constants or forbidden Anella domain references from the R7 search pattern.
- Runtime package manifests do not depend on `products/anella` or plugins.
- Product-specific legacy dependencies remain outside runtime and are explicitly documented as product/root cleanup backlog.

## Follow-up backlog

- Remove the Packwerk exclusion for `runtime/pave-backoffice/app/controllers/pave/backoffice/base_controller.rb` after legacy backoffice auth/helper behavior is isolated behind runtime-neutral extension points.
- Remove the Anella `.` package dependency after remaining root legacy constants are moved to product-owned or runtime-public APIs.
- If future Packwerk versions support privacy enforcement, add privacy/public API enforcement in manifests or a dedicated custom checker.

## Ready for next phase?

Yes. R7 is the final planned runtime phase; follow-up work should be cleanup/backlog, not R8 runtime extraction.

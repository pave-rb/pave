# 02. Authentication, Context, And Audit

## Goal

Make backoffice access explicitly platform-admin-only, separate from product sessions, impossible to run under tenant scope, and consistently audited for mutations.

## Deliverables

- `/admin/sign_in` and `/admin/sign_out` flows.
- Separate platform admin session boundary.
- Backoffice base controller hierarchy.
- Tenant-scope leak guard.
- `audit_admin` helper using `Pave::Audit`.
- Forbidden, not found, and tenant leak boundary pages.
- Static and runtime checks for audited mutations.

## Work Items

### A1. Platform Admin Session Boundary

Create a backoffice-owned session object instead of relying on product `current_user`.

Target responsibilities:

- Store platform admin identity under a dedicated session key such as `session[:pave_backoffice_admin_id]`.
- Resolve the current admin from `Pave::Identity::User` or an identity adapter.
- Require the resolved admin to be a platform super admin.
- Destroy only the platform admin session on `/admin/sign_out`.
- Never create or destroy product app sessions.

Implementation notes:

- The existing app uses Devise on `User`, but runtime identity currently exposes `Pave::Identity::User` over the same `users` table.
- Add an authentication adapter boundary so `pave-backoffice` does not depend on product controllers.
- First implementation can authenticate against the existing Devise-compatible user model where available, but the API should live under `Pave::Backoffice` or `Pave::Identity`.
- If a product session exists in the browser, the sign-in page must show separation copy and still require platform admin credentials.

### A2. Sessions Controller

Target files:

- `runtime/pave-backoffice/app/controllers/pave/backoffice/sessions_controller.rb`
- `runtime/pave-backoffice/app/views/pave/backoffice/sessions/new.html.erb`

Actions:

- `new`: render platform admin sign-in form.
- `create`: authenticate credentials, require super-admin status, set platform admin session, redirect to safe `/admin` return path.
- `destroy`: clear only the platform admin session, redirect to `/admin/sign_in` with the required copy.

Required UX copy:

- Page title: `Pave Backoffice`
- Subtitle: `Platform administration access`
- Required warning: `This sign-in is only for Pave platform super admins. Product users must sign in through their product application.`
- Non-super-admin error: `This account does not have platform backoffice access.`
- Disabled account error: `This platform admin account is disabled.`
- Invalid credentials error: `Invalid email or password.`

### A3. Base Controller Hierarchy

Target controllers:

```txt
Pave::Backoffice::BaseController
Pave::Backoffice::Platform::BaseController
Pave::Backoffice::Products::BaseController
```

`BaseController` responsibilities:

- Use layout `pave/backoffice/application`.
- Require platform admin session for all non-session pages.
- Expose `current_admin`, `backoffice_nav`, `backoffice_context`, and `backoffice_breadcrumbs`.
- Provide `audit_admin` helper.
- Run tenant-scope guard around every action.
- Render boundary pages instead of redirecting to product app roots.

`Platform::BaseController` responsibilities:

- Operate with global scope.
- Never set product context.
- Permit explicit unscoped queries when needed.

`Products::BaseController` responsibilities:

- Resolve `current_product` from route defaults, not by parsing arbitrary URL state.
- Resolve `current_panel` when a panel route is active.
- Render not found if product or panel is not registered.
- Display Product context while keeping tenant scope nil.

### A4. Tenant-Scope Leak Guard

Backoffice must detect both runtime and legacy tenant context during migration.

Guard behavior:

- At request entry, clear any accidental `Pave::Current.space` if set before controller code runs only if it comes from non-backoffice inherited setup.
- During and after action execution, raise `Pave::Backoffice::TenantScopeLeakError` if `Pave::Current.space` is present.
- During migration, also check legacy `::Current.space` when the constant exists.
- Add `skip_before_action :set_space!` and equivalent skips where host controllers define tenant setup callbacks.
- Never use a product space switcher or tenant chrome in the backoffice layout.

Boundary page:

- Title: `Backoffice tenant-scope leak detected.`
- Body: `A tenant space was present during a backoffice request. Pave backoffice must run outside tenant scope.`
- Actions: Platform dashboard and diagnostics.

### A5. Audit Helper And Event Contract

Use `Pave::Audit.log!` as the canonical new audit sink.

Target helper:

```ruby
def audit_admin(key, target: nil, metadata: {})
  Pave::Audit.log!(
    key: key.to_s,
    actor: current_admin,
    target: target,
    space: nil,
    metadata: metadata.merge(backoffice: true),
    source: "backoffice",
    request_id: request.request_id
  )
end
```

Required events from the design:

```txt
backoffice.settings.updated
backoffice.super_admin.granted
backoffice.super_admin.revoked
backoffice.impersonation.started
backoffice.subscription.state_forced
billing.plan.created
billing.plan.updated
```

Notes:

- The system design names events with symbols. The current runtime audit table stores `key` strings, so use stable dotted string keys and map them in docs/locales.
- Existing `AuditLogs::EventLogger` should not be used for new runtime backoffice code. Keep it only for legacy migration until old pages are removed.
- Every success notice for a mutation must mention that a backoffice audit event was recorded.

### A6. Dangerous Action Framing

Every high-impact mutation needs a confirmation UI before submit.

Required cases:

- Grant super admin.
- Revoke super admin.
- Revoke the last super admin, if allowed at all.
- Change encrypted settings or clear settings without fallback.
- Force subscription state.
- Disable integrations.
- Start impersonation.

Confirmation content must include:

- Title.
- Impact summary.
- Affected object.
- Audit statement.
- Confirmation input when destructive.
- Reason field where operationally required.

### A7. Boundary Pages

Create backoffice-owned pages:

- `pave/backoffice/errors/forbidden`
- `pave/backoffice/errors/not_found`
- `pave/backoffice/errors/tenant_scope_leak`
- `pave/backoffice/errors/panel_unavailable`

Behavior:

- Forbidden returns 403.
- Not found returns 404.
- Tenant leak returns 500 unless a custom error class maps to a safer operator status.
- Panel unavailable returns 503 or 404 depending on whether the panel exists but failed boot validation.

### A8. Auth And Audit Tests

Add request/integration tests:

- Visiting `/admin` without platform admin session redirects to `/admin/sign_in`.
- Product session alone does not grant `/admin` access.
- Backoffice sign-in creates only the platform admin session.
- Backoffice sign-out destroys only the platform admin session.
- Non-super-admin credentials are rejected.
- Disabled super admin is rejected when the model supports disabled state.
- Platform admin can access `/admin`.
- Backoffice request raises or renders tenant leak page if `Pave::Current.space` is set.
- Mutating actions write `Pave::Audit::AuditEvent` with `source: "backoffice"` and nil `space_id`.

### A9. Doctor Audit Contract

Extend `bin/pave doctor`:

- Scan `Backoffice::` and `Pave::Backoffice::` controllers for non-GET actions.
- Flag actions that do not call `audit_admin` or a declared audited service object.
- Flag routes for mutating actions that lack confirmation metadata when registered through the backoffice action helper.
- Allow explicit suppression only with a code comment explaining why the action is non-mutating.

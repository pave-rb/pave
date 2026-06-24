# Later L6 — External Distribution Specification

## Intent

Prepare Pavê runtime packages for external use only after Anella proves the design in production.

## Dependencies

- R0 through R7 complete.
- At least one adversarial plugin implemented.
- Documentation and examples stable.
- Anella benefits from runtime extraction rather than being delayed by it.

## Outcome

Runtime packages can be versioned, released, and consumed outside the monorepo.

## Scope

Define:

```text
gemspec quality
semantic version strategy
compatibility matrix
plugin dependency declaration
migration/version policy
generator stability policy
public API documentation
upgrade guide
```

## Packages

Candidate external packages:

```text
pave-core
pave-tenancy
pave-audit
pave-identity
pave-billing
pave-backoffice
pave-hotwire later
pave-agent later
pave-template later
```

## Non-goals

- Do not build a marketplace first.
- Do not promise compatibility before APIs stabilize.
- Do not publish private Anella code.
- Do not chase broad adoption before concrete examples exist.

## Acceptance criteria

- Gems build locally.
- Versioning policy documented.
- Public API docs exist.
- Example app or template exists.
- Plugin compatibility declaration works.

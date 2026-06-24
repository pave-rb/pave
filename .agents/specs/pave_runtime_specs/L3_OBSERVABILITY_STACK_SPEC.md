# Later L3 — Observability Stack Specification

## Intent

Add a reusable production observability template for Pavê deployments without making observability required for local development.

## Dependencies

- R0 through R7 complete.
- Runtime package boundaries stable.

## Outcome

Repository has optional observability configuration under `ops/observability/`.

## Scope

Create templates for:

```text
OpenTelemetry Collector
Prometheus
Loki
Tempo
Grafana
```

Suggested location:

```text
ops/observability/
  otel-collector/
  prometheus/
  loki/
  tempo/
  grafana/
  README.md
```

## Runtime contracts

Pavê should define generic instrumentation points for:

- request lifecycle
- service execution
- audit writes
- billing transitions
- plugin webhook handling
- background jobs

Do not make every runtime action emit expensive traces by default. Sampling and production toggles must exist.

## Non-goals

- Do not require Grafana stack to run Anella.
- Do not block deploy on observability if disabled.
- Do not add vendor-specific SaaS observability lock-in.

## Acceptance criteria

- Optional stack can be started from documented commands.
- Pavê emits useful generic spans/log fields when enabled.
- Disabled observability has negligible overhead.

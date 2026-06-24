# AGENTS.md — Pavê Host App

This is a **Pavê host app** — a deployable Rails application consuming the Pavê runtime.

## Key Directories

- `products/` — Domain product packages loaded by the Pavê runtime.
- `config/pave.rb` — Product and plugin registration.

## Runtime

The Pavê runtime is installed as a gem (or path dependency). See `PAVE_MANIFEST.yml` for version information.

CLI commands are available via `bin/pave`:

- `bin/pave doctor` — run health checks.
- `bin/pave list products` — list registered products.
- `bin/pave install:migrations` — copy runtime migrations.
- `bin/pave upgrade` — upgrade the Pavê runtime.

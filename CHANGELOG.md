# Changelog

## 0.1.0.alpha.1 - 2026-06-24

### Runtime
- Public runtime repository cleanup.
- MIT license included in the release state.
- Runtime gems organized under `gems/`.

### Documentation
- Clarified internal Git-tag consumption.
- Clarified that the root Rails app is a development harness, not the public host-app template.
- Clarified current versus planned install flow.
- Clarified public agent contracts versus private operator workspace.

### Release Hygiene
- Removed `.agents/` from the public tree.
- Aligned version examples with dot-separated prerelease tags.
- Prepared a clean internal release tag from the public reset state.

### Known Limitations
- Public RubyGems release is not enabled.
- Host-app install generator may still be incomplete.
- Smoke install may still be pending or partial.

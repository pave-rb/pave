# Public Repository Checklist

## Manual GitHub cleanup

Before announcing Pavê publicly:

- Delete obsolete GitHub Actions runs that expose private extraction history:
  - Add logout button to backoffice
  - Anella product changes
  - Pave gem module extraction
- Confirm Actions page only shows clean Pavê runtime runs.
- Confirm no old branches expose private history.
- Confirm `.agents/` is not present on `main`.
- Confirm `.agents/` is not reachable from any public tag.
- Confirm `v0.1.0.alpha.1` exists and points to the licensed clean release state.

## Repository hygiene

- [ ] `.agents/` is listed in `.gitignore`.
- [ ] `scripts/repo-check-clean` passes.
- [ ] `scripts/build-gems` passes.
- [ ] `scripts/smoke-install` is either implemented or honestly fails.
- [ ] All first-party gems share the same lockstep version.
- [ ] All gemspecs include MIT license and repository metadata.
- [ ] README and CHANGELOG use the current prerelease tag.
- [ ] README does not instruct production host apps to consume `branch: "main"`.
- [ ] No RubyGems publishing has occurred unless explicitly approved.

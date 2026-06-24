# Pavê releases

## Versioning

Pavê gems are versioned in lockstep. All runtime gems in this monorepo share the same version number.

Git tags follow the pattern `v<version>`, for example `v0.1.0.alpha.2`.

## Release process

1. Ensure all tests pass in the Pavê repository.
2. Update `Pave::VERSION` in `gems/pave-core/lib/pave/version.rb`.
3. Update `README.md` and `docs/` to reference the new tag.
4. Commit the version bump and documentation updates.
5. Create and push a Git tag:

   ```sh
   git tag v0.1.0.alpha.N
   git push origin v0.1.0.alpha.N
   ```

6. Validate the tag in a host app (Anella) before publishing to RubyGems.

## Current alpha tags

- `v0.1.0.alpha.1` — initial public runtime extraction
- `v0.1.0.alpha.2` — external-gem consumption validated by Anella

## RubyGems publishing gate

Pavê will only be published to RubyGems after:

- A host app (Anella) has validated a GitHub tag in staging.
- Gem boundaries are stable.
- Each gem has a clear responsibility and valid gemspec.
- Release automation or a documented manual process exists.

Do not publish alpha tags to RubyGems before the gate is passed.

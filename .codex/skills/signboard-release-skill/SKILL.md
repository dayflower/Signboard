---
name: signboard-release-skill
description: Automate the Signboard PR-first release workflow using repository scripts. Use when asked to bump semantic versions (major/minor/patch), open the version bump PR with release conventions, or validate VERSION consistency.
---

# Signboard Release Skill

## Execute the Canonical Scripts

Run all commands from repository root and use these entrypoints:

- `./scripts/bump-version-pr.sh <major|minor|patch>`
- `./scripts/version.sh assert-consistent`

## Run the Version Bump Flow

1. Ensure `VERSION` and `SignboardVersion.current` are consistent.
2. Execute `./scripts/bump-version-pr.sh <major|minor|patch>`.
3. Report branch name, commit hash, PR URL, and auto-merge status.

## Do Not Tag by Hand

Merging the bump PR triggers `.github/workflows/release.yml`, which creates the `vX.Y.Z` tag itself
with `gh release create --target` after signing and notarization succeed. Never create or push a
release tag manually; doing so makes the workflow skip the release.

## Handle Common Failures

- Version mismatch:
  - `./scripts/version.sh current`
  - `./scripts/version.sh swift-current`
  - `./scripts/version.sh sync-swift`
  - `./scripts/version.sh assert-consistent`
- Dirty working tree:
  - Stop and ask the user to commit/stash intentional changes before rerunning.
- Existing branch:
  - Stop and ask whether to reuse, delete, or choose another bump/version.

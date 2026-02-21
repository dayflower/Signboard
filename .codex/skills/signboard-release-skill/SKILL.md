---
name: signboard-release-skill
description: Automate the Signboard PR-first release workflow using repository scripts. Use when asked to bump semantic versions (major/minor/patch), open the version bump PR with release conventions, validate VERSION consistency, or create/push a lightweight release tag after merge.
---

# Signboard Release Skill

## Execute the Canonical Scripts

Run all commands from repository root and use these entrypoints:

- `./scripts/bump-version-pr.sh <major|minor|patch>`
- `./scripts/tag-merged-release.sh [version]`
- `./scripts/version.sh assert-consistent`

## Run the Version Bump Flow

1. Ensure `VERSION` and `SignboardVersion.current` are consistent.
2. Execute `./scripts/bump-version-pr.sh <major|minor|patch>`.
3. Report branch name, commit hash, PR URL, and auto-merge status.

## Run the Post-merge Tagging Flow

1. Execute `./scripts/tag-merged-release.sh` after the bump PR is merged.
2. If needed, use `./scripts/tag-merged-release.sh <version>` for explicit assertion.
3. Report tag name and push result.

## Handle Common Failures

- Version mismatch:
  - `./scripts/version.sh current`
  - `./scripts/version.sh swift-current`
  - `./scripts/version.sh sync-swift`
  - `./scripts/version.sh assert-consistent`
- Dirty working tree:
  - Stop and ask the user to commit/stash intentional changes before rerunning.
- Existing branch or tag:
  - Stop and ask whether to reuse, delete, or choose another bump/version.

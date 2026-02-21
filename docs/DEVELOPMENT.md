# Development Guide

This document covers local development and release operations.
For end-user installation and usage, see [README.md](../README.md).

## Requirements

- macOS 13 or later
- Xcode command line tools
- Swift 5.9+

## Local Build

```bash
swift build
```

## Local Run

Run the app:

```bash
swift run SignboardApp
```

In another terminal, run CLI commands:

```bash
swift run signboard --version
swift run signboard list
swift run signboard create "Hello, World!"
```

The CLI requires `SignboardApp` to be running.

## Packaging

Create a distributable app bundle:

```bash
./scripts/package-app.sh
```

Create a zip artifact:

```bash
CREATE_ZIP=1 ./scripts/package-app.sh
```

Version metadata is controlled by environment variables:

- `APP_VERSION`: maps to `CFBundleShortVersionString` (default: value from `VERSION`)
- `APP_BUILD_VERSION`: maps to `CFBundleVersion` (default: `APP_VERSION`)

Example:

```bash
APP_VERSION=0.2.0 APP_BUILD_VERSION=20260213 ./scripts/package-app.sh
```

## Version Source of Truth

- Canonical version source: repository-root `VERSION`
- Runtime version constant: `SignboardVersion.current` in `Sources/SignboardCore/SignboardCoreModels.swift`
- Supported format: strict SemVer `major.minor.patch`

Shared helper script:

```bash
./scripts/version.sh <command>
```

Commands:

- `current`: print the value in `VERSION`
- `swift-current`: print `SignboardVersion.current`
- `validate [version]`: validate strict SemVer (`VERSION` when omitted)
- `next <major|minor|patch> [version]`: compute next version
- `write <version>`: write `VERSION`
- `sync-swift [version]`: sync `SignboardVersion.current` (from `VERSION` when omitted)
- `assert-consistent`: fail unless `VERSION` and `SignboardVersion.current` match

## Codex Skill Integration

This repository ships a project-local Codex skill at:

- `.codex/skills/signboard-release-skill`

Modern Codex discovers project-local skills from `.codex/skills` directly.
No installation script is required for this repository-specific skill.

If Codex is already running, restart it after pulling changes so the updated skill is reloaded.

Skill invocation examples:

- `Use $signboard-release-skill to run a patch version bump PR for this repository.`
- `Use $signboard-release-skill to run the post-merge lightweight tagging flow for version 0.2.0.`

## Bundle Verification

From repository root:

```bash
# 1) Build the artifact
./scripts/package-app.sh

# 2) Launch bundled GUI app
open dist/SignboardApp.app

# 3) Run bundled CLI from inside the app bundle
dist/SignboardApp.app/Contents/MacOS/signboard --version
dist/SignboardApp.app/Contents/MacOS/signboard list
dist/SignboardApp.app/Contents/MacOS/signboard create "Packaged app smoke test"
```

The bundled CLI also requires the bundled app to be running.

## CI Consistency Guard

Workflow file: `.github/workflows/version-consistency.yml`

Trigger:

- `pull_request`
- Push to `main`

Main behavior:

1. Checkout repository.
2. Run `./scripts/version.sh assert-consistent`.
3. Fail checks when `VERSION` and `SignboardVersion.current` differ.

## Release Workflow

Workflow file: `.github/workflows/release.yml`

Trigger:

- Push tag matching `vX.Y.Z`

Main behavior:

1. Validate tag format and compare tag version (`vX.Y.Z`) to `VERSION`.
2. Validate `VERSION` and `SignboardVersion.current` consistency.
3. Build package artifact with `CREATE_ZIP=1 APP_VERSION=<version> APP_BUILD_VERSION=<github run number> ./scripts/package-app.sh`.
4. Rename `dist/SignboardApp.zip` to `dist/SignboardApp-<version>.zip`.
5. Generate `dist/SignboardApp-<version>.zip.sha256`.
6. Ensure a release with the same tag does not already exist.
7. Create a GitHub Release and upload both zip and checksum assets.
8. Run the `bump-homebrew-cask` job only after `release` succeeds (`needs: release`).
9. Configure Homebrew git user and run `brew tap dayflower/tap`.
10. Run a preflight check with `brew info --cask dayflower/tap/signboard`.
11. Run `Homebrew/actions/bump-packages` for `dayflower/tap/signboard`.

## PR-first Version Bump Flow

Run from a clean working tree:

```bash
./scripts/bump-version-pr.sh <major|minor|patch>
```

The script performs:

1. Read current version from `VERSION`.
2. Compute next version from bump type.
3. Create branch `chore/bump-version-vX.Y.Z`.
4. Update `VERSION` and sync `SignboardVersion.current`.
5. Commit and push the branch.
6. Open PR to `main` with title `chore: bump version to vX.Y.Z` and label `release`.
7. Enable auto-merge.

## Post-merge Tagging Flow (Lightweight Tags)

After the bump PR is merged:

```bash
./scripts/tag-merged-release.sh
```

Optional explicit version assertion:

```bash
./scripts/tag-merged-release.sh 0.2.0
```

The script performs:

1. Verify clean working tree.
2. Run `git switch main` and `git pull --ff-only`.
3. Validate `VERSION` and `SignboardVersion.current` consistency.
4. Create lightweight tag `vX.Y.Z` on merged `main` HEAD.
5. Push tag to `origin`.

## Operator Runbook for Version Mismatch

If CI reports mismatch between `VERSION` and `SignboardVersion.current`:

1. Inspect both values.

```bash
./scripts/version.sh current
./scripts/version.sh swift-current
```

2. Sync Swift constant from `VERSION`.

```bash
./scripts/version.sh sync-swift
```

3. Re-run consistency check.

```bash
./scripts/version.sh assert-consistent
```

4. Commit and push the fix through PR.

## Dry-run Bump Validation

Use helper commands to validate bump math without changing files:

```bash
./scripts/version.sh next patch
./scripts/version.sh next minor
./scripts/version.sh next major
```

Checksum verification example:

```bash
shasum -a 256 -c dist/SignboardApp-0.2.0.zip.sha256
```

Required secret:

- `HOMEBREW_GITHUB_API_TOKEN` with permission to push branches and open pull requests in `dayflower/homebrew-tap`.

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

- `APP_VERSION`: maps to `CFBundleShortVersionString` (default: `SignboardVersion.current`)
- `APP_BUILD_VERSION`: maps to `CFBundleVersion` (default: `APP_VERSION`)

Example:

```bash
APP_VERSION=0.2.0 APP_BUILD_VERSION=20260213 ./scripts/package-app.sh
```

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

## Release Workflow

Workflow file: `.github/workflows/release.yml`

Trigger:

- Push tag matching `vX.Y.Z`

Main behavior:

1. Validate tag version against `SignboardVersion.current` in `Sources/SignboardCore/SignboardCoreModels.swift`.
2. Build package artifact with `CREATE_ZIP=1 APP_VERSION=<source version> APP_BUILD_VERSION=<github run number> ./scripts/package-app.sh`.
3. Rename `dist/SignboardApp.zip` to `dist/SignboardApp-<version>.zip`.
4. Generate `dist/SignboardApp-<version>.zip.sha256`.
5. Ensure a release with the same tag does not already exist.
6. Create a GitHub Release and upload both zip and checksum assets.
7. Run the `bump-homebrew-cask` job only after `release` succeeds (`needs: release`).
8. Configure Homebrew git user and run `brew tap dayflower/tap`.
9. Run a preflight check with `brew info --cask dayflower/tap/signboard`.
10. Run `Homebrew/actions/bump-packages` for `dayflower/tap/signboard`.

## Version Bump Guide

Use this checklist when preparing a new release version:

1. Decide the next semantic version (`X.Y.Z`) and verify that the tag does not already exist.
2. Update `SignboardVersion.current` in `Sources/SignboardCore/SignboardCoreModels.swift`.
3. Run a local build to confirm the change compiles.
4. Commit the version bump.
5. Create and push a tag with the `vX.Y.Z` format from that commit.

Recommended command sequence:

```bash
# Example: release 0.1.2
NEW_VERSION=0.1.2

# 1) Ensure the tag is not already used
git tag --list "v${NEW_VERSION}"

# 2) Update Sources/SignboardCore/SignboardCoreModels.swift
#    public static let current = "${NEW_VERSION}"

# 3) Verify build
swift build

# 4) Commit
git add Sources/SignboardCore/SignboardCoreModels.swift
git commit -m "chore: bump version to v${NEW_VERSION}"

# 5) Push branch and tag
git push origin <branch>
git tag "v${NEW_VERSION}"
git push origin "v${NEW_VERSION}"
```

Notes:

- `SignboardVersion.current` is the source of truth for release versioning.
- The release workflow fails if `vX.Y.Z` and `SignboardVersion.current` do not match exactly.
- `scripts/package-app.sh` also defaults `APP_VERSION` from `SignboardVersion.current` when `APP_VERSION` is not provided.
- The workflow aborts if a GitHub Release with the same tag already exists.

Manual release steps:

```bash
git tag v0.2.0
git push origin v0.2.0
```

Checksum verification example:

```bash
shasum -a 256 -c dist/SignboardApp-0.2.0.zip.sha256
```

Required secret:

- `HOMEBREW_GITHUB_API_TOKEN` with permission to push branches and open pull requests in `dayflower/homebrew-tap`.

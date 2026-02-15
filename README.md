# Signboard

A lightweight macOS menu bar app that displays floating text panels ("signboards") on your desktop. Includes a CLI tool for scripting and automation.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)

## Why Signboard

If you use multiple macOS Spaces, it is easy to lose track of what each Space is for.
Signboard helps by placing always-visible labels directly on your desktop, such as:

- `Coding: API Refactor`
- `Writing: Blog Draft`
- `Meeting: Sprint Planning`
- `Review Queue`

You can treat each signboard as a lightweight visual anchor for each Space.

## Features

- **Floating text panels** — Display custom text anywhere on your desktop
- **Menu bar control** — Manage signboards from the system menu bar
- **Context menu editing** — Edit text, color, and opacity from each signboard
- **CLI integration** — Create and control signboards from the terminal
- **Customizable** — Adjust text color, opacity, font, and position
- **Persistent** — Signboards are saved and restored across launches
- **Modifier-based interaction** — Reposition panels and open context menus while holding a modifier key

## Build & Run

```bash
swift build
swift run SignboardApp
```

## Build Distributable App Bundle

Create a distributable artifact at `dist/SignboardApp.app`:

```bash
./scripts/package-app.sh
```

Optional release zip:

```bash
CREATE_ZIP=1 ./scripts/package-app.sh
```

Version metadata source:

- `CFBundleShortVersionString`: `APP_VERSION` env var, defaulting to `SignboardVersion.current`
- `CFBundleVersion`: `APP_BUILD_VERSION` env var, defaulting to `APP_VERSION`

Example:

```bash
APP_VERSION=0.2.0 APP_BUILD_VERSION=20260213 ./scripts/package-app.sh
```

## Release Automation (GitHub Actions)

Tag pushes that match `vX.Y.Z` trigger `.github/workflows/release.yml`.
The tag version must match `SignboardVersion.current` in source.

Generated release assets:

- `SignboardApp-<version>.zip`
- `SignboardApp-<version>.zip.sha256`

Release a new version:

```bash
git tag v0.2.0
git push origin v0.2.0
```

Checksum verification (from repository root):

```bash
shasum -a 256 -c dist/SignboardApp-0.2.0.zip.sha256
```

## Homebrew Tap Automation (GitHub Actions)

Publishing a GitHub Release triggers `.github/workflows/bump-homebrew-cask.yml`.
The workflow first runs `brew tap dayflower/tap`, then validates cask resolution with
`brew info --cask dayflower/tap/signboard` before calling
`Homebrew/actions/bump-packages`.
If the preflight check fails, the workflow exits early with a clear diagnostic message.
When preflight succeeds, `bump-packages` updates cask metadata
(version/checksum/url) in `dayflower/homebrew-tap` and opens or updates a pull
request when a bump is needed.

Required repository secret:

- `HOMEBREW_GITHUB_API_TOKEN` with permission to push branches and open pull requests in `dayflower/homebrew-tap`

## Bundle Verification Commands

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

The bundled CLI requires the bundled app to be running, same as local development.

## End-User Quick Start

1. Launch `SignboardApp`.
2. Open the menu bar item (signpost icon) and choose **New Signboard**.
3. To move a signboard: hold the drag modifier key (default: **Option**) and drag it.
4. To edit a signboard: hold the drag modifier key and right-click the signboard, then choose **Edit Signboard...**.
5. From the same context menu, you can also change **Text Color** and **Opacity**.
6. From the app menu bar menu, you can change global settings like **Font**, **Default Text Color**, and **Drag Modifier**.

## Space Workflow Tips

- Create one signboard per Space with a short role label (`Dev`, `Docs`, `Comms`, etc.).
- To place a signboard on a specific Space, open Mission Control and manually move that signboard window to the target Space.
  - **Space Guide...** in the menu shows the same guidance inside the app.
- Keep labels short so they stay readable at a glance.

## CLI Usage

The CLI requires `SignboardApp` to be running.

```bash
# List all signboards
signboard list

# Show CLI/App version
signboard --version

# Create a new signboard
signboard create "Hello, World!"

# Create with a specific ID
signboard create -i myboard "Status: OK"

# Update an existing signboard
signboard update -i {id} "Updated text"

# Hide / show all signboards
signboard hide-all
signboard show-all
```

## Preferences

| Setting       | Options                |
| ------------- | ---------------------- |
| Text color    | White, Black           |
| Opacity       | 100%, 80%, 60%, 40%    |
| Font          | System font panel      |
| Drag modifier | Option, Command, Shift |

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

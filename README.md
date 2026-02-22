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

## Install (Homebrew)

```bash
brew tap dayflower/tap
brew install --cask dayflower/tap/signboard
```

## Install (GitHub Releases)

1. Open the latest release page: [GitHub Releases](https://github.com/dayflower/Signboard/releases/latest)
2. Download `SignboardApp-<version>.zip` (and `SignboardApp-<version>.zip.sha256` if you want checksum verification).
3. Unzip and move `SignboardApp.app` to `/Applications`.
4. Launch `SignboardApp`.

## Quick Start

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

# Delete an existing signboard
signboard delete -i {id}

# Delete all signboards
signboard delete-all

# Hide / show all signboards
signboard hide-all
signboard show-all
```

Raycast Script Command examples are available in [examples/raycast](examples/raycast/README.md).

## Update

Homebrew:

```bash
brew upgrade --cask dayflower/tap/signboard
```

GitHub Releases:

1. Download the latest `SignboardApp-<version>.zip` from [GitHub Releases](https://github.com/dayflower/Signboard/releases/latest).
2. Replace your existing `SignboardApp.app` with the new one.

## Uninstall

Homebrew:

```bash
brew uninstall --cask dayflower/tap/signboard
```

GitHub Releases:

1. Quit `SignboardApp`.
2. Remove `SignboardApp.app` from `/Applications`.

## For Contributors

Developer documentation is available in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Preferences

| Setting       | Options                |
| ------------- | ---------------------- |
| Text color    | White, Black           |
| Opacity       | 100%, 80%, 60%, 40%    |
| Font          | System font panel      |
| Drag modifier | Option, Command, Shift |

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

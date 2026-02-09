# AGENTS

## Project Overview

Signboard is a macOS (13+) Swift app that shows floating text panels ("signboards") on the desktop. It ships two executables:

- `SignboardApp`: menu bar app that manages signboards.
- `signboard`: CLI that sends commands to the running app via DistributedNotificationCenter.

## Repo Structure

- `Sources/SignboardApp`: AppKit UI, menu, preferences, command handling.
- `Sources/SignboardCore`: Shared models and notification payloads.
- `Sources/signboard`: CLI entry point and argument parsing.

## Build & Run

- `swift build`
- `swift run SignboardApp`
- `swift run signboard list | create | set -i <id> | hide-all | show-all`

## Conventions

- Keep UI work on the main thread.
- Update persisted signboard data via `SignboardStore` after any user-visible changes.
- Prefer changes in `SignboardCore` when adding shared command or model behavior.

## Notes

- CLI requires the app to be running.
- Data is stored in `UserDefaults`.
- No automated tests.

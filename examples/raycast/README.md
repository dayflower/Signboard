# Raycast Script Commands for Signboard

This directory contains example Raycast Script Commands for Signboard.

## Included Commands

- `list-signboards.sh`: runs `signboard list`
- `create-signboard.sh`: runs `signboard create <text>`
- `delete-signboard.sh`: runs `signboard delete -i <id>`
- `delete-all-signboards.sh`: runs `signboard delete-all`
- `hide-all-signboards.sh`: runs `signboard hide-all`
- `show-all-signboards.sh`: runs `signboard show-all`

## Behavior

- `list-signboards.sh` prints `No signboards.` only when `signboard list` succeeds with empty stdout.
- `create-signboard.sh` accepts only text input. It does not support `-i <id>`.
- `delete-signboard.sh` requires confirmation in Raycast and takes a signboard ID.
- IDs can be obtained from `Signboard: List`.
- `delete-signboard.sh` forwards CLI error output on failure and prints completion output on success.
- `delete-all-signboards.sh` requires confirmation in Raycast before execution.
- `delete-all-signboards.sh` forwards CLI error output on failure and prints completion output on success.
- If `SignboardApp` is not running, commands fail with a non-zero exit code.
- Script feedback is based on process exit code.
- Scripts assume `signboard` is available in `PATH`.

## Setup

1. Copy the scripts in this directory to your Raycast Script Commands directory.
2. Make scripts executable:

```bash
chmod +x create-signboard.sh delete-all-signboards.sh delete-signboard.sh hide-all-signboards.sh list-signboards.sh show-all-signboards.sh
```

3. Open Raycast and run each command once.

## Exit Codes

- `0`: Success
- Non-zero: Failure
- `3`: `SignboardApp` is not running (returned by `signboard`)

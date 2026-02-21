# Raycast Script Commands for Signboard

This directory contains example Raycast Script Commands for Signboard.

## Included Commands

- `create-signboard.sh`: runs `signboard create <text>`
- `hide-all-signboards.sh`: runs `signboard hide-all`
- `show-all-signboards.sh`: runs `signboard show-all`

## Behavior

- `create-signboard.sh` accepts only text input. It does not support `-i <id>`.
- If `SignboardApp` is not running, commands fail with a non-zero exit code.
- Script feedback is based on process exit code.
- Scripts assume `signboard` is available in `PATH`.

## Setup

1. Copy the scripts in this directory to your Raycast Script Commands directory.
2. Make scripts executable:

```bash
chmod +x create-signboard.sh hide-all-signboards.sh show-all-signboards.sh
```

3. Open Raycast and run each command once.

## Exit Codes

- `0`: Success
- Non-zero: Failure
- `3`: `SignboardApp` is not running (returned by `signboard`)

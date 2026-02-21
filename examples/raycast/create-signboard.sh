#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Signboard: Create
# @raycast.mode compact
#
# Optional parameters:
# @raycast.packageName Signboard
# @raycast.argument1 { "type": "text", "placeholder": "Signboard text" }
#
# Documentation:
# @raycast.description Create a signboard via `signboard create`.
# @raycast.author dayflower
# @raycast.authorURL https://github.com/dayflower

set -u

text="${1-}"
if [[ -z "${text// }" ]]; then
  echo "text is required"
  exit 1
fi

signboard create "$text"

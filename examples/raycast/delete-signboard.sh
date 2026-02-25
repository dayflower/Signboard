#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Signboard: Delete
# @raycast.mode compact
#
# Optional parameters:
# @raycast.packageName Signboard
# @raycast.argument1 { "type": "text", "placeholder": "Signboard ID" }
# @raycast.needsConfirmation true
#
# Documentation:
# @raycast.description Delete a signboard via `signboard delete -i <id>`.
# @raycast.author dayflower
# @raycast.authorURL https://github.com/dayflower

set -u

id="${1-}"
if [[ -z "${id// }" ]]; then
  echo "id is required"
  exit 1
fi

output_file="$(mktemp)"
trap 'rm -f "$output_file"' EXIT

signboard delete -i "$id" >"$output_file" 2>&1
status=$?

if [[ $status -eq 0 ]]; then
  if [[ -s "$output_file" ]]; then
    cat "$output_file"
  else
    echo "Deleted signboard."
  fi
else
  cat "$output_file"
fi

exit "$status"

#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Signboard: Delete All
# @raycast.mode compact
#
# Optional parameters:
# @raycast.packageName Signboard
# @raycast.needsConfirmation true
#
# Documentation:
# @raycast.description Delete all signboards via `signboard delete-all`.
# @raycast.author dayflower
# @raycast.authorURL https://github.com/dayflower

output_file="$(mktemp)"
trap 'rm -f "$output_file"' EXIT

signboard delete-all >"$output_file" 2>&1
status=$?

if [[ $status -eq 0 ]]; then
  if [[ -s "$output_file" ]]; then
    cat "$output_file"
  else
    echo "Deleted all signboards."
  fi
else
  cat "$output_file"
fi

exit "$status"

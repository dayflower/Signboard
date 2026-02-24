#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Signboard: List
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.packageName Signboard
#
# Documentation:
# @raycast.description List signboards via `signboard list`.
# @raycast.author dayflower
# @raycast.authorURL https://github.com/dayflower

output_file="$(mktemp)"
trap 'rm -f "$output_file"' EXIT

signboard list >"$output_file"
status=$?

if [[ $status -eq 0 ]]; then
  if [[ -s "$output_file" ]]; then
    cat "$output_file"
  else
    echo "No signboards."
  fi
else
  cat "$output_file"
fi

exit "$status"

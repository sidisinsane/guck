#!/usr/bin/env bash
# ---
# description: Reports a structured snapshot of the current project.
# usage: project.sh [dir]
# exits:
#   0: success
#   1: failed to source a required helper
# ---

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"

sections=()
for helper in "${SCRIPT_DIR}"/_detect-*.sh; do
  # shellcheck source=/dev/null
  source "$helper" || {
    echo "error: failed to source $(basename "$helper")" >&2
    exit 1
  }
  fn="detect_$(basename "$helper" .sh | sed 's/^_detect-//' | tr '-' '_')"
  output=$("$fn" "$TARGET_DIR" 2>/dev/null) || continue
  output="${output%$'\n'}"
  [[ -z "$output" ]] && continue
  sections+=("$output")
done

printf '%s' "$(IFS=$'\n'; echo "${sections[*]}")"

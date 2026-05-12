#!/usr/bin/env bash
# ---
# description: Reports a structured snapshot of the current project.
# usage: guck project info
# exits:
#   0: success
#   1: failed to source a required helper
# ---

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CATEGORY="$(basename "$SCRIPT_DIR")"
ENDPOINT="$(basename "${BASH_SOURCE[0]}" .sh)"
TARGET_DIR="."

sections=()
for helper in "${SCRIPT_DIR}"/_${ENDPOINT}-*.sh; do
  # shellcheck source=/dev/null
  source "$helper" || {
    echo "error: failed to source $(basename "$helper")" >&2
    exit 1
  }
  fn="${ENDPOINT}_$(basename "$helper" .sh | sed "s/^_${ENDPOINT}-//" | tr '-' '_')"
  output=$("$fn" "$TARGET_DIR" 2>/dev/null) || continue
  output="${output%$'\n'}"
  [[ -z "$output" ]] && continue
  sections+=("$output")
done

printf '%s\n' "$(IFS=$'\n'; echo "${sections[*]}")"

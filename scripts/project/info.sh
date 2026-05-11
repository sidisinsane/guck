#!/usr/bin/env bash
# ---
# description: Reports a structured snapshot of the current project.
# usage: guck project info [dir]
# exits:
#   0: success
#   1: failed to source a required helper
# ---

set -eo pipefail

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"

sections=()
for helper in "${SCRIPT_DIR}"/_${SCRIPT_NAME}-*.sh; do
  # shellcheck source=/dev/null
  source "$helper" || {
    echo "error: failed to source $(basename "$helper")" >&2
    exit 1
  }
  fn="${SCRIPT_NAME}_$(basename "$helper" .sh | sed "s/^_${SCRIPT_NAME}-//" | tr '-' '_')"
  output=$("$fn" "$TARGET_DIR" 2>/dev/null) || continue
  output="${output%$'\n'}"
  [[ -z "$output" ]] && continue
  sections+=("$output")
done

printf '%s' "$(IFS=$'\n'; echo "${sections[*]}")"

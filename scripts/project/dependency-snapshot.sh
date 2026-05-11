#!/usr/bin/env bash
# ---
# description: Reports a dependency snapshot for the specified package manager.
# usage: guck project dependency-snapshot <npm|go> [--dev|--all]
# exits:
#   0: success
#   1: failed to source a required helper or unsupported package manager
# ---

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CATEGORY="$(basename "$SCRIPT_DIR")"
ENDPOINT="$(basename "${BASH_SOURCE[0]}" .sh)"

if [[ $# -eq 0 ]]; then
  echo "usage: guck ${CATEGORY} ${ENDPOINT} <manager> [--dev|--all]" >&2
  exit 1
fi

manager="$1"
shift

helper="${SCRIPT_DIR}/_${ENDPOINT}-${manager}.sh"

if [[ ! -f "$helper" ]]; then
  echo "error: unsupported package manager: ${manager}" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$helper" || {
  echo "error: failed to source $(basename "$helper")" >&2
  exit 1
}

fn="$(echo "${ENDPOINT}_$manager" | tr '-' '_')"
"$fn" "$@"

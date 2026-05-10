#!/usr/bin/env bash
# ---
# description: Dispatches to the appropriate script in the guck collection.
# usage: guck <category> [script] [args...]
# exits:
#   0: success
#   1: script not found or execution failed
# ---

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"

if [[ $# -eq 0 ]]; then
  echo "usage: guck <category> [script] [args...]" >&2
  exit 1
fi

category="$1"
shift

# Try orchestrator pattern: scripts/<category>/<category>.sh
# All remaining args pass through.
orchestrator="${SCRIPTS_DIR}/${category}/${category}.sh"
if [[ -f "$orchestrator" ]]; then
  exec "$orchestrator" "$@"
fi

# Try standalone pattern: scripts/<category>/<script>.sh
# First remaining arg is the script name, rest pass through.
if [[ $# -ge 1 ]]; then
  script="$1"
  shift
  target="${SCRIPTS_DIR}/${category}/${script}.sh"
  if [[ -f "$target" ]]; then
    exec "$target" "$@"
  fi
  echo "guck: script not found: ${category}/${script}" >&2
  exit 1
fi

echo "guck: unknown category: ${category}" >&2
exit 1

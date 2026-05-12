#!/usr/bin/env bash
# ---
# description: Dispatches to the appropriate script in the guck collection.
# usage: guck <category> <endpoint> [args...]
# exits:
#   0: success
#   1: script not found or execution failed
# ---

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"

# =============================================================================
# Helper: list available categories
# =============================================================================
_guck_categories() {
  ls "${SCRIPTS_DIR}" 2>/dev/null | tr '\n' ' ' | sed 's/ $//'
}

# =============================================================================
# Helper: list available endpoints for a category
# =============================================================================
_guck_endpoints() {
  local category="$1"
  ls "${SCRIPTS_DIR}/${category}" 2>/dev/null \
    | grep -v '^_' \
    | sed 's/\.sh$//' \
    | tr '\n' ' ' \
    | sed 's/ $//'
}

# =============================================================================
# Helper: print full shallow usage (no args or unknown category)
# =============================================================================
_guck_usage_shallow() {
  echo "usage: guck <category> <endpoint> [args...]" >&2
  echo "categories: $(_guck_categories)" >&2
  echo "endpoints:" >&2
  for cat in $(ls "${SCRIPTS_DIR}" 2>/dev/null); do
    echo "  ${cat}: $(_guck_endpoints "$cat")" >&2
  done
}

# =============================================================================
# Helper: print middle usage (missing or unknown endpoint)
# =============================================================================
_guck_usage_middle() {
  local category="$1"
  echo "usage: guck ${category} <endpoint>" >&2
  echo "endpoints: $(_guck_endpoints "$category")" >&2
}

# =============================================================================
# Dispatch
# =============================================================================
if [[ $# -eq 0 ]]; then
  _guck_usage_shallow
  exit 1
fi

category="$1"
shift

# Unknown category
if [[ ! -d "${SCRIPTS_DIR}/${category}" ]]; then
  echo "error: unknown category \"${category}\"" >&2
  _guck_usage_shallow
  exit 1
fi

# Try standalone pattern: scripts/<category>/<script>.sh
if [[ $# -ge 1 ]]; then
  script="$1"
  shift
  target="${SCRIPTS_DIR}/${category}/${script}.sh"
  if [[ -f "$target" ]]; then
    exec "$target" "$@"
  fi
  echo "error: unknown endpoint \"${script}\" in \"${category}\"" >&2
  _guck_usage_middle "$category"
  exit 1
fi

# Missing endpoint
echo "error: missing endpoint for \"${category}\"" >&2
_guck_usage_middle "$category"
exit 1

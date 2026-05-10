#!/usr/bin/env bash
# ---
# description: Reports installed network tools and their versions.
# usage: network-tools.sh
# exits:
#   0: success
#   1: no network tools detected
# ---

set -eo pipefail

# =============================================================================
# Network tool registry
# Maps tool name to version command.
# To add a new tool: ["tool_name"]="version_command"
# =============================================================================
declare -A version_cmds=(
  ["curl"]="curl --version 2>/dev/null | awk 'NR==1{print \$2}'"
  ["wget"]="wget --version 2>/dev/null | awk 'NR==1{print \$3}'"
  ["xh"]="xh --version 2>/dev/null"
  ["httpie"]="http --version 2>/dev/null"
)

detected=()

for tool in "${!version_cmds[@]}"; do
  ver=$(eval "${version_cmds[$tool]}" 2>/dev/null) || continue
  [[ -z "$ver" ]] && continue
  detected+=("${tool}|${ver}")
done

if [[ ${#detected[@]} -eq 0 ]]; then
  exit 1
fi

IFS=$'\n' sorted=($(sort <<< "${detected[*]}")); unset IFS

for entry in "${sorted[@]}"; do
  tool="${entry%%|*}"
  ver="${entry#*|}"
  echo "- name: ${tool}"
  echo "  installed: ${ver}"
done

#!/usr/bin/env bash
# ---
# description: Reports installed data processing tools and their versions.
# usage: guck env data-tools
# exits:
#   0: success
#   1: no data tools detected
# ---

set -eo pipefail

# =============================================================================
# Data tool registry
# Maps tool name to version command.
# To add a new tool: ["tool_name"]="version_command"
# =============================================================================
declare -A version_cmds=(
  ["jq"]="jq --version 2>/dev/null | tr -d 'jq-'"
  ["yq"]="yq --version 2>/dev/null | awk '{print \$NF}' | tr -d 'v'"
  ["fx"]="fx --version 2>/dev/null"
  ["gron"]="gron --version 2>/dev/null | awk '{print \$2}'"
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

printf 'name\tinstalled\n'
for entry in "${sorted[@]}"; do
  tool="${entry%%|*}"
  ver="${entry#*|}"
  printf '%s\t%s\n' "$tool" "$ver"
done

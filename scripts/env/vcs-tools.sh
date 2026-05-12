#!/usr/bin/env bash
# ---
# description: Reports installed version control tools and their versions.
# usage: guck env vcs-tools
# exits:
#   0: success
#   1: no VCS tools detected
# ---

set -eo pipefail

# =============================================================================
# VCS tool registry
# Maps tool name to version command.
# To add a new tool: ["tool_name"]="version_command"
# =============================================================================
declare -A version_cmds=(
  ["git"]="git --version 2>/dev/null | awk '{print \$3}'"
  ["gh"]="gh --version 2>/dev/null | awk 'NR==1{print \$3}'"
  ["hub"]="hub --version 2>/dev/null | awk 'NR==2{print \$3}'"
  ["tig"]="tig --version 2>/dev/null | awk '{print \$3}'"
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

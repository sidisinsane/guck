#!/usr/bin/env bash
# ---
# description: Reports installed container and orchestration tools and their versions.
# usage: guck env container-tools
# exits:
#   0: success
#   1: no container tools detected
# ---

set -eo pipefail

# =============================================================================
# Container tool registry
# Maps tool name to version command.
# To add a new tool: ["tool_name"]="version_command"
# =============================================================================
declare -A version_cmds=(
  ["docker"]="docker --version 2>/dev/null | awk '{print \$3}' | tr -d ','"
  ["podman"]="podman --version 2>/dev/null | awk '{print \$3}'"
  ["kubectl"]="kubectl version --client 2>/dev/null | awk '/Client/{print \$3}' | tr -d 'v'"
  ["helm"]="helm version --short 2>/dev/null | tr -d 'v+'"
  ["minikube"]="minikube version 2>/dev/null | awk '{print \$3}' | tr -d 'v'"
  ["k9s"]="k9s version 2>/dev/null | awk '/Version/{print \$2}' | tr -d 'v'"
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

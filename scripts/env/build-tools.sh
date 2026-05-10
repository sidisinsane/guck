#!/usr/bin/env bash
# ---
# description: Reports installed build tools, optionally filtered by runtime group.
# usage: build-tools.sh [runtime...]
# exits:
#   0: success
#   1: no build tools detected
# ---

set -eo pipefail

# =============================================================================
# Build tool registry
# Maps tool name to runtime group.
# To add a new tool: ["tool_name"]="runtime_group"
# =============================================================================
declare -A build_tools=(
  ["make"]="universal"
  ["cmake"]="universal"
  ["ninja"]="universal"
  ["go"]="go"
  ["cargo"]="rust"
  ["rustc"]="rust"
  ["npm"]="nodejs"
  ["pnpm"]="nodejs"
  ["yarn"]="nodejs"
  ["python3"]="python"
  ["pip"]="python"
  ["uv"]="python"
  ["poetry"]="python"
  ["mvn"]="java"
  ["gradle"]="java"
  ["composer"]="php"
  ["bundler"]="ruby"
  ["rake"]="ruby"
)

# =============================================================================
# Version commands per tool
# Maps tool name to the command that prints its version string.
# =============================================================================
declare -A version_cmds=(
  ["make"]="make --version 2>/dev/null | awk 'NR==1{print \$3}'"
  ["cmake"]="cmake --version 2>/dev/null | awk 'NR==1{print \$3}'"
  ["ninja"]="ninja --version 2>/dev/null"
  ["go"]="go version 2>/dev/null | awk '{print \$3}' | sed 's/go//'"
  ["cargo"]="cargo --version 2>/dev/null | awk '{print \$2}'"
  ["rustc"]="rustc --version 2>/dev/null | awk '{print \$2}'"
  ["npm"]="npm --version 2>/dev/null"
  ["pnpm"]="pnpm --version 2>/dev/null"
  ["yarn"]="yarn --version 2>/dev/null"
  ["python3"]="python3 --version 2>/dev/null | awk '{print \$2}'"
  ["pip"]="pip --version 2>/dev/null | awk '{print \$2}'"
  ["uv"]="uv --version 2>/dev/null | awk '{print \$2}'"
  ["poetry"]="poetry --version 2>/dev/null | awk '{print \$3}' | tr -d ')'"
  ["mvn"]="mvn --version 2>/dev/null | awk 'NR==1{print \$3}'"
  ["gradle"]="gradle --version 2>/dev/null | grep '^Gradle' | awk '{print \$2}'"
  ["composer"]="composer --version 2>/dev/null | awk '{print \$3}'"
  ["bundler"]="bundler --version 2>/dev/null | awk '{print \$3}'"
  ["rake"]="rake --version 2>/dev/null | awk '{print \$3}'"
)

# Collect runtime filter from positional arguments
filter=("$@")

_matches_filter() {
  local group="$1"
  [[ ${#filter[@]} -eq 0 ]] && return 0
  for f in "${filter[@]}"; do
    [[ "$f" == "$group" ]] && return 0
  done
  return 1
}

detected=()

for tool in "${!build_tools[@]}"; do
  group="${build_tools[$tool]}"
  _matches_filter "$group" || continue

  cmd="${version_cmds[$tool]}"
  [[ -z "$cmd" ]] && continue

  ver=$(eval "$cmd" 2>/dev/null) || continue
  [[ -z "$ver" ]] && continue

  detected+=("${tool}|${group}|${ver}")
done

if [[ ${#detected[@]} -eq 0 ]]; then
  exit 1
fi

IFS=$'\n' sorted=($(sort <<< "${detected[*]}")); unset IFS

for entry in "${sorted[@]}"; do
  tool="${entry%%|*}"
  rest="${entry#*|}"
  group="${rest%%|*}"
  ver="${rest#*|}"

  echo "- name: ${tool}"
  echo "  runtime: ${group}"
  echo "  installed: ${ver}"
done

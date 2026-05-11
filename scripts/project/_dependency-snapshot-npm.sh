#!/usr/bin/env bash
# ---
# description: Detects npm dependencies and reports name, version, and depth.
# usage: source _dependency-snapshot-npm.sh && dependency_snapshot_npm [--dev|--all]
# requires: npm 7+, jq
# exits:
#   0: success
#   1: npm or jq not found, unsupported npm version, or no dependencies detected
# ---

dependency_snapshot_npm() {
  local mode="prod"

  for arg in "$@"; do
    case "$arg" in
      --dev) mode="dev" ;;
      --all) mode="all" ;;
    esac
  done

  # Check for jq
  if ! command -v jq > /dev/null 2>&1; then
    echo "error: jq is required but not found" >&2
    return 1
  fi

  # Check for npm
  if ! command -v npm > /dev/null 2>&1; then
    echo "error: npm is required but not found" >&2
    return 1
  fi

  # Check for npm 7+
  local npm_version
  npm_version=$(npm --version 2>/dev/null)
  local npm_major
  npm_major=$(echo "$npm_version" | awk -F'.' '{print $1}')
  if [[ "$npm_major" -lt 7 ]]; then
    echo "error: npm 7+ is required (found ${npm_version})" >&2
    return 1
  fi

  # Check for package.json when filtering is needed
  if [[ "$mode" != "all" ]] && [[ ! -f "package.json" ]]; then
    echo "error: package.json not found" >&2
    return 1
  fi

  # Build filter list from package.json
  local filter_keys=""
  if [[ "$mode" == "prod" ]]; then
    filter_keys=$(jq -r '.dependencies // {} | keys[]' package.json)
  elif [[ "$mode" == "dev" ]]; then
    filter_keys=$(jq -r '.devDependencies // {} | keys[]' package.json)
  fi

  # Step 1 — get full flat list with root_pkg as first column
  local raw
  raw=$(npm ls --all --json 2>/dev/null | jq -r '
    [
      paths(scalars) as $p
      | select($p[-1] == "version")
      | select($p[0] == "dependencies")
      | {
          root: $p[1],
          name: ($p | map(select(. != "dependencies" and . != "version")) | .[-1]),
          version: getpath($p),
          depth: (($p | length - 1) / 2)
        }
      | select(.name != null)
    ]
    | group_by(.name)
    | map(min_by(.depth))
    | sort_by(.depth)
    | .[]
    | [.root, .name, .version, .depth]
    | @tsv
  ')

  [[ -z "$raw" ]] && return 1

  # Step 2 — filter by root package and drop root column
  printf 'name\tversion\tdepth\n'

  if [[ "$mode" == "all" ]]; then
    echo "$raw" | awk -F'\t' '{print $2"\t"$3"\t"$4}'
  else
    echo "$raw" | awk -F'\t' '
      NR==FNR { allowed[$1] = 1; next }
      allowed[$1] { print $2"\t"$3"\t"$4 }
    ' <(echo "$filter_keys") -
  fi
}
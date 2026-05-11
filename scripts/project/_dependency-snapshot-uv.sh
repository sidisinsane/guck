#!/usr/bin/env bash
# ---
# description: Detects uv dependencies and reports name, version, and depth.
# usage: source _dependency-snapshot-uv.sh && dependency_snapshot_uv [--dev|--all]
# requires: uv
# exits:
#   0: success
#   1: uv not found, not a uv project, or no dependencies detected
# ---

dependency_snapshot_uv() {
  local group_flag="--no-dev"

  for arg in "$@"; do
    case "$arg" in
      --dev) group_flag="--only-dev" ;;
      --all) group_flag="--all-groups" ;;
    esac
  done

  # Check for uv
  if ! command -v uv > /dev/null 2>&1; then
    echo "error: uv is required but not found" >&2
    return 1
  fi

  # Check for pyproject.toml
  if [[ ! -f "pyproject.toml" ]]; then
    echo "error: pyproject.toml not found" >&2
    return 1
  fi

  # Step 1 — get direct dependencies (depth 1)
  declare -A direct
  while read -r name; do
    direct["$name"]=1
  done < <(uv tree --universal "$group_flag" --depth 1 --frozen 2>/dev/null \
    | tail -n +2 \
    | awk '{
        # strip tree chars and (group: ...) labels
        gsub(/^[├└│ ─]+/, "")
        if (/^\(\*\)/) next
        gsub(/ \(.*\)$/, "")
        print $1
      }')

  # Step 2 — get full tree
  local rows=()
  while read -r name version; do
    local depth
    if [[ -n "${direct[$name]}" ]]; then
      depth=1
    else
      depth=2
    fi
    rows+=("${depth}|${name}|${version}")
  done < <(uv tree --universal "$group_flag" --frozen 2>/dev/null \
    | tail -n +2 \
    | awk '{
        # strip tree chars, (*) dedupe markers, and (group: ...) labels
        gsub(/^[├└│ ─]+/, "")
        if (/^\(\*\)/) next
        gsub(/ \(\*\)$/, "")
        gsub(/ \(.*\)$/, "")
        if (NF >= 2) print $1, $2
      }' \
    | sort -u)

  [[ ${#rows[@]} -eq 0 ]] && return 1

  # Step 3 — sort and output
  printf 'name\tversion\tdepth\n'
  IFS=$'\n' sorted=($(printf '%s\n' "${rows[@]}" | sort -t'|' -k1,1n -k2,2)); unset IFS
  for row in "${sorted[@]}"; do
    depth="${row%%|*}"
    rest="${row#*|}"
    name="${rest%%|*}"
    version="${rest#*|}"
    printf '%s\t%s\t%s\n' "$name" "$version" "$depth"
  done
}

#!/usr/bin/env bash
# ---
# description: Detects cargo dependencies and reports name, version, and depth.
# usage: source _dependency-snapshot-cargo.sh && dependency_snapshot_cargo [--dev|--all]
# requires: cargo, jq
# exits:
#   0: success
#   1: cargo or jq not found, not a cargo project, or no dependencies detected
# ---

dependency_snapshot_cargo() {
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

  # Check for cargo
  if ! command -v cargo > /dev/null 2>&1; then
    echo "error: cargo is required but not found" >&2
    return 1
  fi

  # Check for Cargo.toml
  if [[ ! -f "Cargo.toml" ]]; then
    echo "error: Cargo.toml not found" >&2
    return 1
  fi

  # Step 1 — get metadata once
  local metadata
  metadata=$(cargo metadata --format-version 1 2>/dev/null)

  [[ -z "$metadata" ]] && return 1

  # Step 2 — get direct dependency names filtered by kind
  local direct_deps
  if [[ "$mode" == "prod" ]]; then
    direct_deps=$(echo "$metadata" | jq -r '
      .packages[]
      | select(.source == null)
      | .dependencies[]
      | select(.kind == null)
      | .name
    ')
  elif [[ "$mode" == "dev" ]]; then
    direct_deps=$(echo "$metadata" | jq -r '
      .packages[]
      | select(.source == null)
      | .dependencies[]
      | select(.kind == "dev")
      | .name
    ')
  else
    direct_deps=$(echo "$metadata" | jq -r '
      .packages[]
      | select(.source == null)
      | .dependencies[]
      | .name
    ')
  fi

  [[ -z "$direct_deps" ]] && return 1

  # Step 3 — get full package list with versions, excluding root package
  local raw
  raw=$(echo "$metadata" | jq -r '
    .packages[]
    | select(.source != null)
    | [.name, .version]
    | @tsv
  ')

  [[ -z "$raw" ]] && return 1

  # Step 4 — assign depth by cross-referencing direct deps, filter by mode
  printf 'name\tversion\tdepth\n'

  local rows=()
  while IFS=$'\t' read -r name version; do
    local depth=2
    if echo "$direct_deps" | grep -qx "$name"; then
      depth=1
    fi
    rows+=("${depth}|${name}|${version}")
  done < <(echo "$raw")

  # Filter to only include packages reachable from direct deps when not --all
  if [[ "$mode" != "all" ]]; then
    local filtered=()
    for row in "${rows[@]}"; do
      depth="${row%%|*}"
      if [[ "$depth" -eq 1 ]]; then
        filtered+=("$row")
      fi
    done
    # Include transitives of direct deps
    for row in "${rows[@]}"; do
      depth="${row%%|*}"
      if [[ "$depth" -eq 2 ]]; then
        filtered+=("$row")
      fi
    done
    rows=("${filtered[@]}")
  fi

  IFS=$'\n' sorted=($(printf '%s\n' "${rows[@]}" | sort -t'|' -k1,1n -k2,2)); unset IFS
  for row in "${sorted[@]}"; do
    depth="${row%%|*}"
    rest="${row#*|}"
    name="${rest%%|*}"
    version="${rest#*|}"
    printf '%s\t%s\t%s\n' "$name" "$version" "$depth"
  done
}

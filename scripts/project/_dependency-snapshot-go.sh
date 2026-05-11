#!/usr/bin/env bash
# ---
# description: Detects Go module dependencies and reports name, version, and depth.
# usage: source _dependency-snapshot-go.sh && dependency_snapshot_go
# requires: go, jq
# exits:
#   0: success
#   1: go or jq not found, not a go module, or no dependencies detected
# ---

dependency_snapshot_go() {
  # Check for jq
  if ! command -v jq > /dev/null 2>&1; then
    echo "error: jq is required but not found" >&2
    return 1
  fi

  # Check for go
  if ! command -v go > /dev/null 2>&1; then
    echo "error: go is required but not found" >&2
    return 1
  fi

  # Check for go.mod
  if [[ ! -f "go.mod" ]]; then
    echo "error: go.mod not found" >&2
    return 1
  fi

  # Step 1 — parse go.mod for declared dependencies
  declare -A gomod_deps
  while IFS=$'\t' read -r name version depth; do
    gomod_deps["$name"]="${version}|${depth}"
  done < <(awk '
    /^require \(/ { in_block=1; next }
    /^\)/ { in_block=0; next }
    /^require / && NF >= 3 {
      name=$2; version=$3
      indirect = (NF >= 4 && $4 == "//") ? 2 : 1
      print name "\t" version "\t" indirect
      next
    }
    in_block && NF >= 2 {
      name=$1; version=$2
      indirect = (NF >= 3 && $3 == "//") ? 2 : 1
      print name "\t" version "\t" indirect
    }
  ' go.mod)

  # Step 2 — get full graph from go list
  local golist
  golist=$(go list -m -json all 2>/dev/null | jq -rs '
    [
      .[]
      | select(.Version != null)
      | select(.Main != true)
      | { name: .Path, version: .Version, depth: (if .Indirect then 2 else 1 end) }
    ]
    | .[]
    | [.name, .version, .depth]
    | @tsv
  ')

  [[ -z "$golist" && ${#gomod_deps[@]} -eq 0 ]] && return 1

  # Step 3 — collect all rows, substituting go.mod data where available
  local rows=()

  while IFS=$'\t' read -r name version depth; do
    if [[ -n "${gomod_deps[$name]}" ]]; then
      version="${gomod_deps[$name]%%|*}"
      depth="${gomod_deps[$name]##*|}"
      unset "gomod_deps[$name]"
    fi
    rows+=("${depth}|${name}|${version}")
  done < <(echo "$golist")

  # Step 4 — append any go.mod deps missing from go list (workspace modules)
  for name in "${!gomod_deps[@]}"; do
    version="${gomod_deps[$name]%%|*}"
    depth="${gomod_deps[$name]##*|}"
    rows+=("${depth}|${name}|${version}")
  done

  [[ ${#rows[@]} -eq 0 ]] && return 1

  # Step 5 — sort and output
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

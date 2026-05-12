#!/usr/bin/env bash
# ---
# description: Detects Composer dependencies and reports name, version, and depth.
# usage: source _dependency-snapshot-composer.sh && dependency_snapshot_composer [--dev|--all]
# requires: jq
# exits:
#   0: success
#   1: jq not found, not a composer project, or no dependencies detected
# ---

dependency_snapshot_composer() {
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

  # Check for composer.json and composer.lock
  if [[ ! -f "composer.json" ]]; then
    echo "error: composer.json not found" >&2
    return 1
  fi

  if [[ ! -f "composer.lock" ]]; then
    echo "error: composer.lock not found" >&2
    return 1
  fi

  # Step 1 — collect direct prod and dev dep names from composer.json.
  # Exclude platform requirements (php, ext-*, lib-*).
  declare -A direct_prod
  while IFS= read -r name; do
    direct_prod["$name"]=1
  done < <(jq -r '(.require // {}) | keys[] | select(test("^(php$|ext-|lib-)") | not)' composer.json)

  declare -A direct_dev
  while IFS= read -r name; do
    direct_dev["$name"]=1
  done < <(jq -r '(."require-dev" // {}) | keys[] | select(test("^(php$|ext-|lib-)") | not)' composer.json)

  # Step 2 — read all resolved packages from composer.lock.
  # packages[]     = prod (including transitive prod deps)
  # packages-dev[] = dev  (including transitive dev deps)
  local rows=()

  while IFS=$'\t' read -r name version; do
    local depth=2
    [[ -n "${direct_prod[$name]}" ]] && depth=1
    rows+=("${depth}|prod|${name}|${version}")
  done < <(jq -r '.packages[] | [.name, .version] | @tsv' composer.lock)

  while IFS=$'\t' read -r name version; do
    local depth=2
    [[ -n "${direct_dev[$name]}" ]] && depth=1
    rows+=("${depth}|dev|${name}|${version}")
  done < <(jq -r '."packages-dev"[] | [.name, .version] | @tsv' composer.lock)

  [[ ${#rows[@]} -eq 0 ]] && return 1

  # Step 3 — filter by mode and output
  local filtered=()
  for row in "${rows[@]}"; do
    local group="${row#*|}"
    group="${group%%|*}"
    case "$mode" in
      prod) [[ "$group" == "dev" ]] && continue ;;
      dev)  [[ "$group" == "prod" ]] && continue ;;
    esac
    filtered+=("$row")
  done

  [[ ${#filtered[@]} -eq 0 ]] && return 1

  printf 'name\tversion\tdepth\n'
  IFS=$'\n' sorted=($(printf '%s\n' "${filtered[@]}" | sort -t'|' -k1,1n -k3,3)); unset IFS
  for row in "${sorted[@]}"; do
    depth="${row%%|*}"
    rest="${row#*|}"
    rest="${rest#*|}"
    name="${rest%%|*}"
    version="${rest#*|}"
    printf '%s\t%s\t%s\n' "$name" "$version" "$depth"
  done
}

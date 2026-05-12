#!/usr/bin/env bash
# ---
# description: Detects Maven dependencies and reports name, version, and depth.
# usage: source _dependency-snapshot-maven.sh && dependency_snapshot_maven [--dev|--all]
# requires: mvn
# exits:
#   0: success
#   1: mvn not found, not a maven project, or no dependencies detected
# ---

dependency_snapshot_maven() {
  local mode="prod"

  for arg in "$@"; do
    case "$arg" in
      --dev) mode="dev" ;;
      --all) mode="all" ;;
    esac
  done

  # Check for mvn
  if ! command -v mvn > /dev/null 2>&1; then
    echo "error: mvn is required but not found" >&2
    return 1
  fi

  # Check for pom.xml
  if [[ ! -f "pom.xml" ]]; then
    echo "error: pom.xml not found" >&2
    return 1
  fi

  # Get full dependency tree
  local raw
  raw=$(mvn dependency:tree 2>/dev/null \
    | grep '^\[INFO\]' \
    | grep -E '(\+\-|\\\-)' \
    | sed 's/^\[INFO\] //')

  [[ -z "$raw" ]] && return 1

  # Parse lines into name, version, scope, depth
  local rows=()
  while IFS= read -r line; do
    # Determine depth — direct deps have no leading | characters before +-
    if echo "$line" | grep -qE '^\+\-|^\\\-'; then
      depth=1
    else
      depth=2
    fi

    # Extract artifact — strip tree chars
    local artifact
    artifact=$(echo "$line" | sed 's/^[|+\\ -]*//' | awk '{print $1}')

    # artifact format: groupId:artifactId:jar:version:scope
    local name version scope
    name=$(echo "$artifact" | awk -F: '{print $1":"$2}')
    version=$(echo "$artifact" | awk -F: '{print $4}')
    scope=$(echo "$artifact" | awk -F: '{print $5}')

    [[ -z "$name" || -z "$version" || -z "$scope" ]] && continue

    rows+=("${depth}|${scope}|${name}|${version}")
  done < <(echo "$raw")

  [[ ${#rows[@]} -eq 0 ]] && return 1

  # Filter by mode
  local filtered=()
  for row in "${rows[@]}"; do
    local scope="${row#*|}"
    scope="${scope%%|*}"
    case "$mode" in
      prod)
        [[ "$scope" != "test" ]] && filtered+=("$row")
        ;;
      dev)
        [[ "$scope" == "test" ]] && filtered+=("$row")
        ;;
      all)
        filtered+=("$row")
        ;;
    esac
  done

  [[ ${#filtered[@]} -eq 0 ]] && return 1

  # Sort and output — drop scope column
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

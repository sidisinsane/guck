#!/usr/bin/env bash
# ---
# description: Detects Gradle dependencies and reports name, version, and depth.
# usage: source _dependency-snapshot-gradle.sh && dependency_snapshot_gradle [--dev|--all]
# requires: gradle or gradlew
# exits:
#   0: success
#   1: gradle not found, not a gradle project, or no dependencies detected
# ---

dependency_snapshot_gradle() {
  local mode="prod"

  for arg in "$@"; do
    case "$arg" in
      --dev) mode="dev" ;;
      --all) mode="all" ;;
    esac
  done

  # Check for gradle or gradlew
  local gradle_cmd
  if [[ -f "./gradlew" ]]; then
    gradle_cmd="./gradlew"
  elif command -v gradle > /dev/null 2>&1; then
    gradle_cmd="gradle"
  else
    echo "error: gradle or gradlew is required but not found" >&2
    return 1
  fi

  # Check for build.gradle or build.gradle.kts
  if [[ ! -f "build.gradle" && ! -f "build.gradle.kts" ]]; then
    echo "error: build.gradle or build.gradle.kts not found" >&2
    return 1
  fi

  # Determine which configurations to parse based on mode
  local configs
  case "$mode" in
    prod) configs="compileClasspath runtimeClasspath" ;;
    dev)  configs="testCompileClasspath testRuntimeClasspath" ;;
    all)  configs="compileClasspath runtimeClasspath testCompileClasspath testRuntimeClasspath" ;;
  esac

  # Get full dependency output
  local raw
  raw=$("$gradle_cmd" dependencies 2>/dev/null)

  [[ -z "$raw" ]] && return 1

  # Parse dependencies from relevant configuration blocks
  declare -A seen
  local rows=()

  for config in $configs; do
    local in_block=0
    while IFS= read -r line; do
      # Detect start of target configuration block
      if echo "$line" | grep -qE "^${config} -"; then
        in_block=1
        continue
      fi

      # Detect end of block — blank line or new configuration header
      if [[ $in_block -eq 1 ]]; then
        if [[ -z "$line" ]] || echo "$line" | grep -qE '^[a-zA-Z]'; then
          in_block=0
          continue
        fi

        # Skip unresolvable and empty lines
        echo "$line" | grep -qE '\(n\)|No dependencies' && continue

        # Determine depth
        local depth=2
        if echo "$line" | grep -qE '^\+---|^\\---'; then
          depth=1
        fi

        # Extract artifact — strip tree chars and conflict markers
        local artifact
        artifact=$(echo "$line" \
          | sed 's/^[|+\\ -]*//' \
          | sed 's/ -> /:/' \
          | sed 's/ (\*)//' \
          | awk '{print $1}')

        # artifact format: group:name:version
        local name version
        name=$(echo "$artifact" | awk -F: '{print $1":"$2}')
        version=$(echo "$artifact" | awk -F: '{print $3}')

        [[ -z "$name" || -z "$version" ]] && continue

        # Deduplicate keeping minimum depth
        if [[ -n "${seen[$name]}" ]]; then
          local existing_depth="${seen[$name]%%|*}"
          [[ $depth -ge $existing_depth ]] && continue
          # Remove existing entry
          local new_rows=()
          for row in "${rows[@]}"; do
            [[ "${row#*|}" != "$name|"* ]] && new_rows+=("$row")
          done
          rows=("${new_rows[@]}")
        fi

        seen["$name"]="${depth}|${version}"
        rows+=("${depth}|${name}|${version}")
      fi
    done < <(echo "$raw")
  done

  [[ ${#rows[@]} -eq 0 ]] && return 1

  # Sort and output
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

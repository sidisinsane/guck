#!/usr/bin/env bash
# ---
# description: Reports file counts and line counts, sorted by relevance.
# usage: guck project stats
# exits:
#   0: success
#   1: not a git repository or no files found
# ---

set -eo pipefail

git rev-parse --is-inside-work-tree > /dev/null 2>&1 || exit 1

# =============================================================================
# Exclusion patterns
# Files matching these patterns are excluded from all output.
# Uses glob-style patterns: * matches any sequence of characters.
# =============================================================================
exclusions=(
  "*.lock"
  "*-lock.json"
)

# =============================================================================
# Manifest registry
# Known project-level files that are high-value regardless of language.
# =============================================================================
declare -A manifests=(
  ["README.md"]=1
  ["README.rst"]=1
  ["pyproject.toml"]=1
  ["requirements.txt"]=1
  ["package.json"]=1
  ["Cargo.toml"]=1
  ["go.mod"]=1
  ["composer.json"]=1
  ["Gemfile"]=1
  ["Makefile"]=1
  [".env.example"]=1
)

# =============================================================================
# Entry point registry
# Maps file extension to known entry point filenames.
# =============================================================================
declare -A entry_points=(
  ["py"]="main.py app.py __main__.py"
  ["js"]="index.js main.js app.js"
  ["ts"]="index.ts main.ts app.ts"
  ["go"]="main.go"
  ["rs"]="main.rs lib.rs"
  ["rb"]="app.rb main.rb"
  ["php"]="index.php app.php"
  ["html"]="index.html"
  ["md"]="README.md"
)

# =============================================================================
# Build exclusion pattern from array
# =============================================================================
exclude_pattern=$(printf '%s\n' "${exclusions[@]}" | sed 's/\./\\./g; s/\*/.*/g; s/$/$/' | paste -sd'|' -)

# =============================================================================
# Step 1 — collect all tracked files with line counts
# =============================================================================
declare -A file_lines
while IFS=$'\t' read -r lines path; do
  file_lines["$path"]="$lines"
done < <(git ls-files | grep -v -E "$exclude_pattern" | xargs wc -l 2>/dev/null | grep -v "^ *[0-9]* total$" | awk '{print $1"\t"$2}')

if [[ ${#file_lines[@]} -eq 0 ]]; then
  exit 1
fi

# =============================================================================
# Step 2 — determine dominant extension via frequency
# =============================================================================
declare -A ext_count
for path in "${!file_lines[@]}"; do
  filename=$(basename "$path")
  ext="${filename##*.}"
  [[ "$ext" == "$filename" ]] && continue  # no extension
  (( ext_count["$ext"]++ )) || true
done

dominant_ext=""
dominant_count=0
for ext in "${!ext_count[@]}"; do
  if [[ "${ext_count[$ext]}" -gt "$dominant_count" ]]; then
    dominant_count="${ext_count[$ext]}"
    dominant_ext="$ext"
  fi
done

# =============================================================================
# Step 3 — build known entry point set for dominant extension
# =============================================================================
declare -A entry_point_set
if [[ -n "$dominant_ext" && -n "${entry_points[$dominant_ext]}" ]]; then
  for ep in ${entry_points[$dominant_ext]}; do
    entry_point_set["$ep"]=1
  done
fi

# =============================================================================
# Step 4 — score and sort files
# Tier 1: manifests
# Tier 2: entry points
# Tier 3: everything else, sorted by depth then line count descending
# =============================================================================
tier1=()
tier2=()
tier3=()

for path in "${!file_lines[@]}"; do
  filename=$(basename "$path")
  depth=$(echo "$path" | tr -cd '/' | wc -c | tr -d ' ')
  lines="${file_lines[$path]}"

  if [[ -n "${manifests[$filename]}" ]]; then
    tier1+=("$path")
  elif [[ -n "${entry_point_set[$filename]}" ]]; then
    tier2+=("$path")
  else
    tier3+=("${depth}|${lines}|${path}")
  fi
done

# Sort tier3 by depth asc, then lines desc
IFS=$'\n' sorted3=($(
  for entry in "${tier3[@]}"; do
    echo "$entry"
  done | sort -t'|' -k1,1n -k2,2rn
)); unset IFS

# =============================================================================
# Output
# =============================================================================
printf 'path\tlines\n'

for path in "${tier1[@]}"; do
  printf '%s\t%s\n' "$path" "${file_lines[$path]}"
done

for path in "${tier2[@]}"; do
  printf '%s\t%s\n' "$path" "${file_lines[$path]}"
done

for entry in "${sorted3[@]}"; do
  path="${entry#*|}"
  path="${path#*|}"
  printf '%s\t%s\n' "$path" "${file_lines[$path]}"
done

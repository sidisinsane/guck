#!/usr/bin/env bash
# ---
# description: >
#   Detects runtimes, language variants, versions, and package managers
#   by probing marker files in CWD and subdirectories.
# usage: source _info-environments.sh && info_environments [dir]
# requires: bash 4+
# populates:
#   detected_environments: array of "runtime|language|version|installed|manager|manager_installed|path" entries
# exits:
#   0: success
#   1: no environments detected
# ---

# =============================================================================
# Runtime markers
# Maps primary marker filename to runtime name.
# To add a new runtime: ["marker_file"]="runtime_name"
# =============================================================================
declare -A runtime_markers=(
  ["go.mod"]="go"
  ["pyproject.toml"]="python"
  ["package.json"]="nodejs"
  ["Cargo.toml"]="rust"
  ["composer.json"]="php"
  ["Gemfile"]="ruby"
)

# =============================================================================
# Language variant detection
# Maps runtime to secondary marker and the language name it implies.
# Only runtimes where language != runtime need an entry.
# Format: ["runtime"]="marker_glob|language_if_found|language_if_not_found"
# =============================================================================
declare -A language_variants=(
  ["nodejs"]="tsconfig*.json|typescript|javascript"
)

# =============================================================================
# Version detection priority per runtime
# Each runtime defines an ordered list of detection strategies.
# Format per strategy: "type:value" where type is one of:
#   file_parse  — parse a file in the project directory
#   binary      — query an installed binary
# Strategies are tried in order; first non-empty result wins.
#
# file_parse values reference internal _parse_* functions below.
# binary values are shell commands evaluated at runtime.
# =============================================================================
declare -A version_strategies=(
  ["go"]="file_parse:go.mod|binary:go version 2>/dev/null | awk '{print \$3}' | sed 's/go//'"
  ["python"]="file_parse:.venv/pyvenv.cfg|file_parse:.python-version|file_parse:pyproject.toml|binary:python3 --version 2>/dev/null | awk '{print \$2}'"
  ["nodejs"]="file_parse:package.json|file_parse:.node-version|binary:node --version 2>/dev/null | sed 's/v//'"
  ["rust"]="file_parse:rust-toolchain.toml|binary:rustc --version 2>/dev/null | awk '{print \$2}'"
  ["php"]="file_parse:composer.json|binary:php --version 2>/dev/null | awk 'NR==1{print \$2}'"
  ["ruby"]="file_parse:.ruby-version|file_parse:Gemfile|binary:ruby --version 2>/dev/null | awk '{print \$2}'"
)

# =============================================================================
# Installed version commands per runtime
# Queries the runtime binary directly — independent of project declarations.
# Used to populate version.installed in the output.
# =============================================================================
declare -A installed_version_cmds=(
  ["go"]="go version 2>/dev/null | awk '{print \$3}' | sed 's/go//'"
  ["python"]="python3 --version 2>/dev/null | awk '{print \$2}'"
  ["nodejs"]="node --version 2>/dev/null | sed 's/v//'"
  ["rust"]="rustc --version 2>/dev/null | awk '{print \$2}'"
  ["php"]="php --version 2>/dev/null | awk 'NR==1{print \$2}'"
  ["ruby"]="ruby --version 2>/dev/null | awk '{print \$2}'"
)

# =============================================================================
# Package manager markers
# Ordered lists of lockfiles per runtime — first match wins.
# Format: ["runtime"]="lockfile:manager|lockfile:manager|..."
# Order reflects precedence when multiple lockfiles could coexist.
# =============================================================================
declare -A package_manager_markers=(
  ["nodejs"]="pnpm-lock.yaml:pnpm|yarn.lock:yarn|package-lock.json:npm"
  ["python"]="uv.lock:uv|poetry.lock:poetry|Pipfile.lock:pipenv|requirements.txt:pip"
  ["rust"]="Cargo.lock:cargo"
  ["go"]="go.sum:gomod"
  ["php"]="composer.lock:composer"
  ["ruby"]="Gemfile.lock:bundler"
)

# =============================================================================
# Installed version commands per package manager
# Queries the manager binary directly.
# =============================================================================
declare -A manager_version_cmds=(
  ["pnpm"]="pnpm --version 2>/dev/null"
  ["yarn"]="yarn --version 2>/dev/null"
  ["npm"]="npm --version 2>/dev/null"
  ["uv"]="uv --version 2>/dev/null | awk '{print \$2}'"
  ["poetry"]="poetry --version 2>/dev/null | awk '{print \$3}' | tr -d ')'"
  ["pipenv"]="pipenv --version 2>/dev/null | awk '{print \$3}'"
  ["pip"]="pip --version 2>/dev/null | awk '{print \$2}'"
  ["cargo"]="cargo --version 2>/dev/null | awk '{print \$2}'"
  ["gomod"]="go version 2>/dev/null | awk '{print \$3}' | sed 's/go//'"
  ["composer"]="composer --version 2>/dev/null | awk '{print \$3}'"
  ["bundler"]="bundler --version 2>/dev/null | awk '{print \$3}'"
)

# =============================================================================
# File parsers
# One function per file type. Each receives the full file path and prints
# a version string (with optional + suffix) or nothing.
# =============================================================================

_parse_go.mod() {
  local ver
  ver=$(grep -E "^go [0-9]" "$1" | awk '{print $2}' | head -1)
  [[ -n "$ver" ]] && echo "${ver}+"
}

_parse_.python-version() {
  local ver
  ver=$(tr -d '[:space:]' < "$1")
  [[ -n "$ver" ]] && echo "$ver"
}

_parse_.venv/pyvenv.cfg() {
  local ver
  ver=$(grep -E "^version\s*=" "$1" | awk -F'=' '{print $2}' | tr -d '[:space:]')
  [[ -n "$ver" ]] && echo "$ver"
}

_parse_pyproject.toml() {
  local ver
  ver=$(grep -E 'requires-python' "$1" | grep -o '[0-9][0-9.]*' | head -1)
  [[ -n "$ver" ]] && echo "${ver}+"
}

_parse_package.json() {
  local ver
  ver=$(grep -A2 '"engines"' "$1" | grep '"node"' | grep -o '[0-9][0-9.]*' | head -1)
  [[ -n "$ver" ]] && echo "${ver}+"
}

_parse_.node-version() {
  local ver
  ver=$(tr -d '[:space:]v' < "$1")
  [[ -n "$ver" ]] && echo "$ver"
}

_parse_rust-toolchain.toml() {
  local ver
  ver=$(grep -E '^channel' "$1" | grep -o '[0-9][0-9.]*\|stable\|beta\|nightly' | head -1)
  [[ -n "$ver" ]] && echo "$ver"
}

_parse_composer.json() {
  local ver
  ver=$(grep -o '"php"[[:space:]]*:[[:space:]]*"[^"]*"' "$1" \
    | grep -o '[0-9][0-9.]*' | head -1)
  [[ -n "$ver" ]] && echo "${ver}+"
}

_parse_.ruby-version() {
  local ver
  ver=$(tr -d '[:space:]' < "$1")
  [[ -n "$ver" ]] && echo "$ver"
}

_parse_Gemfile() {
  local ver
  ver=$(grep -E "^ruby ['\"]" "$1" | grep -o '[0-9][0-9.]*' | head -1)
  [[ -n "$ver" ]] && echo "$ver"
}

# =============================================================================
# Core detection logic
# =============================================================================

_detect_version() {
  local runtime="$1"
  local dir="$2"
  local strategies="${version_strategies[$runtime]}"

  [[ -z "$strategies" ]] && return

  IFS='|' read -ra strategy_list <<< "$strategies"
  for strategy in "${strategy_list[@]}"; do
    local type="${strategy%%:*}"
    local value="${strategy#*:}"

    if [[ "$type" == "file_parse" ]]; then
      local filepath="${dir}/${value}"
      local fn="_parse_${value}"
      if [[ -f "$filepath" ]] && declare -f "$fn" > /dev/null 2>&1; then
        local ver
        ver=$("$fn" "$filepath")
        [[ -n "$ver" ]] && echo "$ver" && return
      fi

    elif [[ "$type" == "binary" ]]; then
      local ver
      ver=$(eval "$value" 2>/dev/null)
      [[ -n "$ver" ]] && echo "$ver" && return
    fi
  done
}

_detect_installed_version() {
  local runtime="$1"
  local cmd="${installed_version_cmds[$runtime]}"

  [[ -z "$cmd" ]] && return

  local ver
  ver=$(eval "$cmd" 2>/dev/null)
  [[ -n "$ver" ]] && echo "$ver"
}

_detect_language() {
  local runtime="$1"
  local dir="$2"
  local variant="${language_variants[$runtime]}"

  if [[ -n "$variant" ]]; then
    local marker="${variant%%|*}"
    local rest="${variant#*|}"
    local lang_found="${rest%%|*}"
    local lang_not_found="${rest#*|}"

    if compgen -G "${dir}/${marker}" > /dev/null 2>&1; then
      echo "$lang_found"
    else
      echo "$lang_not_found"
    fi
    return
  fi

  echo "$runtime"
}

_detect_manager() {
  local runtime="$1"
  local dir="$2"
  local markers="${package_manager_markers[$runtime]}"

  [[ -z "$markers" ]] && return

  IFS='|' read -ra marker_list <<< "$markers"
  for entry in "${marker_list[@]}"; do
    local lockfile="${entry%%:*}"
    local manager="${entry#*:}"
    if [[ -f "${dir}/${lockfile}" ]]; then
      echo "$manager"
      return
    fi
  done
}

_detect_manager_installed() {
  local manager="$1"
  local cmd="${manager_version_cmds[$manager]}"

  [[ -z "$cmd" ]] && return

  local ver
  ver=$(eval "$cmd" 2>/dev/null)
  [[ -n "$ver" ]] && echo "$ver"
}

_probe_dir() {
  local dir="${1:-.}"
  local path
  path=$(realpath --relative-to="$(pwd)" "$dir" 2>/dev/null || echo "$dir")
  [[ "$path" == "." ]] && path="."

  for marker in "${!runtime_markers[@]}"; do
    if [[ -f "${dir}/${marker}" ]]; then
      local runtime="${runtime_markers[$marker]}"
      local language
      language=$(_detect_language "$runtime" "$dir")
      local version
      version=$(_detect_version "$runtime" "$dir")
      local installed
      installed=$(_detect_installed_version "$runtime")
      local manager
      manager=$(_detect_manager "$runtime" "$dir")
      local manager_installed
      manager_installed=$(_detect_manager_installed "$manager")
      detected_environments+=("${runtime}|${language}|${version}|${installed}|${manager}|${manager_installed}|${path}")
    fi
  done
}

info_environments() {
  detected_environments=()
  local base="${1:-.}"

  _probe_dir "$base"

  for dir in "${base}"/*/; do
    [[ -d "$dir" ]] && _probe_dir "$dir"
  done

  if [[ ${#detected_environments[@]} -eq 0 ]]; then
    return 1
  fi

  echo "environments:"
  for entry in "${detected_environments[@]}"; do
    local runtime="${entry%%|*}"
    local rest="${entry#*|}"
    local language="${rest%%|*}"
    rest="${rest#*|}"
    local version="${rest%%|*}"
    rest="${rest#*|}"
    local installed="${rest%%|*}"
    rest="${rest#*|}"
    local manager="${rest%%|*}"
    local manager_installed="${rest#*|}"
    # manager_installed is last field — strip path which is actually last
    local path="${manager_installed#*|}"
    manager_installed="${manager_installed%%|*}"

    echo "  - runtime: ${runtime}"
    [[ "$language" != "$runtime" ]] && echo "    language: ${language}"
    if [[ -n "$version" || -n "$installed" ]]; then
      echo "    version:"
      [[ -n "$version" ]]   && echo "      required: ${version}"
      [[ -n "$installed" ]] && echo "      installed: ${installed}"
    fi
    if [[ -n "$manager" ]]; then
      echo "    manager:"
      echo "      name: ${manager}"
      [[ -n "$manager_installed" ]] && echo "      installed: ${manager_installed}"
    fi
    echo "    path: ${path}"
  done
}
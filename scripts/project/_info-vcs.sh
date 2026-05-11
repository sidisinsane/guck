#!/usr/bin/env bash
# ---
# description: Detects the VCS in use and reports repository state.
# usage: source _info-vcs.sh && info_vcs [dir]
# populates:
#   detected_vcs: associative array of VCS metadata
# exits:
#   0: success
#   1: no VCS detected
# ---

declare -A detected_vcs

info_vcs() {
  detected_vcs=()
  local base="${1:-.}"

  if [[ -d "${base}/.git" ]]; then
    detected_vcs["vcs"]="git"
    detected_vcs["branch"]=$(git -C "$base" rev-parse --abbrev-ref HEAD 2>/dev/null)
    detected_vcs["last_tag"]=$(git -C "$base" describe --tags --abbrev=0 2>/dev/null || echo "")
    detected_vcs["commits_since_tag"]=$(git -C "$base" log "${detected_vcs[last_tag]}..HEAD" \
      --oneline 2>/dev/null | wc -l | tr -d ' ')
    detected_vcs["uncommitted_changes"]=$(git -C "$base" status --porcelain 2>/dev/null | wc -l | tr -d ' ')

  elif [[ -d "${base}/.hg" ]]; then
    detected_vcs["vcs"]="mercurial"

  elif [[ -d "${base}/.svn" ]]; then
    detected_vcs["vcs"]="svn"

  else
    return 1
  fi

  echo "vcs:"
  echo "  type: ${detected_vcs[vcs]}"

  [[ -n "${detected_vcs[branch]}" ]] && \
    echo "  branch: ${detected_vcs[branch]}"

  if [[ -n "${detected_vcs[last_tag]}" ]]; then
    echo "  last_tag: ${detected_vcs[last_tag]}"
    echo "  commits_since_tag: ${detected_vcs[commits_since_tag]}"
  fi

  [[ -n "${detected_vcs[uncommitted_changes]}" ]] && \
    echo "  uncommitted_changes: ${detected_vcs[uncommitted_changes]}"
}

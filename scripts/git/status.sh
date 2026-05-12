#!/usr/bin/env bash
# ---
# description: Reports the current git repository status.
# usage: guck git status
# exits:
#   0: success
#   1: not a git repository
# ---

set -eo pipefail

git rev-parse --is-inside-work-tree > /dev/null 2>&1 || exit 1

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
stash=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
unstaged=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")
if [[ -n "$upstream" ]]; then
  ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null)
  behind=$(git rev-list --count HEAD..@{u} 2>/dev/null)
fi

git_dir=$(git rev-parse --git-dir 2>/dev/null)
merge=false
rebase=false
[[ -f "${git_dir}/MERGE_HEAD" ]] && merge=true
[[ -d "${git_dir}/rebase-merge" || -d "${git_dir}/rebase-apply" ]] && rebase=true

echo "branch: ${branch}"
[[ -n "$ahead" ]]   && echo "ahead: ${ahead}"
[[ -n "$behind" ]]  && echo "behind: ${behind}"
echo "staged: ${staged}"
echo "unstaged: ${unstaged}"
echo "untracked: ${untracked}"
echo "stash: ${stash}"
[[ "$merge" == true ]]  && echo "merge_in_progress: true"
[[ "$rebase" == true ]] && echo "rebase_in_progress: true"

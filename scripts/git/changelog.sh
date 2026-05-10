#!/usr/bin/env bash
# ---
# description: Reports commits since the last tag as a TSV index.
# usage: changelog.sh
# exits:
#   0: success
#   1: not a git repository or no commits found
# ---

set -eo pipefail

git rev-parse --is-inside-work-tree > /dev/null 2>&1 || exit 1

last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [[ -n "$last_tag" ]]; then
  range="${last_tag}..HEAD"
else
  range="HEAD"
fi

count=$(git log "$range" --oneline 2>/dev/null | wc -l | tr -d ' ')
[[ "$count" -eq 0 ]] && exit 1

printf 'hash\tdate\tmessage\n'
git log "$range" --format="%h%x09%as%x09%s" 2>/dev/null \
  | awk -F'\t' 'BEGIN{OFS="\t"} {gsub(/\t/, " ", $3); print $1, $2, $3}'

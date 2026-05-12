#!/usr/bin/env bash
# ---
# description: Bash tab completion for guck.
# usage: source completions/guck.bash
# ---

_guck_complete() {
  local cur words
  cur="${COMP_WORDS[COMP_CWORD]}"
  words=("${COMP_WORDS[@]}")

  local guck_dir="${GUCK_DIR:-$HOME/.guck}"
  local scripts_dir="${guck_dir}/scripts"

  case "${#words[@]}" in
    2)
      # Complete categories
      local categories
      categories=$(ls "${scripts_dir}" 2>/dev/null | tr '\n' ' ')
      COMPREPLY=($(compgen -W "${categories}" -- "${cur}"))
      ;;
    3)
      # Complete endpoints for the given category
      local category="${words[1]}"
      local endpoints
      endpoints=$(ls "${scripts_dir}/${category}" 2>/dev/null \
        | grep -v '^_' \
        | sed 's/\.sh$//' \
        | tr '\n' ' ')
      COMPREPLY=($(compgen -W "${endpoints}" -- "${cur}"))
      ;;
    4)
      # Complete positional values derived from helper filenames
      local category="${words[1]}"
      local endpoint="${words[2]}"
      local values
      values=$(ls "${scripts_dir}/${category}/_${endpoint}-"*.sh 2>/dev/null \
        | sed "s/.*_${endpoint}-//;s/\.sh$//" \
        | tr '\n' ' ')
      COMPREPLY=($(compgen -W "${values}" -- "${cur}"))
      ;;
  esac
}

complete -F _guck_complete guck

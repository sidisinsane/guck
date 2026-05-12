#compdef guck
# ---
# description: Zsh tab completion for guck.
# usage: source completions/guck.zsh
# ---

_guck() {
  local guck_dir="${GUCK_DIR:-$HOME/.guck}"
  local scripts_dir="${guck_dir}/scripts"
  local state

  _arguments \
    '1: :->category' \
    '2: :->endpoint' \
    '3: :->value'

  case "${state}" in
    category)
      local categories
      categories=($(ls "${scripts_dir}" 2>/dev/null))
      _describe 'category' categories
      ;;
    endpoint)
      local category="${words[2]}"
      local endpoints
      endpoints=($(ls "${scripts_dir}/${category}" 2>/dev/null \
        | grep -v '^_' \
        | sed 's/\.sh$//'))
      _describe 'endpoint' endpoints
      ;;
    value)
      local category="${words[2]}"
      local endpoint="${words[3]}"
      local values
      values=($(ls "${scripts_dir}/${category}/_${endpoint}-"*.sh 2>/dev/null \
        | sed "s/.*_${endpoint}-//;s/\.sh$//"))
      _describe 'value' values
      ;;
  esac
}

_guck

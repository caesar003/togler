# Bash completion for togler

_togler_completion() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  # Main options
  opts="-t --toggle -l --list -e --edit -v --version -h --help"

  # If previous word is -t or --toggle, suggest configured apps
  if [[ "$prev" == "-t" ]] || [[ "$prev" == "--toggle" ]]; then
    local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/togler/apps.conf"

    if [ -f "$config_file" ]; then
      # Extract app names from config (first field before |)
      local apps=$(grep -v "^#" "$config_file" | grep -v "^$" | cut -d'|' -f1)
      COMPREPLY=($(compgen -W "$apps" -- "$cur"))
      return 0
    fi
  fi

  # Default completion with options
  COMPREPLY=($(compgen -W "$opts" -- "$cur"))
  return 0
}

# Register completion function
complete -F _togler_completion togler

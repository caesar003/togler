#!/bin/bash

# helper.sh - Helper functions for togler
# This module contains utility functions for logging, prompts, validation, and system checks

# {{{ Logging Functions
# Display messages with consistent formatting
log_info() { echo "ℹ️  $1"; }
log_success() { echo "✅ $1"; }
log_error() { echo "❌ Error: $1"; }
log_warning() { echo "⚠️  Warning: $1"; }
# }}}

# {{{ Input/Validation Functions
# {{{ Prompt functions

# {{{ Required
prompt_required() {
  local prompt="$1"
  local var_name="$2"
  local value

  read -rp "$prompt" value
  if [ -z "$value" ]; then
    log_error "$var_name cannot be empty"
    exit 1
  fi
  echo "$value"
}
# }}}

# {{{ Optional
prompt_optional() {
  local prompt="$1"
  local default="$2"
  local value

  read -rp "$prompt" value
  echo "${value:-$default}"
}
# }}}

# }}} Prompt functions

# {{{ Validation helpers
# Check if command exists
require_command() {
  local cmd="$1"
  local install_hint="$2"

  if ! command -v "$cmd" &>/dev/null; then
    log_error "$cmd is not installed. $install_hint"
    exit 1
  fi
}
# }}}
# }}} Input/Validation Functions

# {{{ System Check Functions
# Check if running in terminal
is_terminal() {
  [ -t 1 ]
}

# Check session type
is_wayland() {
  [ "$XDG_SESSION_TYPE" = "wayland" ]
}
# }}}

# {{{ String Utility Functions
# Clean quotes from gsettings output
clean_quotes() {
  echo "$1" | sed "s/^'//; s/'$//"
}
# }}}

# {{{ Application Mapping Functions
# Application-specific mappings for process names and window classes
get_process_pattern() {
  local app="$1"
  case "$app" in
  "gnome-terminal") echo "gnome-terminal-server" ;;
  "code") echo "code" ;;
  "firefox") echo "firefox" ;;
  *) echo "$app" ;;
  esac
}

get_window_class() {
  local app="$1"
  case "$app" in
  "gnome-terminal") echo "Gnome-terminal" ;;
  "code") echo "Code" ;;
  "firefox") echo "Firefox" ;;
  *) echo "$app" ;;
  esac
}
# }}}

#{{{ Command Validation Functions

#{{{ Check if command exists and is executable
validate_command() {
  local cmd="$1"
  local suggest_install="$2"

  if ! command -v "$cmd" >/dev/null 2>&1; then
    log_error "Command '$cmd' not found or not executable"
    if [ -n "$suggest_install" ]; then
      echo "💡 Try installing it first:"
      case "$cmd" in
      konsole)
        echo "   sudo apt install konsole  # Ubuntu/Debian"
        echo "   sudo dnf install konsole  # Fedora"
        echo "   sudo pacman -S konsole    # Arch"
        ;;
      code)
        echo "   Visit: https://code.visualstudio.com/download"
        ;;
      firefox)
        echo "   sudo apt install firefox  # Ubuntu/Debian"
        echo "   sudo dnf install firefox  # Fedora"
        ;;
      *)
        echo "   Use your package manager to install '$cmd'"
        ;;
      esac
    fi
    return 1
  fi
  return 0
}

#}}}

#{{{ Interactive command valiation with suggestions

validate_command_interactive() {
  local cmd="$1"

  if validate_command "$cmd" "suggest"; then
    return 0
  fi

  echo
  local try_anyway=$(prompt_optional "🤔 Command not found. Create binding anyway? [y/N]: " "N")
  if [[ "$try_anyway" == "y" || "$try_anyway" == "Y" ]]; then
    log_warning "Creating binding for potentially unavailable command '$cmd'"
    return 0
  else
    echo "Operation cancelled."
    exit 1
  fi
}
#}}}
#}}}

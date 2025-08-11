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

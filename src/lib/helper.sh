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
	"slack") echo "Slack" ;;
	*) echo "$app" ;;
	esac
}

get_window_class() {
	local app="$1"
	case "$app" in
	"gnome-terminal") echo "gnome-terminal-server" ;;
	"code") echo "Code" ;;
	"firefox") echo "firefox_firefox" ;;
	"postman") echo "Postman" ;;
	"slack") echo "Slack" ;;
	"chrome") echo "google-chrome" ;;
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

# Extension management functions for togler
# Add these to your helper.sh or create a new extension.sh module

# {{{ Extension Management Functions

#{{{ Check if extension is installed
is_extension_installed() {
	local extension_dir="$HOME/.local/share/gnome-shell/extensions/togler@local"
	[[ -d "$extension_dir" && -f "$extension_dir/extension.js" && -f "$extension_dir/metadata.json" ]]
}
#}}}

#{{{ Install extension
install_extension() {
	local source_dir="$1" # Source directory containing extension files
	local target_dir="$HOME/.local/share/gnome-shell/extensions/togler@local"

	# Create target directory
	mkdir -p "$target_dir"

	# Copy extension files
	if [[ -d "$source_dir" ]]; then
		cp "$source_dir"/* "$target_dir/"
		log_success "Extension installed to $target_dir"
		return 0
	else
		log_error "Extension source directory not found: $source_dir"
		return 1
	fi
}
#}}}

#{{{ Enable extension
enable_extension() {
	local extension_uuid="togler@local"

	# Check if gnome-extensions command is available
	if command -v gnome-extensions >/dev/null 2>&1; then
		gnome-extensions enable "$extension_uuid" >/dev/null 2>&1
		if [[ $? -eq 0 ]]; then
			log_success "Extension enabled"
			return 0
		fi
	fi

	# Fallback: use gsettings directly
	local current_extensions=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null)
	if [[ "$current_extensions" != *"'$extension_uuid'"* ]]; then
		# Add to enabled extensions list
		local new_extensions=$(echo "$current_extensions" | sed "s/]/, '$extension_uuid']/")
		gsettings set org.gnome.shell enabled-extensions "$new_extensions"
		log_success "Extension enabled via gsettings"
	else
		log_info "Extension already enabled"
	fi
}
#}}}

#{{{ Setup extension for wayland
setup_wayland_extension() {
	# Determine extension source path based on installation context
	local extension_source=""

	if [[ -d "/usr/share/togler/extension" ]]; then
		# Installed via package
		extension_source="/usr/share/togler/extension"
	elif [[ -d "$SCRIPT_DIR/extensions" ]]; then
		# Development environment
		extension_source="$SCRIPT_DIR/extensions"
	elif [[ -d "$SCRIPT_DIR/../extensions" ]]; then
		# Alternative development structure
		extension_source="$SCRIPT_DIR/../extensions"
	else
		log_error "Could not locate extension source files"
		return 1
	fi

	# Check if extension is already installed
	if is_extension_installed; then
		log_info "Extension already installed"
		enable_extension
		return 0
	fi

	log_info "Installing GNOME Shell extension for Wayland support..."

	# Install extension
	if install_extension "$extension_source"; then
		enable_extension
		log_warning "Please log out and log back in, or restart GNOME Shell (Alt+F2, 'r', Enter) to activate the extension"
		return 0
	else
		return 1
	fi
}
#}}}

#{{{ Auto-setup extension on first wayland use
ensure_wayland_support() {
	if is_wayland && ! is_extension_installed; then
		echo "🔧 Wayland detected but extension not installed."
		echo "   Setting up GNOME Shell extension for Wayland support..."
		echo

		if setup_wayland_extension; then
			echo
			echo "✨ Extension installed! You may need to restart GNOME Shell."
			echo "   After restart, try running your command again."
			exit 0
		else
			log_error "Failed to set up Wayland extension"
			echo "💡 You can manually copy the extension files from:"
			echo "   $SCRIPT_DIR/extensions/ → ~/.local/share/gnome-shell/extensions/togler@local/"
			exit 1
		fi
	fi
}
#}}}

# }}}

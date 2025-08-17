#!/bin/bash

# helper.sh - Helper functions for togler
# This module contains utility functions for logging, prompts, validation, and system checks

# Display messages with consistent formatting
log_info() { echo "ℹ️  $1"; }
log_success() { echo "✅ $1"; }
log_error() { echo "❌ Error: $1"; }
log_warning() { echo "⚠️  Warning: $1"; }

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

prompt_optional() {
  local prompt="$1"
  local default="$2"
  local value

  read -rp "$prompt" value
  echo "${value:-$default}"
}

require_command() {
  local cmd="$1"
  local install_hint="$2"

  if ! command -v "$cmd" &>/dev/null; then
    log_error "$cmd is not installed. $install_hint"
    exit 1
  fi
}

is_terminal() {
  [ -t 1 ]
}

is_wayland() {
  [ "$XDG_SESSION_TYPE" = "wayland" ]
}

clean_quotes() {
  echo "$1" | sed "s/^'//; s/'$//"
}

get_process_pattern() {
  local app="$1"

  # First, try to detect if the app is currently running
  if pgrep -f "$app" >/dev/null 2>&1; then
    # Get the actual process command/name
    local actual_process=$(pgrep -f "$app" | head -1 | xargs ps -p | tail -1 | awk '{print $4}')
    echo "$actual_process"
    return 0
  fi

  # Fallback: check common variations
  local variations=(
    "$app"
    "${app}-bin"
    "${app}.bin"
    "${app}-server"
    "$(basename "$app")"
  )

  for variant in "${variations[@]}"; do
    if command -v "$variant" >/dev/null 2>&1; then
      echo "$variant"
      return 0
    fi
  done

  # Last resort: use the app name as-is
  echo "$app"
}

get_window_class() {
  local app="$1"

  if is_wayland; then
    # For Wayland, try to get window class from currently running windows
    get_wayland_window_class "$app"
  else
    # For X11, we can query xdotool
    get_x11_window_class "$app"
  fi
}

get_x11_window_class() {
  local app="$1"

  # Try to find existing windows first
  local existing_windows=$(xdotool search --name "$app" 2>/dev/null | head -5)

  for window_id in $existing_windows; do
    local class=$(xdotool getwindowname "$window_id" 2>/dev/null)
    local wm_class=$(xprop -id "$window_id" WM_CLASS 2>/dev/null | cut -d'"' -f4)

    if [[ -n "$wm_class" ]]; then
      echo "$wm_class"
      return 0
    fi
  done

  # Fallback to common patterns
  get_fallback_window_class "$app"
}

get_wayland_window_class() {
  local app="$1"

  # For Wayland, we need to rely on the extension or make educated guesses
  # This could be enhanced to query the extension for current window info

  get_fallback_window_class "$app"
}

get_fallback_window_class() {
  local app="$1"

  # Common transformations
  case "$app" in
  # Keep the known good mappings
  "gnome-terminal") echo "gnome-terminal-server" ;;
  "code") echo "Code" ;;
  "firefox") echo "firefox_firefox" ;;
  "postman") echo "Postman" ;;
  "slack") echo "Slack" ;;
  "chrome") echo "google-chrome" ;;
  *)
    # Try intelligent guessing
    # Capitalize first letter (many apps do this)
    local capitalized="$(tr '[:lower:]' '[:upper:]' <<<${app:0:1})${app:1}"
    echo "$capitalized"
    ;;
  esac
}

get_app_info_from_desktop() {
  local app="$1"
  local desktop_file=""

  # Common desktop file locations
  local desktop_dirs=(
    "/usr/share/applications"
    "/usr/local/share/applications"
    "$HOME/.local/share/applications"
    "/var/lib/flatpak/exports/share/applications"
    "$HOME/.local/share/flatpak/exports/share/applications"
  )

  # Look for desktop file
  for dir in "${desktop_dirs[@]}"; do
    if [[ -f "$dir/$app.desktop" ]]; then
      desktop_file="$dir/$app.desktop"
      break
    fi

    # Also try with common suffixes
    for suffix in "" "-stable" "-dev" "-git"; do
      if [[ -f "$dir/$app$suffix.desktop" ]]; then
        desktop_file="$dir/$app$suffix.desktop"
        break 2
      fi
    done
  done

  if [[ -n "$desktop_file" ]]; then
    # Extract information from desktop file
    local exec_line=$(grep "^Exec=" "$desktop_file" | head -1 | cut -d'=' -f2-)
    local wm_class=$(grep "^StartupWMClass=" "$desktop_file" | head -1 | cut -d'=' -f2-)
    local name=$(grep "^Name=" "$desktop_file" | head -1 | cut -d'=' -f2-)

    # Return structured info
    echo "exec:$exec_line"
    echo "wm_class:$wm_class"
    echo "name:$name"
    echo "desktop_file:$desktop_file"
    return 0
  fi

  return 1
}

discover_app_properties() {
  local app="$1"

  echo "🔍 Discovering properties for '$app'..."

  # Try desktop file first
  if app_info=$(get_app_info_from_desktop "$app"); then
    echo "📄 Found desktop file:"
    echo "$app_info" | while IFS=':' read -r key value; do
      echo "  $key: $value"
    done
  else
    echo "❌ No desktop file found"
  fi

  # Check if running
  if pgrep -f "$app" >/dev/null 2>&1; then
    echo "✅ App is currently running"

    if ! is_wayland; then
      # For X11, show actual window classes
      echo "🪟 Current window classes:"
      xdotool search --name "$app" 2>/dev/null | while read -r window_id; do
        local class=$(xprop -id "$window_id" WM_CLASS 2>/dev/null | cut -d'"' -f4)
        local name=$(xdotool getwindowname "$window_id" 2>/dev/null)
        echo "  Window: $name"
        echo "  Class:  $class"
        echo "  ID:     $window_id"
        echo
      done
    fi
  else
    echo "⚠️  App is not currently running"
    echo "💡 Start the app first for better detection"
  fi
}

validate_and_discover_app() {
  local app="$1"

  # Basic command validation
  if ! command -v "$app" >/dev/null 2>&1; then
    echo "⚠️  Command '$app' not found in PATH"

    # Try to find similar commands
    local suggestions=$(find /usr/bin /usr/local/bin -name "*$app*" 2>/dev/null | head -5)
    if [[ -n "$suggestions" ]]; then
      echo "🔍 Did you mean one of these?"
      echo "$suggestions"
    fi

    # Check desktop files
    if get_app_info_from_desktop "$app" >/dev/null 2>&1; then
      echo "📄 Found desktop file - app might still work"
    fi
  fi

  # Discover properties
  discover_app_properties "$app"
}

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

is_extension_installed() {
  local extension_dir="$HOME/.local/share/gnome-shell/extensions/togler@local"
  [[ -d "$extension_dir" && -f "$extension_dir/extension.js" && -f "$extension_dir/metadata.json" ]]
}

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

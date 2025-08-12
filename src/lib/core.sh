#!/bin/bash

# core.sh - Core business logic for togler
# This module contains the main functionality for toggling windows and managing applications

#{{{ Version and Help Functions
#{{{ Print Version

print_version() {
  echo "togler version $VERSION"
  exit 0
}
# }}}

#{{{ Print Help
print_help() {
  echo "Usage:"
  echo "  togler --version | -v"
  echo "        Show version information"
  echo
  echo "  togler --help | -h"
  echo "        Show this help message"
  echo
  echo "  togler --toggle | -t <app-name>"
  echo "        Toggle visibility of windows for the specified application"
  echo
  echo "  togler --bind | -b [<key>] [<app-name>]"
  echo "        Bind a key combination to toggle the application"
  echo "        Prompts interactively if arguments are not provided"
  echo
  echo "  togler --list | -l"
  echo "        List available bindings"
  echo
  echo "  togler --delete | -d [<app-name>]"
  echo "        Delete current keybinding"
  echo "        Prompts interactively if app-name is not provided"
  echo
  echo "  togler --add | -a [<app-name>] [<shortcut-name>] [<key>]"
  echo "        Create a GNOME shortcut to toggle an application"
  echo "        Prompts interactively for missing arguments"
  echo
  echo "Examples:"
  echo "  togler -t code"
  echo "  togler -b '<Super>c' code"
  echo "  togler -a firefox 'Toggle Firefox' '<Alt>f'"
  exit 0
}
#}}}

#}}}

#{{{ Keybinding Management

# {{{ List available bindings

list_bindings() {
  log_info "Listing all Togler bindings..."
  echo

  local existing=$(get_setting "org.gnome.settings-daemon.plugins.media-keys" "custom-keybindings")

  if [ "$existing" = "@as []" ]; then
    log_info "No custom shortcuts found"
    return 0
  fi

  local found_togler_bindings=0
  local binding_count=0
  local paths=$(echo "$existing" | grep -o "custom[0-9]\+" | sort -V)

  for custom_id in $paths; do
    local path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/$custom_id/"
    local command=$(get_setting "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" "command")

    if [ -z "$command" ] || [ "$command" = "''" ]; then
      continue
    fi

    if [[ "$command" == *"togler --toggle"* ]] || [[ "$command" == *"toggle-"* ]]; then
      found_togler_bindings=1
      binding_count=$((binding_count + 1))

      local name=$(get_setting "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" "name")
      local binding=$(get_setting "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" "binding")

      name=$(clean_quotes "$name")
      command=$(clean_quotes "$command")
      binding=$(clean_quotes "$binding")

      local app_name=""
      if [[ "$command" == *"togler --toggle "* ]]; then
        app_name=$(echo "$command" | sed 's/.*togler --toggle //')
      elif [[ "$command" == *"toggle-"* ]]; then
        app_name=$(echo "$command" | sed 's/toggle-//')
      fi

      echo "🎯 $name"
      echo "   App:     $app_name"
      echo "   Key:     $binding"
      # Add command availability check
      if ! command -v "$app_name" >/dev/null 2>&1; then
        echo "   Status:  ⚠️  Command not found"
      else
        echo "   Status:  ✅ Available"
      fi
      echo
    fi
  done

  if [ $found_togler_bindings -eq 0 ]; then
    log_info "No Togler bindings found"
    echo "💡 Use 'togler --add <app>' to create your first binding"
  else
    echo "📊 Found $binding_count Togler binding(s)"
  fi
}
#}}}

#{{{ Update existing key binding
bind_key() {
  local key_binding="$1"
  local app_name="$2"

  # Interactive prompts using helpers
  if [ -z "$key_binding" ]; then
    key_binding=$(prompt_required "🎹 Enter keybinding (e.g., <Alt>f, <Super>Return): " "Keybinding")
  fi

  if [ -z "$app_name" ]; then
    app_name=$(prompt_required "📱 Enter application name (e.g., firefox, code): " "Application name")
  fi

  local existing=$(get_setting "org.gnome.settings-daemon.plugins.media-keys" "custom-keybindings")

  if [ "$existing" = "@as []" ]; then
    log_error "No existing shortcuts found for '$app_name'"
    echo "💡 Use 'togler --add $app_name' to create a new shortcut first"
    exit 1
  fi

  # Use helper function to find binding
  local found_path
  if found_path=$(find_app_binding "$app_name"); then
    local old_binding=$(get_setting "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$found_path" "binding")

    if set_setting "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$found_path" "binding" "$key_binding"; then
      log_success "Successfully updated keybinding for '$app_name'"
      echo "   Old binding: $(clean_quotes "$old_binding")"
      echo "   New binding: $key_binding"
    else
      log_error "Failed to update keybinding"
      exit 1
    fi
  else
    log_error "No existing shortcut found for '$app_name'"
    echo "💡 Available options:"
    echo "   1. Use 'togler --add $app_name \"Toggle $app_name\" \"$key_binding\"' to create a new shortcut"
    echo "   2. Check existing shortcuts with: gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings"

    local create_new=$(prompt_optional "🤔 Would you like to create a new shortcut instead? [y/N]: " "N")
    if [[ "$create_new" == "y" || "$create_new" == "Y" ]]; then
      add_app "$app_name" "Toggle $app_name" "$key_binding"
    else
      exit 1
    fi
  fi
}
#}}}
# {{{ Delete Existing Binding
delete_binding() {
  local app_name="$1"

  # Prompt for the application name if it wasn't provided as an argument
  if [ -z "$app_name" ]; then
    app_name=$(prompt_required "📱 Enter app name for the binding to delete (e.g., code): " "Application name")
  fi

  log_info "Searching for binding for '$app_name'..."

  # Use the helper function to find the keybinding's path
  local found_path
  if ! found_path=$(find_app_binding "$app_name"); then
    log_error "No binding found for '$app_name'."
    echo "💡 Use 'togler --list' to see all available bindings."
    exit 1
  fi

  # --- Confirmation Prompt Added ---
  local confirm
  confirm=$(prompt_optional "🤔 Are you sure? This binding is too good to be deleted 😉 [y/N]: " "N")

  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log_info "Deletion cancelled. That was a close one!"
    exit 0
  fi
  # --- End of Change ---

  # Get the current list of keybindings
  local current_list
  current_list=$(get_setting "org.gnome.settings-daemon.plugins.media-keys" "custom-keybindings")

  # Rebuild the list, excluding the path we want to remove
  local new_list="["
  local first=true
  # This pipeline extracts just the paths from the gsettings string array format
  local paths=$(echo "$current_list" | grep -oP "'[^']+'" | sed "s/'//g")

  for path in $paths; do
    if [ "$path" != "$found_path" ]; then
      if ! $first; then
        new_list="$new_list, "
      fi
      new_list="$new_list'$path'"
      first=false
    fi
  done
  new_list="$new_list]"

  # GSettings expects a specific format for an empty array
  if [ "$new_list" = "[]" ]; then
    new_list="@as []"
  fi

  # Apply the new, filtered list
  if set_setting "org.gnome.settings-daemon.plugins.media-keys" "custom-keybindings" "$new_list"; then
    # Resetting the old path is good practice for cleanup
    gsettings reset-recursively "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$found_path" &>/dev/null
    log_success "Successfully deleted binding for '$app_name'."
  else
    log_error "Failed to delete the keybinding."
    exit 1
  fi
}
# }}}

# {{{ Add new app
add_app() {
  local app_command="$1"
  local shortcut_name="$2"
  local key_binding="$3"

  # Interactive prompts using helpers
  if [ -z "$app_command" ]; then
    echo "🛠  Add new toggleable app"
    app_command=$(prompt_required "👉 Application command (e.g., code, firefox): " "Application command")
  fi

  # Validate command exists before proceeding
  validate_command_interactive "$app_command"

  if [ -z "$shortcut_name" ]; then
    shortcut_name=$(prompt_optional "📛 Shortcut name (e.g., Toggle Firefox): " "Toggle $app_command")
  fi

  if [ -z "$key_binding" ]; then
    key_binding=$(prompt_required "🎹 Keybinding (e.g., <Alt>f): " "Keybinding")
  fi

  local toggle_command="togler --toggle $app_command"
  local existing=$(get_setting "org.gnome.settings-daemon.plugins.media-keys" "custom-keybindings")
  local new_index=$(find_next_slot)
  local new_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$new_index/"

  # Update custom-keybindings list
  local updated
  if [ "$existing" = "@as []" ]; then
    updated="['$new_path']"
  else
    updated=$(echo "$existing" | sed 's/]$//')
    updated="$updated, '$new_path']"
  fi

  # Apply the keybinding using helper functions
  if set_setting "org.gnome.settings-daemon.plugins.media-keys" "custom-keybindings" "$updated" &&
    set_setting "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_path" "name" "$shortcut_name" &&
    set_setting "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_path" "command" "$toggle_command" &&
    set_setting "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_path" "binding" "$key_binding"; then
    log_success "Successfully added GNOME shortcut for '$shortcut_name' with keybinding $key_binding"
  else
    log_error "Failed to create GNOME keybinding"
    exit 1
  fi
}
# }}}

#}}}

# {{{ Core Toggle Functionality
toggle() {
  if is_terminal; then
    echo "🤔 Looks like you're running this from a terminal."
    echo "💡 For best results, assign 'togler -t $APP_NAME' to a keyboard shortcut instead."
    echo
  fi

  if is_wayland; then
    log_warning "Wayland detected!"

    echo "togler relies on xdotool, which does not work under Wayland."
    echo "For best results, log in using an X11 session instead."
    exit 1

  fi

  require_command "xdotool" "Install it with: sudo apt install -y xdotool"

  # Validate the app command exists before proceeding
  if ! validate_command "$APP_NAME"; then
    echo "💡 You can still create a binding for this app using:"
    echo "   togler --add $APP_NAME"
    exit 1
  fi

  local process_pattern=$(get_process_pattern "$APP_NAME")
  local window_class=$(get_window_class "$APP_NAME")

  if pgrep -f "$process_pattern" >/dev/null; then
    active_win_id=$(xdotool getactivewindow 2>/dev/null)
    app_win_ids=$(xdotool search --onlyvisible --class "$APP_NAME" | sort -n)

    if [ -z "$app_win_ids" ]; then
      "$APP_NAME" &
      exit 0
    fi

    win_array=($app_win_ids)
    num_windows=${#win_array[@]}

    if [ $num_windows -eq 1 ]; then
      win_id=${win_array[0]}
      if [ "$win_id" = "$active_win_id" ]; then
        xdotool windowminimize "$win_id"
      else
        xdotool windowactivate "$win_id"
      fi
      exit 0
    fi

    active_app_window=""
    active_index=-1

    for i in "${!win_array[@]}"; do
      if [ "${win_array[$i]}" = "$active_win_id" ]; then
        active_app_window="${win_array[$i]}"
        active_index=$i
        break
      fi
    done

    mkdir -p /tmp/togler 2>/dev/null || true
    state_file="/tmp/togler/${APP_NAME}_state"

    last_action=""
    if [ -f "$state_file" ]; then
      last_action=$(cat "$state_file" 2>/dev/null)
    fi

    if [ $active_index -eq -1 ]; then
      xdotool windowactivate "${win_array[0]}"
      echo "activated_${win_array[0]}" >"$state_file"
    elif [ $active_index -eq $((num_windows - 1)) ]; then
      xdotool windowminimize "$active_app_window"
      echo "minimized_$active_app_window" >"$state_file"
    else
      if [[ "$last_action" == "minimized_"* ]] && [ $active_index -eq $((num_windows - 2)) ]; then
        xdotool windowactivate "${win_array[0]}"
        echo "activated_${win_array[0]}" >"$state_file"
      else
        next_index=$((active_index + 1))
        xdotool windowactivate "${win_array[$next_index]}"
        echo "activated_${win_array[$next_index]}" >"$state_file"
      fi
    fi
  else
    "$APP_NAME" &
  fi
}

# }}}

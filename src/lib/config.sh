#!/bin/bash

# config.sh - Configuration management for togler
# This module handles GNOME settings, keybinding management, and configuration operations

# {{{ GNOME Settings Functions
# Get gsettings value safely
get_setting() {
	local schema="$1"
	local key="$2"
	gsettings get "$schema" "$key" 2>/dev/null || echo ""
}

set_setting() {
	local schema="$1"
	local key="$2"
	local value="$3"
	gsettings set "$schema" "$key" "$value"
}
# }}}

# {{{ Keybinding Management Functions
# {{{ Find existing app binding
find_app_binding() {
	local app_name="$1"
	local existing=$(get_setting "org.gnome.settings-daemon.plugins.media-keys" "custom-keybindings")

	for i in {0..50}; do
		if ! echo "$existing" | grep -q "custom$i"; then
			continue
		fi

		local path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$i/"
		local command=$(get_setting "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" "command")

		if [[ "$command" == "'toggle-$app_name'" ]] || [[ "$command" == "'togler --toggle $app_name'" ]]; then
			echo "$path"
			return 0
		fi
	done

	return 1
}
# }}}

# {{{ Find next available slot
find_next_slot() {
	local existing=$(get_setting "org.gnome.settings-daemon.plugins.media-keys" "custom-keybindings")
	local new_index=0

	while echo "$existing" | grep -q "custom$new_index"; do
		new_index=$((new_index + 1))
	done

	echo "$new_index"
}
# }}}
# }}}

# {{{ Configuration Constants
# Default schemas for GNOME settings
readonly MEDIA_KEYS_SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
readonly CUSTOM_KEYBINDINGS_KEY="custom-keybindings"
readonly KEYBINDING_PREFIX="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/"
# }}}

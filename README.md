# Togler

A command-line utility for toggling application window visibility on GNOME desktop environments.

## Features

- 🪟 **Toggle windows** - Show/hide application windows with a single command
- 🚀 **Auto-launch** - Automatically launch applications if not running
- 🔄 **Wayland & X11** - Full support for both display servers
- ⚙️ **Configurable** - Easy configuration for custom applications
- 📝 **Bash completion** - Tab completion for configured apps
- 🎯 **Smart behavior** - Minimize focused windows, activate unfocused ones

## Requirements

- GNOME Shell (version 42+)
- GLib D-Bus tools (`glib2.0-bin`)
- Bash

## Installation

### From .deb Package (Recommended)

1. Download or build the package:
   ```bash
   ./build.sh
   ```

2. Install the package:
   ```bash
   sudo apt install ./build/togler_0.0.1_all.deb
   ```

3. Enable the GNOME Shell extension:
   ```bash
   gnome-extensions enable togler@local
   ```

4. Restart your terminal or source bash completion:
   ```bash
   source /etc/bash_completion.d/togler
   ```

### Manual Installation

```bash
sudo make install
gnome-extensions enable togler@local
```

## Usage

### Basic Commands

```bash
# Toggle an application
togler -t chrome

# Toggle with custom launch command
togler -t myapp /path/to/myapp

# List configured applications
togler -l

# Edit configuration
togler -e

# Show help
togler -h

# Show version
togler -v
```

### Configuration

Togler uses a configuration file at `~/.config/togler/apps.conf` to map application names to their WM_CLASS values for both Wayland and X11.

#### Configuration Format

```
app_name|wayland_class|x11_class|launch_command
```

#### Example Configuration

```
chrome|google-chrome|Google-chrome|google-chrome
firefox|firefox_firefox|firefox_firefox|firefox
kitty|kitty|kitty|kitty
terminal|gnome-terminal-server|Gnome-terminal|gnome-terminal
vscode|Code|Code|code
```

#### Adding Custom Applications

1. Edit the configuration:
   ```bash
   togler -e
   ```

2. Add your application in the format shown above

3. Save and exit

#### Finding WM_CLASS Values

**On X11:**
```bash
xprop WM_CLASS
# Click on the window
```

**On Wayland:**
- Open GNOME Looking Glass: `Alt+F2`, type `lg`, press Enter
- Navigate to the "Windows" tab
- Find your window and check the `wm_class` property

## Building from Source

### Build Requirements

- `dpkg-deb`
- `gzip`
- `make`

### Build Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/caesar003/togler.git
   cd togler
   ```

2. Build the package:
   ```bash
   ./build.sh
   ```

3. The `.deb` package will be created in the `build/` directory

### Makefile Targets

```bash
make deb        # Build Debian package
make build      # Prepare build directory
make install    # Install directly to system (requires sudo)
make uninstall  # Uninstall from system (requires sudo)
make clean      # Clean build artifacts
make help       # Show help
```

## How It Works

Togler consists of two components:

1. **Command-line tool** - The `togler` script that users interact with
2. **GNOME Shell extension** - Provides a D-Bus interface for window manipulation

When you run `togler -t <app>`:
1. The script looks up the WM_CLASS for your session type (Wayland/X11)
2. It sends a D-Bus message to the GNOME Shell extension
3. The extension searches for windows with matching WM_CLASS
4. If found and focused → minimize it
5. If found but not focused → activate it
6. If not found → launch the application

## Uninstallation

### Using dpkg
```bash
sudo dpkg -r togler
```

### Using apt
```bash
sudo apt remove togler
```

### Manual uninstall
```bash
sudo make uninstall
```

### Remove user configuration (optional)
```bash
rm -rf ~/.config/togler
```

## Examples

### Toggle Chrome
```bash
togler -t chrome
```

### Toggle Terminal
```bash
togler -t terminal
```

### Toggle Custom App
```bash
togler -t slack
```

### Bind to Keyboard Shortcut

In GNOME Settings → Keyboard → Custom Shortcuts:
- **Command**: `togler -t terminal`
- **Shortcut**: `Super+Enter` (or your preference)

## Troubleshooting

### Extension not loading
```bash
# Check if extension is installed
gnome-extensions list | grep togler

# Enable the extension
gnome-extensions enable togler@local

# Check extension status
gnome-extensions info togler@local
```

### D-Bus errors
```bash
# Verify extension is running
gdbus introspect --session \
  --dest org.gnome.Shell \
  --object-path /org/gnome/Shell/Extensions/Togler
```

### Application not toggling
- Check if the app is in your config: `togler -l`
- Verify the WM_CLASS matches your running application
- Edit config if needed: `togler -e`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source. See LICENSE file for details.

## Author

Caesar - [GitHub](https://github.com/caesar003)

## Links

- **Repository**: https://github.com/caesar003/togler
- **Issues**: https://github.com/caesar003/togler/issues
- **Man Page**: `man togler`r

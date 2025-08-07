# togler

**Togler** (yes, not a typo) is a minimalist command-line tool to toggle the focus and visibility of GUI applications on X11 using `xdotool`.

Designed for speed and simplicity, it’s perfect for creating custom keyboard shortcuts that launch or hide your most-used apps.

---

## ✨ Features

-   Toggle app windows on/off screen with a single command
-   Cycle between multiple windows of the same app
-   Smart minimize if already focused
-   Automatically launch the app if not running
-   Interactive helpers for creating GNOME keybindings
-   Clean CLI interface: `--toggle`, `--add`, `--bind`, `--help`, `--version`
-   Zero config required. Just install and go.
-   Pure Bash. No dependencies besides `xdotool` and `gsettings`

---

## 🚀 Usage

```sh
togler -t firefox          # Toggle Firefox
togler -b "<Alt>f" code    # Bind Alt+F to toggle VS Code
togler -a code             # Add GNOME shortcut for VS Code (interactive)
togler -v                  # Show version
togler -h                  # Show help
```

### Options

| Option                           | Description                                                                 |
| -------------------------------- | --------------------------------------------------------------------------- |
| `-t`, `--toggle <app>`           | Toggle the app’s window(s). Activate, cycle, minimize, or launch as needed  |
| `-b`, `--bind [key] [app]`       | Bind a key to toggle an app. Prompts interactively if arguments are missing |
| `-a`, `--add [app] [name] [key]` | Create GNOME shortcut. Prompts for any missing values interactively         |
| `-v`, `--version`                | Show current version                                                        |
| `-h`, `--help`                   | Show usage instructions                                                     |

> 💡 **Tip:** If you’re running `togler` from a terminal, it’ll remind you to assign it to a keyboard shortcut for smoother use.

---

## 📦 Installation

Download the latest `.deb` from the [Releases](https://github.com/caesar003/togler/releases) page and install:

```sh
sudo dpkg -i togler*.deb
```

Or just copy the `togler` script to your `~/.local/bin` and make it executable.

---

## ⚙️ Requirements

-   X11 session (Wayland is **not** supported)
-   `xdotool` installed:

    ```sh
    sudo apt install xdotool
    ```

---

## 🔧 Post-Install Setup (Recommended)

### 1. Use `--add` to Define Shortcuts

```sh
togler --add firefox "Toggle Firefox" "<Alt>f"
```

Or run `togler --add` alone and follow the prompts.

This will:

-   Create a script in `~/.local/bin/toggle-firefox`
-   Add a GNOME keyboard shortcut bound to your chosen key

### 2. Bind or Rebind Later with `--bind`

Need to change the key later?

```sh
togler --bind "<Super>f" firefox
```

No need to re-add the app manually.

---

## 🧠 How It Works

-   Uses `xdotool` to manage windows by class name
-   Stores temporary toggle state in `/tmp/togler/<app>_state`
-   Launches the app if it's not running
-   Minimizes if focused, activates if not, cycles if multiple windows exist
-   Designed for quick toggling with keyboard bindings

---

## 📚 Examples

```sh
togler -t code                      # Toggle VS Code
togler -a postman "Postman" "<Alt>p"  # Add shortcut for Postman
togler -b "<Super>Return" terminal   # Bind Super+Enter to Terminal
```

---

## 📎 Tip: Keyboard Shortcuts (GNOME)

1. Open **Settings → Keyboard → Keyboard Shortcuts**
2. Scroll to **Custom Shortcuts**
3. Click **+ Add Shortcut**
4. Fill in:

    - **Name:** Toggle Firefox
    - **Command:** `/home/youruser/.local/bin/toggle-firefox`
    - **Shortcut:** `<Alt>f` or similar

Make sure `~/.local/bin` is in your `PATH`.

---

## 🛑 Known Limitations

-   Only works on **X11** (not Wayland)
-   Depends on `xdotool` and GNOME’s `gsettings` for bindings
-   Multiple windows are cycled, not tiled or stacked

---

## 🪪 License

MIT — Free to use, modify, distribute.

---

Made with ❤️ by [Caesar](https://github.com/caesar003)

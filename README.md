# togler

**Togler** (yes, not a typo) is a minimalist command-line tool to toggle the focus and visibility of GUI applications in X11 using `xdotool`.

---

## Features

-   Toggle application windows on/off the screen
-   Smart minimize when app is already focused
-   Clean CLI interface with `--toggle`, `--help`, and `--version`
-   Friendly reminder when invoked from an interactive terminal
-   Simple script, no dependencies beyond `xdotool`

---

## Usage

```sh
togler -t firefox
togler -v
togler -h
```

-   `-t`, `--toggle <app>`: Toggle the application window (focus, minimize, or launch if not running)
-   `-v`, `--version`: Show current version
-   `-h`, `--help`: Show usage instructions

If the window is focused, it gets minimized. If it's not focused, it gets activated. If the app isn't running, it's launched.

> 💡 **Tip:** If you're running this from the terminal, consider assigning it to a keyboard shortcut for smoother workflows.

---

## Installation

Download the latest `.deb` package from the [release page](https://github.com/caesar003/togler/releases) and install:

```sh
sudo dpkg -i togler*.deb
```

---

## Requirements

-   X11 session (does **not** work under Wayland)
-   `xdotool` installed

---

## Post-Install Setup (Recommended)

To get the most out of `togler`, you’ll typically want to:

### 1. Create One-Liner Launcher Scripts

For each application you want to toggle quickly, create a script like:

```bash
#!/bin/bash
# ~/.local/bin/toggle-postman.sh

togler -t postman
```

Make it executable:

```sh
chmod +x ~/.local/bin/toggle-postman.sh
```

Add `~/.local/bin` to your `PATH` if it’s not already there.

---

### 2. Define Keyboard Shortcuts

This is the real power of `togler`: launching or hiding apps with a single keypress.

You can assign keybindings to these one-liner scripts using your desktop environment’s shortcut settings.

#### For GNOME:

1. Open **Settings → Keyboard → Keyboard Shortcuts**
2. Scroll down and click **"Custom Shortcuts"**
3. Add a new shortcut:

    - **Name:** Toggle Postman
    - **Command:** `/home/youruser/.local/bin/toggle-postman.sh`
    - **Shortcut:** `Alt + P`

Refer to your desktop environment’s documentation if you're using KDE, XFCE, i3, etc.

---

## License

MIT — Feel free to copy, modify, distribute.

---

Built with ❤️ by [Caesar](https://github.com/caesar003)

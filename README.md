# togler

**Togler** (yes, not a typo) is a minimalist command-line tool to toggle the focus and visibility of GUI applications in X11 using `xdotool`.

## Features

-   Toggle application windows on/off the screen.
-   Smart minimize when app is already focused.
-   Simple script, no dependencies beyond `xdotool`.

## Usage

```sh
togler firefox
```

If the window is focused, it gets minimized. If it's not focused, it gets activated. If the app isn't running, it's launched.

## Installation

```sh
sudo dpkg -i togler_1.0.0_all.deb
```

## Requirements

-   X11 session (does not work under Wayland)
-   `xdotool` installed

## License

MIT — Feel free to copy, modify, distribute.

---

Built with ❤️ by Caesar.

# omarchy-dots

My [Omarchy](https://omarchy.org) setup on an **M4 Pro MacBook** running Arch Linux ARM (Asahi-style kernel) with Hyprland 0.57 (Lua config) and the Omarchy (Quickshell) shell.

The goal: make a MacBook running Omarchy feel like macOS where it matters — trackpad, scrolling, fonts, click feel.

## What's in here

| Area | Files | Notes |
|---|---|---|
| **Theme** | `THEME` | Built-in **Vantablack** theme, `glassy` bar background |
| **Trackpad / mouse** | `config/hypr/input.lua` | macOS default trackpad pointer curve as a native libinput `custom` profile, macOS scroll-acceleration curve (scaled to 0.45), per-app scroll factors (Chromium/Electron/Firefox/Ghostty), clickfinger, no tap-to-click, external mouse flat at `-0.545`, no middle-click paste |
| **Gestures** | `config/hypr/input.lua` | 3-finger swipe → next/prev workspace, using a custom accumulator so it doesn't get misread as a vertical swipe |
| **Monitors** | `config/hypr/monitors.lua` | External MSI 1080p@144 above the built-in panel (scale 2), `GDK_SCALE=2` |
| **Look & feel** | `config/hypr/looknfeel.lua` | Cursor doesn't warp when switching workspaces |
| **Bar / dock / idle** | `config/omarchy/shell.json` | Bar layout, world clock, dock pins, lock after 5 min |
| **Shell plugins** | `config/omarchy/plugins/` | `blueemi.power` (battery + stats), `blueemi.keyboard-backlight`; installer also clones [omarchy-blackout](https://github.com/Blueemi/omarchy-blackout) and [omausage](https://github.com/Blueemi/omausage) |
| **Fonts** | `config/fontconfig/`, `system/etc/fonts/conf.d/` | SF Mono everywhere monospace, SF Pro for the Omarchy shell UI (fonts themselves not included) |
| **Terminals** | `config/{ghostty,foot,alacritty,kitty}` | SF Mono, 14px padding, CSI-u Shift+Enter |
| **Shell** | `home/.zshrc`, `config/starship.toml` | zsh + autosuggestions, syntax highlighting, history substring search, eza, fzf, starship |
| **Browsers** | `config/*-flags.conf` | Wayland + `WaylandUnscaledTouchpadScrolling` so touchpad scroll is 1:1 |
| **Keyboard** | `system/etc/keyd/default.conf` | Fn → F19 (for push-to-talk) |
| **Click feel** | `system/…/trackpad-light-click*` | Light, quiet haptic click (`hid_magicmouse` haptic strength 25, softness 255) — needs a kernel with the haptics params |
| **Neovim** | `config/nvim/lua/plugins/` | Small tweaks on top of Omarchy's LazyVim |

## Install

```sh
git clone https://github.com/Blueemi/omarchy-dots.git
cd omarchy-dots
./install.sh            # user config only (backs up files it replaces as *.bak.<time>)
./install.sh --system   # + keyd, fontconfig, trackpad haptics service (sudo)
```

Hardware-specific bits you'll probably want to change: `monitors.lua` (my monitor), the `apple-mtp-multi-touch` device block in `input.lua`, and the trackpad haptics service (Apple Silicon only).

# dotfiles

Per-OS folders at the repo root. Each contains GNU Stow packages, so you stow
from *inside* the folder for your machine — not from the repo root.

```
macos/      fastfetch  fish  kitty  nvim  solaar
fedora-44/  fish  kitty  nvim  hypr  quickshell  qt6ct  gtk
```

## Install

```sh
# Fedora 44 / Hyprland
cd ~/dotfiles/fedora-44
stow -t ~ fish kitty nvim hypr quickshell qt6ct gtk

# macOS
cd ~/dotfiles/macos
stow -t ~ fish kitty nvim fastfetch solaar
```

Stow refuses to link over an existing regular file. Remove the conflicting file
first, or use `stow --adopt` (which pulls the existing file into the repo).

## fedora-44 packages

| Package      | Links to                | Notes |
|--------------|-------------------------|-------|
| `fish`       | `~/.config/fish`        | pure prompt vendored in `functions/`. Version managers (pyenv/rbenv/fnm/zoxide/cargo) are all guarded with `command -q` / `test -f`, so a missing tool is never a startup error. |
| `kitty`      | `~/.config/kitty`       | Maple Mono NF, `shell /usr/bin/fish`. |
| `nvim`       | `~/.config/nvim`        | lazy.nvim. mason `ensure_installed` must use **mason** package names (`lua-language-server`), not lspconfig server names. |
| `hypr`       | `~/.config/hypr`        | Hyprland 0.56 **Lua** config (not `hyprland.conf`), plus hyprpaper/hyprlock/hypridle. |
| `quickshell` | `~/.config/quickshell`  | Bar, notification daemon + log, alt-tab switcher. Replaces waybar and mako. |
| `qt6ct`      | `~/.config/qt6ct`       | Only source of a Qt icon theme. Without it `image://icon/<name>` never resolves and tray icons break. Needs `QT_QPA_PLATFORMTHEME=qt6ct` (set in `hyprland.lua`). |
| `gtk`        | `~/.config/gtk-3.0`     | GTK theme/icon names. |

Deliberately **not** tracked: `~/.config/gh` (auth tokens), `~/.config/zen`
(browser profile), and `go`/`dconf`/`pulse` (runtime state).

## Fedora 44 system dependencies

Hyprland and its ecosystem come from the `lionheartp/Hyprland` COPR —
`solopasha/hyprland` has dropped everything but rawhide and has no f44 build.

```sh
sudo dnf copr enable lionheartp/Hyprland
sudo dnf install hyprland xdg-desktop-portal-hyprland hyprlock hypridle \
  hyprpaper hyprpolkitagent quickshell kitty qt6ct qt6-qt5compat \
  fuzzel pipewire pipewire-pulseaudio wireplumber xdg-desktop-portal-gtk \
  grim slurp wl-clipboard xorg-x11-server-Xwayland mesa-dri-drivers \
  mesa-vulkan-drivers adwaita-icon-theme google-noto-sans-fonts \
  google-noto-sans-cjk-vf-fonts google-noto-sans-mono-cjk-vf-fonts \
  fish stow neovim fzf ripgrep fd-find zoxide gh solaar
```

Not packaged, installed by hand:

- **Maple Mono NF** — the *static* NF build from the maple-font releases,
  unpacked to `~/.local/share/fonts/`. The variable build carries **no** Nerd
  Font glyphs, so the bar icons need this one.
- **fnm** — Node version manager (GitHub release → `~/.local/bin`). The system
  `nodejs` RPM is intentionally *not* installed so fnm is the only Node.
- **Zen Browser** — official tarball in `~/.local/share/zen`, user-owned so its
  built-in updater works.
- LSPs/formatters via `npm -g` (under fnm), `go install`, and `cargo install`.

## Gotchas worth remembering

- Hyprland 0.56 configures in **Lua**. `hyprctl dispatch` parses Lua too, so
  legacy strings like `dispatch workspace 1` are a syntax error — use
  `hl.dsp.focus({ workspace = 1 })`. Window selectors need a prefix:
  `"address:0x…"`, not a bare `0x…`.
- The Lua API **silently ignores unknown keys**. A dispatcher returns `ok` for
  arguments it does not understand, and `--verify-config` will not catch it.
- Quickshell models (`Hyprland.workspaces`, `SystemTray.items`,
  `NotificationServer.trackedNotifications`, `DesktopEntries.applications`) are
  **lazy** — they only populate while bound to a view.
- `mode = "preferred"` picks the EDID-preferred mode, which on a high-refresh
  4K panel is usually 60Hz. Set the rate explicitly or use `"highrr"`.

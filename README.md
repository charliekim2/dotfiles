# dotfiles

Per-OS folders at the repo root. Each contains GNU Stow packages, so you stow
from *inside* the folder for your machine — not from the repo root.

```
macos/      fastfetch  fish  kitty  nvim
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
  fish stow neovim fzf ripgrep fd-find zoxide gh solaar \
  adwaita-sans-fonts material-icons-fonts
```

Not packaged, installed by hand:

- **Maple Mono NF** — the *static* NF build from the maple-font releases,
  unpacked to `~/.local/share/fonts/`. The variable build carries **no** Nerd
  Font glyphs. Used by kitty and qt6ct; the quickshell bar no longer needs it
  (it sets Adwaita Sans for text and Material Icons Round for glyphs, both
  from dnf above).
- **fnm** — Node version manager (GitHub release → `~/.local/bin`). The system
  `nodejs` RPM is intentionally *not* installed so fnm is the only Node.
- **Zen Browser** — official tarball in `~/.local/share/zen`, user-owned so its
  built-in updater works.
- LSPs/formatters via `npm -g` (under fnm), `go install`, and `cargo install`.

## Quickshell config layout

`fedora-44/quickshell/.config/quickshell/` is a module tree, not one file.
Stow *folds* the package directory, so `~/.config/quickshell` is a symlink to
this directory and new files go live with no re-stow.

```
shell.qml       entry point; wiring only
Theme.qml       palette + every metric   (singleton)
Icons.qml       Material Icons codepoints (singleton)
components/     Pill, Icon, StyledText, SignalBars
services/       Net, Peripherals, Audio, SysInfo, Notifs, Switcher (singletons)
modules/        bar/, notifications/, switcher/
```

Subdirectories become QML modules automatically and are imported as
`qs.components`, `qs.services`, `qs.modules.bar` and so on — quickshell
synthesises the `qmldir` files, so none are checked in.

## Gotchas worth remembering

- Hyprland 0.56 configures in **Lua**. `hyprctl dispatch` parses Lua too, so
  legacy strings like `dispatch workspace 1` are a syntax error — use
  `hl.dsp.focus({ workspace = 1 })`. Window selectors need a prefix:
  `"address:0x…"`, not a bare `0x…`.
- The Lua API **silently ignores unknown keys**. A dispatcher returns `ok` for
  arguments it does not understand, and `--verify-config` will not catch it.
- Quickshell models (`Hyprland.workspaces`, `SystemTray.items`,
  `NotificationServer.trackedNotifications`, `Networking.devices`,
  `Bluetooth.devices`, `UPower.devices`, `DesktopEntries.applications`) are
  **lazy** — they only populate while bound to a view, and some **nest**: a
  `WifiDevice.networks` needs its own bound view one level deeper or signal
  strength reads 0 forever.
- Quickshell singletons need the **bare** `pragma Singleton`. The
  `//@ pragma Singleton` comment form that several third-party docs show does
  nothing in 0.3.1: the file still resolves as a type, but every property reads
  back `undefined`, which surfaces far from the cause as
  "Unable to assign [undefined]".
- `UPowerDevice.percentage` and `BluetoothDevice.battery` are **0..1
  fractions**, not 0..100. A mouse at 55% arrives as `0.55` and, taken at face
  value, rounds to a permanent "1%" low-battery alarm.
- Quickshell **singletons survive a hot reload** (they are `Reloadable`).
  Editing a singleton's *values* takes effect immediately, but ADDING a
  function to one does not — the live instance keeps its old shape and every
  call fails with "Property 'x' ... is not a function". Restart quickshell,
  don't just save again. Newly installed **fonts** need a restart too: Qt
  builds its font database once at process start.
- A card that can **float** needs an opaque fill. `Theme.tint()` is a
  translucent wash, which is right for a pill on the bar but leaves a toast
  90% see-through over the desktop — the wallpaper reads straight through the
  text. Use `Theme.over()` for anything not sitting on an opaque parent.
- Layer-shell already places a popup **below the bar's exclusive zone**, so a
  popup's top margin is just the gap it wants. Adding the bar height again
  pushes it a full bar-height down the screen.
- wlr-layer-shell reserves **`margin` + `exclusiveZone`** on the anchored edge,
  so a floating bar's `exclusiveZone` is its *height alone*. Including the top
  margin charges it twice and leaves a visibly wider gutter between the bar and
  the tiled windows than between two windows. Check with
  `hyprctl monitors -j | jq '.[0].reserved'` — it should equal margin + height.
- Hyprland's `gaps_in` is **half** the window-to-window gap, and `hyprctl
  clients` reports content geometry, so a border shows up on each side: with
  `gaps_in 5, border_size 2` two windows sit 14px apart by those numbers but
  10px apart visually.
- The packaged **Material Icons is 4.0.0 and lags upstream** — `device_thermostat`
  exists in the GitHub codepoint list but not in the font. Check new codepoints
  against the installed file, not the repo, or they render as tofu.
- Notification icons from `notify-send -i` arrive in `Notification.image`
  (as an `image://icon/...` URL), not in `appIcon`. Handle both.
- `mode = "preferred"` picks the EDID-preferred mode, which on a high-refresh
  4K panel is usually 60Hz. Set the rate explicitly or use `"highrr"`.

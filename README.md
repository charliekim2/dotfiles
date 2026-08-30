# dotfiles

Per-OS folders at the repo root. Each contains GNU Stow packages, so you stow
from *inside* the folder for your machine — not from the repo root.

```
macos/      fastfetch  fish  kitty  nvim
fedora-44/  fish  kitty  nvim  hypr  quickshell  qt6ct  gtk  solaar
```

## Install

```sh
# Fedora 44 / Hyprland
cd ~/dotfiles/fedora-44
stow -t ~ fish kitty nvim hypr quickshell qt6ct gtk solaar

# macOS
cd ~/dotfiles/macos
stow -t ~ fish kitty nvim fastfetch
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
  unpacked to `~/.local/share/fonts/`. Used by kitty and qt6ct.
- **fnm** — Node version manager (GitHub release → `~/.local/bin`). The system
  `nodejs` RPM is intentionally *not* installed so fnm is the only Node.
- LSPs/formatters via `npm -g` (under fnm), `go install`, and `cargo install`.

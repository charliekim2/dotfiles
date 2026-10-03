# dotfiles

Per-OS folders at the repo root. Each contains GNU Stow packages, so you stow
from *inside* the folder for your machine — not from the repo root.

```
macos/      fastfetch  fish  kitty  nvim  claude
fedora-44/  fish  kitty  nvim  hypr  quickshell  qt6ct  gtk  solaar  claude
```

## Install

```sh
# Fedora 44 / Hyprland
cd ~/dotfiles/fedora-44
stow -t ~ fish kitty nvim hypr quickshell qt6ct gtk solaar claude

# macOS
cd ~/dotfiles/macos
stow -t ~ fish kitty nvim fastfetch claude
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
  fish stow neovim fzf ripgrep fd-find zoxide gh jq solaar \
  material-icons-fonts
```

Not packaged, installed by hand:

- **Fonts** — see [Fonts](#fonts).
- **fnm** — Node version manager (GitHub release → `~/.local/bin`). The system
  `nodejs` RPM is intentionally *not* installed so fnm is the only Node.
- LSPs/formatters via `npm -g` (under fnm), `go install`, and `cargo install`.

## Fonts

| Family | Kind | Source | Used by |
| --- | --- | --- | --- |
| Maple Mono NF | mono | maple-font release, *static* NF build | kitty, qt6ct — the only Nerd Font installed, so it owns every terminal glyph |
| Victor Mono | mono | Google Fonts zip | spare coding face; the draw is its cursive italics |
| IBM Plex Mono | mono | Google Fonts zip | spare coding face |
| IBM Plex Sans | sans | Google Fonts zip | quickshell bar candidate |
| IBM Plex Serif | serif | Google Fonts zip | documents |
| SF Pro Display | sans | `sf-pro-display.zip` | quickshell bar candidate |
| Noto Sans (+ CJK) | sans | `google-noto-sans-fonts` (dnf) | GTK UI font, CJK fallback, current quickshell bar font |
| Material Icons Round | icons | `material-icons-fonts` (dnf) | quickshell bar icons — *not* a Nerd Font, so `Icons.qml` addresses glyphs by codepoint |


## Claude accounts (macOS)

`claude` is the work account in `~/.claude`. `claude-personal` (stowed into
`~/.local/bin` by the `claude` package) runs the same binary with
`CLAUDE_CONFIG_DIR=~/.claude-personal`, so the personal account has its own
login, history, projects, memory and `settings.json`. Fish abbreviations:
`ccw` → `claude`, `ccp` → `claude-personal`.

The first run creates `~/.claude-personal`, links in `hooks/`, `statusline.sh`
and `skills/handoff` from this package, seeds a `settings.json` (the work
preferences minus the org-specific bits), and Claude Code asks you to log in.
Nothing else is manual, and none of it is version-controlled apart from the
links. On macOS a non-default config dir gets its own keychain item
(`Claude Code-credentials-<hash of dir>`), so logging in to one account never
signs out the other. Pending handoffs go to `~/.claude-personal/ctx-guard`, so
they don't cross accounts.

## Handoffs

Ask for a handoff (`/handoff`) when a session has gone on long enough that a
fresh one would do better. The skill writes the state of the work down and arms
it, so the next session in that directory continues from it without you pasting
anything. Nothing triggers it automatically. Lives in the `claude` package.

```
claude/.claude/
  hooks/ctx-session-start.sh SessionStart hook — feeds an armed handoff in
  hooks/ctx-arm-handoff.sh   arms a handoff for the next session here
  hooks/ctx-lib.sh           shared helpers
  skills/handoff/SKILL.md    the /handoff skill
```

### The loop

1. **On handoff**, the `handoff` skill writes `.claude/HANDOFF.md` in the
   project and runs `ctx-arm-handoff.sh`, which drops a one-shot pointer at
   `~/.claude/ctx-guard/pending-handoff` recording the directory and document.
2. **Press `/clear`.** `ctx-session-start.sh` fires with `source=clear`, finds
   the pointer, and injects the handoff into the new session with instructions
   to continue from its Next Steps. The pointer is consumed; the document stays
   on disk. Pointers armed in another directory are left alone, and
   `resume`/`compact` never consume one — they still have the old context.

### Enabling it

`settings.json` is deliberately not stowed — it carries machine- and org-local
state. Add the hook to `~/.claude/settings.json` by hand:

```json
"hooks": {
  "SessionStart": [
    { "hooks": [ { "type": "command", "command": "~/.claude/hooks/ctx-session-start.sh", "timeout": 10 } ] }
  ]
}
```

Requires `jq`.

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


## Context guard

Claude Code sessions degrade as the context window fills — retrieval and
instruction-following slip well before the window is actually full. The guard
watches how full the window is and, past a threshold, stops the session at a
turn boundary to offer a handoff to a fresh one. Lives in the `claude` package.

```
claude/.claude/
  hooks/ctx-stop.sh          Stop hook — trips at the threshold
  hooks/ctx-session-start.sh SessionStart hook — feeds an armed handoff in
  hooks/ctx-arm-handoff.sh   arms a handoff for the next session here
  hooks/ctx-lib.sh           shared helpers
  skills/handoff/SKILL.md    the /handoff skill
  statusline.sh              also writes the usage sidecar the hooks read
```

It measures the window, not the model. Asking a degrading model to report its
own degradation puts the alarm inside the thing being monitored; the token
count is outside it and needs no cooperation.

### Where the number comes from

Hooks aren't given context-window data — the status line is. So `statusline.sh`
writes `pct`, `tokens` and `window` to `~/.claude/ctx-guard/usage/<session-id>`
every time it renders, and `ctx-stop.sh` reads that. The write is guarded at
every step: nothing there can cost you the status line.

No status line means no readings, and the guard stays quiet rather than
guessing. Readings older than `CTX_USAGE_MAX_AGE` (1h) are ignored for the same
reason, and a new session deletes its old reading so a stale 90% can't trip
turn one.

### The loop

1. **Every turn**, `ctx-stop.sh` compares usage against `CTX_THRESHOLD` (60%).
   Under it: silence. At or over: the hook blocks the stop *once* and hands
   Claude instructions to leave the tree coherent, then ask — continue, or hand
   off? It fires at most once per session, so it can never become a loop.
2. **On handoff**, the `handoff` skill writes `.claude/HANDOFF.md` in the
   project and runs `ctx-arm-handoff.sh`, which drops a one-shot pointer at
   `~/.claude/ctx-guard/pending-handoff` recording the directory and document.
3. **Press `/clear`.** `ctx-session-start.sh` fires with `source=clear`, finds
   the pointer, and injects the handoff into the new session with instructions
   to continue from its Next Steps. The pointer is consumed; the document stays
   on disk. Pointers armed in another directory are left alone, and
   `resume`/`compact` never consume one — they still have the old context.

`/clear` is the only manual step; no hook can drive the TUI.

### Tuning

| Variable | Default | |
| --- | --- | --- |
| `CTX_THRESHOLD` | `60` | percent of the window at which to offer a handoff |
| `CTX_MAX_TOKENS` | `0` | absolute token cap; `0` disables it |
| `CTX_USAGE_MAX_AGE` | `3600` | seconds before a reading is treated as stale |

Set them in the `env` block of `~/.claude/settings.json` — it applies to every
session and its subprocesses, hooks included — or export them before `claude`
for one session.

`CTX_MAX_TOKENS` is worth setting on a 1M window, where 60% is 600k tokens and
retrieval has degraded long before that. On a 200k window the percentage alone
is fine.

### Enabling it

`settings.json` is deliberately not stowed — it carries machine- and org-local
state. Add the hooks to `~/.claude/settings.json` by hand:

```json
"hooks": {
  "Stop": [
    { "hooks": [ { "type": "command", "command": "~/.claude/hooks/ctx-stop.sh", "timeout": 10, "statusMessage": "Checking context budget..." } ] }
  ],
  "SessionStart": [
    { "hooks": [ { "type": "command", "command": "~/.claude/hooks/ctx-session-start.sh", "timeout": 10 } ] }
  ]
}
```

Requires `jq`, which the hooks and the status line both use.

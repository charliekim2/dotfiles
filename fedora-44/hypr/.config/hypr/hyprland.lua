-- Hyprland config (Lua) — Fedora 44, AMD dGPU, single monitor
-- API reference: /usr/share/hypr/stubs/hl.meta.lua
-- Wiki: https://wiki.hypr.land/Configuring/Start/

------------------
---- MONITORS ----
------------------
-- Acer X32 V2 (DP-3) advertises 4K60 as its EDID-preferred mode, so
-- mode = "preferred" silently caps you at 60Hz. Set the rate explicitly.
hl.monitor({
    output   = "DP-3",
    mode     = "3840x2160@165",
    position = "auto",
    scale    = 1.5,   -- 4K at 1.5x = 2560x1440 logical (exact, no fractional artifacts)
})

-- Fallback for any other/future output
hl.monitor({
    output   = "",
    mode     = "highrr",
    position = "auto",
    scale    = "auto",
})

---------------------
---- MY PROGRAMS ----
---------------------
local terminal    = "kitty"
local menu        = "fuzzel"
local fileManager = "kitty"  -- no GUI file manager installed yet

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    -- Hand the session env to dbus + systemd --user so portals/screensharing work
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE")

    hl.exec_cmd("hyprpaper")
    -- quickshell replaces waybar (config: ~/.config/quickshell/shell.qml)
    hl.exec_cmd("quickshell")
    -- mako removed: notifications are handled by the quickshell config
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
    hl.exec_cmd("hypridle")

    -- Solaar is deliberately NOT started here. It ships
    -- /etc/xdg/autostart/solaar.desktop, which systemd-xdg-autostart-generator
    -- runs as app-solaar@autostart.service -- already with --window=hide. This
    -- session is SDDM + uwsm (wayland-wm@hyprland.desktop.service), so
    -- graphical-session.target is reached and XDG autostart IS honoured; the
    -- old "not honoured from a TTY" note no longer applies.
    --
    -- Starting it here as well gave two instances. The second one registers,
    -- finds the first via GtkApplication's single-instance lock, and its run()
    -- fires activate on the primary -> window.popup(). That is what forced the
    -- window open at every login despite --window=hide being on both.
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
-- Firefox/Chromium and Qt/GTK on Wayland
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
-- qt6ct supplies Qt with an icon theme. Without it Qt searches only hicolor,
-- so tray icons referencing theme names (image://icon/battery-low) fail to
-- resolve even though adwaita-icon-theme is installed.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND", "wayland,x11")

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = true, range = 4, render_power = 3, color = 0xee1a1a1a },
        blur   = { enabled = true, size = 3, passes = 1, vibrancy = 0.1696 },
    },

    animations = { enabled = true },

    dwindle = { preserve_split = true },
    master  = { new_status = "master" },

    misc = {
        force_default_wallpaper = 0,     -- no anime mascot wallpaper
        disable_hyprland_logo   = true,
    },
})

-- Default curves / animations
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

---------------
---- INPUT ----
---------------
hl.config({
    input = {
        kb_layout    = "us",
        -- 2 = pointer focus is DETACHED from keyboard focus:
        --   * scroll/hover events go to the window under the cursor, so you can
        --     scroll docs in a browser while still typing in the terminal
        --     (the macOS/Windows behaviour)
        --   * keyboard focus only moves when you actually click
        -- 0 would keep pointer focus glued to the focused window, which breaks
        -- scrolling over anything else. 1 is plain focus-follows-mouse. 3 also
        -- stops clicks from moving keyboard focus, which is too far.
        follow_mouse = 2,
        sensitivity  = 0,
        touchpad     = { natural_scroll = false },
    },

    -- Keyboard-driven focus changes (alt-tab, SUPER binds) must not drag the
    -- pointer to the newly focused window; the cursor should move only on real
    -- mouse input. This matters more with follow_mouse = 2: a warped cursor
    -- would land on the new window and take pointer focus with it.
    cursor = {
        no_warps = true,
    },
})

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + M", hl.dsp.exit())

-- Screenshots (grim + slurp)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind("Print",                   hl.dsp.exec_cmd("grim - | wl-copy"))

-- Alt-tab is handled by the quickshell switcher overlay (centred icon row).
-- The commit bind uses { release = true } so the highlighted window is
-- activated when ALT is released, like macOS.
-- Release binds on a held modifier do NOT work: at the instant ALT is released
-- it is still logically held, so neither `Alt_L` (modmask 0) nor `ALT + Alt_L`
-- (modmask 8) ever matches, and the commit fell through to a timeout.
-- Poll hl.is_key_down instead — the approach the Omarchy alttab plugin uses.
-- This commits the moment ALT is physically let go, with no delay.
altWatch = hl.timer(function()  -- global on purpose: lets hyprctl eval poke it
    if not (hl.is_key_down("Alt_L") or hl.is_key_down("Alt_R")) then
        altWatch:set_enabled(false)
        hl.dispatch(hl.dsp.global("quickshell:altRelease"))
    end
end, { timeout = 25, type = "repeat" })
altWatch:set_enabled(false)

hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.global("quickshell:altTab"))
    altWatch:set_enabled(true)
end, { repeating = true })

hl.bind("ALT + SHIFT + Tab", function()
    hl.dispatch(hl.dsp.global("quickshell:altTabPrev"))
    altWatch:set_enabled(true)
end, { repeating = true })

-- notification dropdown
hl.bind(mainMod .. " + N",   hl.dsp.exec_cmd("qs ipc call notifs toggle"))

-- Focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspaces
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + ALT + S",   hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mouse drag / resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

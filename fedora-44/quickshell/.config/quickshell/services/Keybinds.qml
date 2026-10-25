//
// Keybinds — the cheat-sheet palette: what is bound, and whether it is open.
//
// The list is CURATED, not read from `hyprctl binds`. That output has no
// titles (every Lua bind reports dispatcher "__lua"), and it lists one row per
// key, so "focus left/right/up/down" would be four rows instead of one. The
// cost is that this file must be kept in step with KEYBINDINGS in
// hyprland.lua by hand.
//
// Each entry:
//   category  section header; entries of one category must be contiguous
//   title     what you read
//   keys      keycaps, joined with "+" in the palette
//   keywords  extra words the search matches (synonyms, the app's name, ...)
//
pragma Singleton

import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: keybinds

    property bool open: false

    readonly property string arrows: "← ↑ → ↓"

    readonly property var binds: [
        // ---- windows
        { category: "Windows", title: "Close window",        keys: ["Super", "C"], keywords: "kill quit exit app" },
        { category: "Windows", title: "Toggle floating",     keys: ["Super", "V"], keywords: "float tile tiling unfloat" },
        { category: "Windows", title: "Fullscreen",          keys: ["Super", "F"], keywords: "maximize maximise monocle" },
        { category: "Windows", title: "Pseudotile",          keys: ["Super", "P"], keywords: "pseudo dwindle keep size" },
        { category: "Windows", title: "Drag window",         keys: ["Super", "Left drag"],  keywords: "mouse move float click" },
        { category: "Windows", title: "Resize with mouse",   keys: ["Super", "Right drag"], keywords: "mouse size click" },

        // ---- focus
        { category: "Focus", title: "Focus in direction",      keys: ["Super", arrows],          keywords: "select switch neighbour neighbor" },
        { category: "Focus", title: "Switch window (alt-tab)", keys: ["Alt", "Tab"],             keywords: "switcher cycle next recent mru" },
        { category: "Focus", title: "Switch window backwards", keys: ["Alt", "Shift", "Tab"],    keywords: "switcher cycle previous reverse mru" },

        // ---- move / swap / resize
        { category: "Move & resize", title: "Move window",   keys: ["Super", "Shift", arrows], keywords: "rearrange relocate re-split layout tree" },
        { category: "Move & resize", title: "Swap windows",  keys: ["Super", "Alt", arrows],   keywords: "exchange trade places switch positions" },
        { category: "Move & resize", title: "Resize window", keys: ["Super", "Ctrl", arrows],  keywords: "grow shrink width height bigger smaller size" },

        // ---- layout
        { category: "Layout", title: "Toggle split direction", keys: ["Super", "J"],          keywords: "dwindle horizontal vertical stacked side by side orientation rotate" },
        { category: "Layout", title: "Swap split halves",      keys: ["Super", "Shift", "J"], keywords: "dwindle mirror flip swapsplit" },

        // ---- workspaces
        { category: "Workspaces", title: "Go to workspace 1–10",         keys: ["Super", "1 … 0"],          keywords: "switch desktop jump number" },
        { category: "Workspaces", title: "Move window to workspace",     keys: ["Super", "Shift", "1 … 0"], keywords: "send desktop throw number" },
        { category: "Workspaces", title: "Next / previous workspace",    keys: ["Super", "Scroll"],         keywords: "cycle mouse wheel desktop" },
        { category: "Workspaces", title: "Toggle scratchpad",            keys: ["Super", "S"],              keywords: "special magic hidden show hide" },
        { category: "Workspaces", title: "Send window to scratchpad",    keys: ["Super", "Alt", "S"],       keywords: "special magic hide move" },

        // ---- apps & shell
        { category: "Apps & shell", title: "Terminal",          keys: ["Super", "Q"], keywords: "kitty shell console open" },
        { category: "Apps & shell", title: "App launcher",      keys: ["Super", "R"], keywords: "fuzzel menu run open program" },
        { category: "Apps & shell", title: "File manager",      keys: ["Super", "E"], keywords: "files browse kitty" },
        { category: "Apps & shell", title: "Notifications",     keys: ["Super", "N"], keywords: "dropdown panel history log" },
        { category: "Apps & shell", title: "Keybind palette",   keys: ["Super", "/"], keywords: "help cheat sheet shortcuts bindings this" },

        // ---- screenshots
        { category: "Screenshots", title: "Screenshot region",      keys: ["Super", "Shift", "S"], keywords: "capture grim slurp select area clipboard copy" },
        { category: "Screenshots", title: "Screenshot full screen", keys: ["Print"],               keywords: "capture grim whole monitor clipboard copy" },

        // ---- system
        { category: "System", title: "Lock screen",    keys: ["Super", "L"],   keywords: "hyprlock away secure" },
        { category: "System", title: "Exit Hyprland",  keys: ["Super", "M"],   keywords: "logout log out quit session" },
        { category: "System", title: "Volume up / down", keys: ["Volume keys"], keywords: "audio sound louder quieter media" },
        { category: "System", title: "Mute speakers",  keys: ["Mute key"],     keywords: "audio sound silence media" },
        { category: "System", title: "Mute microphone", keys: ["Mic mute key"], keywords: "audio mic input media" }
    ]

    // Order of the sections as they first appear, for per-section accents.
    readonly property var categories: {
        const seen = [];
        for (const b of binds)
            if (seen.indexOf(b.category) < 0) seen.push(b.category);
        return seen;
    }

    // Every whitespace-separated term must appear somewhere in the entry
    // (title, keywords, category or keys), so "move work" narrows straight to
    // the workspace binds. Section order is kept rather than ranking by score: the list is short,
    // and stable positions are what make it learnable.
    function filter(query) {
        const terms = query.toLowerCase().split(/\s+/).filter(t => t.length);
        if (!terms.length) return binds;
        return binds.filter(function (b) {
            const hay = (b.title + " " + b.keywords + " " + b.category + " "
                         + b.keys.join(" ")).toLowerCase();
            return terms.every(t => hay.indexOf(t) >= 0);
        });
    }

    function toggle() { keybinds.open = !keybinds.open; }

    // Bound to SUPER+/ in hyprland.lua via hl.dsp.global("quickshell:keybinds").
    GlobalShortcut { appid: "quickshell"; name: "keybinds"; onPressed: keybinds.toggle() }

    //   qs ipc call keybinds toggle
    IpcHandler {
        target: "keybinds"
        function toggle(): void { keybinds.toggle(); }
        function open(): void   { keybinds.open = true; }
        function close(): void  { keybinds.open = false; }
    }
}

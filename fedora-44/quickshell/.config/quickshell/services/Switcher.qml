//
// Switcher — alt-tab state: which windows exist, in what order, and where the
// selection currently sits.
//
pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

Singleton {
    id: switcher

    property bool open: false
    property int  index: 0
    property var  list: []

    // Most-recently-used order, newest first, as Hyprland addresses.
    //
    // Tracked by hand because HyprlandToplevel.lastIpcObject (and its
    // focusHistoryID) is NOT refreshed on focus changes — it goes stale, so
    // sorting by it puts the already-focused window first, which is precisely
    // the one window alt-tab must never land on.
    property var mru: []

    function noteFocus() {
        const active = ToplevelManager.activeToplevel;
        if (!active) return;
        const list = Hyprland.toplevels.values;
        for (var i = 0; i < list.length; i++) {
            if (list[i].wayland === active) {
                const a = list[i].address;
                switcher.mru = [a].concat(switcher.mru.filter(x => x !== a));
                return;
            }
        }
    }

    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() { switcher.noteFocus(); }
    }

    function step(dir) {
        if (!switcher.open) {
            // Hyprland.toplevels, not ToplevelManager: these carry .address,
            // the only reliable way to focus a specific window.
            switcher.list = Hyprland.toplevels.values.slice().sort(function (a, b) {
                var ia = switcher.mru.indexOf(a.address); if (ia < 0) ia = 9999;
                var ib = switcher.mru.indexOf(b.address); if (ib < 0) ib = 9999;
                return ia - ib;
            });
            if (switcher.list.length === 0) return;
            // start on the *next* window, like alt-tab everywhere else
            switcher.index = switcher.list.length > 1
                ? (dir > 0 ? 1 : switcher.list.length - 1)
                : 0;
            switcher.open = true;
        } else {
            const n = switcher.list.length;
            if (n === 0) return;
            switcher.index = (switcher.index + dir + n) % n;
        }
        safety.restart();
    }

    function commit() {
        if (!switcher.open) return;
        const t = switcher.list[switcher.index];
        switcher.open = false;
        safety.stop();
        if (!t) return;
        // Selector strings MUST be prefixed. A bare "0x…" resolves to nothing;
        // "address:0x…" works. HyprlandToplevel.address has no 0x prefix.
        Hyprland.dispatch("hl.dsp.focus({ window = \"address:0x" + t.address + "\" })");
    }

    // Safety net: if the ALT-release bind ever fails to fire, never leave the
    // overlay stuck on screen. Restarted on every step.
    Timer {
        id: safety
        interval: 3000
        repeat: false
        onTriggered: switcher.commit()
    }

    // Hyprland global shortcuts, bound in hyprland.lua via hl.dsp.global().
    // The commit one is bound with { release = true } so the selection lands
    // when ALT is let go — the macOS behaviour.
    GlobalShortcut { appid: "quickshell"; name: "altTab";     onPressed: switcher.step(1) }
    GlobalShortcut { appid: "quickshell"; name: "altTabPrev"; onPressed: switcher.step(-1) }
    GlobalShortcut { appid: "quickshell"; name: "altRelease"; onPressed: switcher.commit() }

    // Keeps Hyprland.toplevels SUBSCRIBED. Without a bound view the lazy model
    // stays empty and the switcher would have nothing to list.
    Item {
        Repeater {
            model: Hyprland.toplevels
            delegate: Item { required property var modelData }
        }
    }
}

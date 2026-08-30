//
// Notifs — the notification server, the toast queue, and the dropdown's state.
//
// Toasts and history are deliberately separate collections. A toast leaving
// the screen must NOT drop the notification from `trackedNotifications`, or
// the log empties itself as you watch it.
//
pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import qs

Singleton {
    id: notifs

    // Popups currently on screen.
    property var toasts: []
    property bool panelOpen: false
    property int  count: 0

    readonly property alias tracked: notifServer.trackedNotifications

    // Arrival wall-clock per notification id. The protocol carries no
    // timestamp, so if we do not stamp it on the way in, "5m ago" is
    // unknowable afterwards.
    property var arrivals: ({})

    NotificationServer {
        id: notifServer
        keepOnReload: false
        imageSupported: true
        actionsSupported: true
        bodyMarkupSupported: true

        onNotification: function (n) {
            notifs.arrivals[n.id] = Date.now();
            n.tracked = true;      // retain in trackedNotifications for the log
            notifs.addToast(n);    // and show a transient popup
        }
    }

    function addToast(n)    { notifs.toasts = notifs.toasts.concat([n]); }
    function removeToast(n) { notifs.toasts = notifs.toasts.filter(t => t !== n); }

    function clearAll() {
        // copy first — dismiss() mutates the model we would be iterating
        const all = notifServer.trackedNotifications.values.slice();
        for (var i = 0; i < all.length; i++) all[i].dismiss();
        notifs.toasts = [];
        notifs.arrivals = ({});
    }

    // ---- relative time -----------------------------------------------------
    // Ticks once a minute. Call sites pass `Notifs.now` as the second argument
    // purely to make the binding depend on it; the value itself is unused.
    // Without that the label would be computed once and then sit there lying.
    SystemClock { id: minuteClock; precision: SystemClock.Minutes }
    readonly property date now: minuteClock.date

    function ago(id, _tick) {
        const t = notifs.arrivals[id];
        if (!t) return "";
        const s = Math.max(0, Math.floor((Date.now() - t) / 1000));
        if (s < 60) return "now";
        const m = Math.floor(s / 60);
        if (m < 60) return m + "m";
        const h = Math.floor(m / 60);
        if (h < 24) return h + "h";
        return Math.floor(h / 24) + "d";
    }

    // ---- colour ------------------------------------------------------------
    // Critical always paints poppy. Everything else takes a stable hue derived
    // from the app name, so Discord is always one colour and the dropdown
    // becomes scannable by colour rather than by reading every heading.
    function accentFor(n) {
        if (!n) return Theme.lilac;
        if (n.urgency === NotificationUrgency.Critical) return Theme.poppy;
        return Theme.accentFor(n.appName && n.appName.length ? n.appName : "?");
    }

    function isCritical(n) {
        return !!n && n.urgency === NotificationUrgency.Critical;
    }

    // Lets the panel be driven from outside the shell:
    //   qs ipc call notifs toggle
    // Bound to SUPER+N in hyprland.lua.
    IpcHandler {
        target: "notifs"
        function toggle(): void { notifs.panelOpen = !notifs.panelOpen; }
        function open(): void   { notifs.panelOpen = true; }
        function close(): void  { notifs.panelOpen = false; }
        function clear(): void  { notifs.clearAll(); }
        function count(): string { return "" + notifs.count; }
    }

    // Keeps trackedNotifications SUBSCRIBED so the badge is live even while the
    // dropdown is shut. Without a bound view the lazy model does not update.
    Item {
        Repeater {
            model: notifServer.trackedNotifications
            delegate: Item {
                required property var modelData
                Component.onCompleted:   notifs.count = notifServer.trackedNotifications.values.length
                Component.onDestruction: notifs.count = notifServer.trackedNotifications.values.length
            }
        }
    }
}

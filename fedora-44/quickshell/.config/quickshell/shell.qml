//
// Quickshell bar + notifications — Hyprland / Fedora 44
//
// Gotchas learned the hard way, do not "simplify" these away:
//  * Quickshell models (Hyprland.workspaces, SystemTray.items,
//    NotificationServer.trackedNotifications) are LAZY. They only populate
//    while bound to a view. Reading .values from a Timer with nothing
//    subscribed gives stale objects (workspaces come back with id = -1).
//  * Tray icons are Adwaita *symbolic* SVGs filled #222222 — invisible on a
//    dark bar. ColorOverlay replaces colour respecting alpha; MultiEffect's
//    colorization multiplies by luminance and leaves black black.
//  * Icon themes need QT_QPA_PLATFORMTHEME=qt6ct, else Qt searches only
//    hicolor and image://icon/<name> never resolves.
//
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

ShellRoot {
    id: root

    // ---- theme ----
    readonly property color bg      : "#1e1e2e"
    readonly property color surface : "#313244"
    readonly property color overlay : "#45475a"
    readonly property color fg      : "#cdd6f4"
    readonly property color muted   : "#6c7086"
    readonly property color accent  : "#33ccff"
    readonly property color urgent  : "#f38ba8"
    readonly property int   barH    : 34
    readonly property string uiFont : "Maple Mono NF"

    // ---- notification state ----
    // Popups currently on screen. Separate from history: a toast leaving the
    // screen must NOT drop the notification from trackedNotifications.
    property var toasts: []

    property bool panelOpen: false

    function addToast(n) {
        root.toasts = root.toasts.concat([n]);
    }
    function removeToast(n) {
        root.toasts = root.toasts.filter(function (t) { return t !== n; });
    }
    function clearAll() {
        // copy first — dismiss() mutates the model we would be iterating
        const all = notifServer.trackedNotifications.values.slice();
        for (var i = 0; i < all.length; i++) all[i].dismiss();
        root.toasts = [];
    }

    NotificationServer {
        id: notifServer
        keepOnReload: false
        imageSupported: true
        actionsSupported: true
        bodyMarkupSupported: true

        onNotification: function (n) {
            n.tracked = true;      // retain in trackedNotifications for the log
            root.addToast(n);      // and show a transient popup
        }
    }

    // Lets the panel be toggled from outside the shell:
    //   qs ipc call notifs toggle
    // Bound to SUPER+N in hyprland.lua.
    IpcHandler {
        target: "notifs"
        function toggle(): void { root.panelOpen = !root.panelOpen; }
        function open(): void { root.panelOpen = true; }
        function close(): void { root.panelOpen = false; }
        function clear(): void { root.clearAll(); }
        function count(): string { return "" + notifCount.count; }
    }

    // ---- alt-tab switcher state ----
    property bool switcherOpen: false
    property int  switcherIndex: 0
    property var  switcherList: []

    // Most-recently-used order, newest first, as a list of Hyprland addresses.
    // We track this ourselves because HyprlandToplevel.lastIpcObject (and its
    // focusHistoryID) is NOT refreshed on focus changes — it goes stale, so
    // sorting by it puts the already-focused window first.
    property var mru: []

    function noteFocus() {
        const active = ToplevelManager.activeToplevel;
        if (!active) return;
        const list = Hyprland.toplevels.values;
        for (var i = 0; i < list.length; i++) {
            if (list[i].wayland === active) {
                const a = list[i].address;
                root.mru = [a].concat(root.mru.filter(function (x) { return x !== a; }));
                return;
            }
        }
    }

    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() { root.noteFocus(); }
    }

    function switcherStep(dir) {
        if (!root.switcherOpen) {
            // Hyprland.toplevels, not ToplevelManager: these carry .address,
            // which is the only reliable way to focus a specific window.
            root.switcherList = Hyprland.toplevels.values.slice().sort(function (a, b) {
                var ia = root.mru.indexOf(a.address); if (ia < 0) ia = 9999;
                var ib = root.mru.indexOf(b.address); if (ib < 0) ib = 9999;
                return ia - ib;
            });
            if (root.switcherList.length === 0) return;
            // start on the *next* window, like alt-tab everywhere else
            root.switcherIndex = root.switcherList.length > 1
                ? (dir > 0 ? 1 : root.switcherList.length - 1)
                : 0;
            root.switcherOpen = true;
        } else {
            const n = root.switcherList.length;
            if (n === 0) return;
            root.switcherIndex = (root.switcherIndex + dir + n) % n;
        }
        switcherSafety.restart();
    }
    function switcherCommit() {
        if (!root.switcherOpen) return;
        const t = root.switcherList[root.switcherIndex];
        root.switcherOpen = false;
        switcherSafety.stop();
        if (!t) return;
        // Selector strings MUST be prefixed. A bare "0x…" resolves to nothing;
        // "address:0x…" works. HyprlandToplevel.address has no 0x prefix.
        Hyprland.dispatch("hl.dsp.focus({ window = \"address:0x" + t.address + "\" })");
    }

    // Safety net: if the ALT-release bind ever fails to fire, never leave the
    // overlay stuck on screen. Restarted on every step.
    Timer {
        id: switcherSafety
        interval: 3000
        repeat: false
        onTriggered: root.switcherCommit()
    }

    // Hyprland global shortcuts. Bound in hyprland.lua via hl.dsp.global().
    // The commit one is bound with { release = true } so the selection lands
    // when ALT is let go — the macOS behaviour.
    GlobalShortcut { appid: "quickshell"; name: "altTab";     onPressed: root.switcherStep(1) }
    GlobalShortcut { appid: "quickshell"; name: "altTabPrev"; onPressed: root.switcherStep(-1) }
    GlobalShortcut { appid: "quickshell"; name: "altRelease"; onPressed: root.switcherCommit() }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    SystemClock { id: clock; precision: SystemClock.Seconds }

    // =====================================================================
    //  BAR
    // =====================================================================
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            implicitHeight: root.barH
            color: root.bg

            // ---------------- LEFT: workspaces ----------------
            RowLayout {
                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                spacing: 6

                Repeater {
                    model: Hyprland.workspaces
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isFocused: modelData.focused

                        implicitWidth: Math.max(26, wsLabel.implicitWidth + 14)
                        implicitHeight: 22
                        radius: 6
                        color: isFocused ? root.accent : root.surface

                        Text {
                            id: wsLabel
                            anchors.centerIn: parent
                            text: modelData.name
                            color: parent.isFocused ? root.bg : root.fg
                            font.family: root.uiFont
                            font.pixelSize: 13
                            font.bold: parent.isFocused
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            // hyprctl dispatch parses LUA in 0.56. The legacy "workspace N"
                            // string is a syntax error: hl.dispatch(workspace 1).
                            onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData.id + " })")
                        }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }
            }

            // ---------------- CENTRE: focused window ----------------
            Text {
                anchors.centerIn: parent
                width: parent.width * 0.4
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: root.muted
                font.family: root.uiFont
                font.pixelSize: 13
                text: ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : ""
            }

            // ---------------- RIGHT: tray | volume | bell | clock ----------------
            RowLayout {
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 14

                // tray
                RowLayout {
                    spacing: 8
                    Repeater {
                        model: SystemTray.items
                        delegate: MouseArea {
                            required property var modelData
                            implicitWidth: 18
                            implicitHeight: 18
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function (mouse) {
                                if (mouse.button === Qt.LeftButton) modelData.activate();
                                else modelData.secondaryActivate();
                            }
                            IconImage {
                                id: trayIcon
                                anchors.fill: parent
                                source: modelData.icon
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: parent
                                source: trayIcon
                                color: root.fg
                            }
                        }
                    }
                }

                // volume — scroll to adjust, click to mute
                MouseArea {
                    readonly property var sink: Pipewire.defaultAudioSink
                    readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
                    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

                    implicitWidth: volRow.implicitWidth
                    implicitHeight: root.barH
                    cursorShape: Qt.PointingHandCursor

                    onClicked: if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
                    onWheel: function (wheel) {
                        if (!sink || !sink.audio) return;
                        const dir = wheel.angleDelta.y > 0 ? 1 : -1;
                        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + dir * 0.02));
                    }

                    RowLayout {
                        id: volRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            // U+F075F volume-off / U+F057E volume-high — present in
                            // Maple Mono NF. NOT U+F6A9, which Maple lacks.
                            text: parent.parent.muted ? "󰝟" : "󰕾"
                            color: parent.parent.muted ? root.muted : root.fg
                            font.family: root.uiFont
                            font.pixelSize: 13
                        }
                        Text {
                            text: Math.round(parent.parent.vol * 100) + "%"
                            color: parent.parent.muted ? root.muted : root.fg
                            font.family: root.uiFont
                            font.pixelSize: 13
                        }
                    }
                }

                // ---- notification bell + unread badge ----
                MouseArea {
                    implicitWidth: bellRow.implicitWidth
                    implicitHeight: root.barH
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.panelOpen = !root.panelOpen

                    RowLayout {
                        id: bellRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            // U+F0F3 bell (Font Awesome set, present in Maple Mono NF)
                            text: ""
                            color: root.panelOpen ? root.accent : root.fg
                            font.family: root.uiFont
                            font.pixelSize: 13
                        }
                        Rectangle {
                            visible: notifCount.count > 0
                            implicitWidth: Math.max(16, badge.implicitWidth + 8)
                            implicitHeight: 16
                            radius: 8
                            color: root.accent
                            Text {
                                id: badge
                                anchors.centerIn: parent
                                text: notifCount.count
                                color: root.bg
                                font.family: root.uiFont
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                    }
                }

                // clock
                Text {
                    color: root.fg
                    font.family: root.uiFont
                    font.pixelSize: 13
                    font.bold: true
                    text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm:ss")
                }
            }

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                color: root.surface
            }
        }
    }

    // Keeps Hyprland.toplevels SUBSCRIBED. Without a bound view the lazy model
    // stays empty and the switcher would have nothing to list.
    Item {
        Repeater {
            model: Hyprland.toplevels
            delegate: Item { required property var modelData }
        }
    }

    // Keeps trackedNotifications SUBSCRIBED so the count is live even while the
    // dropdown is closed. Without a bound view the lazy model does not update.
    Item {
        id: notifCount
        property int count: 0
        Repeater {
            model: notifServer.trackedNotifications
            delegate: Item {
                required property var modelData
                Component.onCompleted: notifCount.count = notifServer.trackedNotifications.values.length
                Component.onDestruction: notifCount.count = notifServer.trackedNotifications.values.length
            }
        }
    }

    // =====================================================================
    //  TOASTS — appear top-right, leave on their own
    // =====================================================================
    PanelWindow {
        anchors { top: true; right: true }
        margins { top: 12; right: 12 }
        implicitWidth: 400
        implicitHeight: Math.max(1, toastCol.implicitHeight)
        color: "transparent"
        exclusiveZone: 0                     // must not reserve screen space
        focusable: false                     // never steal keyboard focus
        visible: root.toasts.length > 0      // no invisible click-blocker when idle
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        ColumnLayout {
            id: toastCol
            anchors { top: parent.top; right: parent.right }
            width: parent.width
            spacing: 8

            Repeater {
                model: root.toasts

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool critical: modelData.urgency === 2

                    Layout.fillWidth: true
                    implicitHeight: toastBody.implicitHeight + 20
                    radius: 10
                    color: root.surface
                    border.width: critical ? 2 : 1
                    border.color: critical ? root.urgent : root.overlay

                    // slide + fade in
                    opacity: 0
                    x: 40
                    Component.onCompleted: { opacity = 1; x = 0; }
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    // Auto-dismiss. Honour the client's expireTimeout when it gives
                    // one; -1 means "server decides".
                    Timer {
                        interval: modelData.expireTimeout > 0
                                  ? modelData.expireTimeout
                                  : (critical ? 8000 : 5000)
                        running: true
                        repeat: false
                        onTriggered: root.removeToast(modelData)
                    }

                    ColumnLayout {
                        id: toastBody
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                                  leftMargin: 14; rightMargin: 14 }
                        spacing: 3

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: modelData.summary
                                color: critical ? root.urgent : root.fg
                                font.family: root.uiFont
                                font.pixelSize: 13
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: modelData.appName
                                color: root.muted
                                font.family: root.uiFont
                                font.pixelSize: 10
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: modelData.body.length > 0
                            text: modelData.body
                            color: root.fg
                            font.family: root.uiFont
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }

                    // click to dismiss early (optional, not required)
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.removeToast(modelData)
                    }
                }
            }
        }
    }

    // Full-screen catcher so a click anywhere else closes the dropdown.
    // Declared before the dropdown window so it stacks underneath it.
    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusiveZone: 0
        focusable: false
        visible: root.panelOpen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            onClicked: root.panelOpen = false
        }
    }

    // =====================================================================
    //  DROPDOWN — the notification log
    // =====================================================================
    PanelWindow {
        anchors { top: true; right: true }
        margins { top: 12; right: 12 }
        implicitWidth: 440
        implicitHeight: 520
        color: "transparent"
        exclusiveZone: 0
        visible: root.panelOpen
        // Grab the keyboard only while open so Escape reaches us, and hand it
        // straight back on close. Clicking the backdrop also dismisses, so
        // there is always a way out if focus misbehaves.
        focusable: root.panelOpen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.panelOpen ? WlrKeyboardFocus.Exclusive
                                                    : WlrKeyboardFocus.None

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.panelOpen = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: root.bg
            border.width: 1
            border.color: root.overlay

            ColumnLayout {
                anchors { fill: parent; margins: 14 }
                spacing: 10

                // header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "Notifications"
                        color: root.fg
                        font.family: root.uiFont
                        font.pixelSize: 15
                        font.bold: true
                    }
                    Rectangle {
                        visible: notifCount.count > 0
                        implicitWidth: clearLabel.implicitWidth + 16
                        implicitHeight: 24
                        radius: 6
                        color: clearMouse.containsMouse ? root.overlay : root.surface
                        Text {
                            id: clearLabel
                            anchors.centerIn: parent
                            text: "Clear all"
                            color: root.fg
                            font.family: root.uiFont
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clearAll()
                        }
                    }
                    Rectangle {
                        implicitWidth: 24; implicitHeight: 24
                        radius: 6
                        color: closeMouse.containsMouse ? root.overlay : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "×"
                            color: root.fg
                            font.family: root.uiFont
                            font.pixelSize: 16
                        }
                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.panelOpen = false
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: root.surface }

                // empty state
                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: notifCount.count === 0
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "No notifications"
                    color: root.muted
                    font.family: root.uiFont
                    font.pixelSize: 12
                }

                // history list
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: notifCount.count > 0
                    clip: true
                    spacing: 8
                    model: notifServer.trackedNotifications

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool critical: modelData.urgency === 2

                        width: ListView.view ? ListView.view.width : 0
                        implicitHeight: itemBody.implicitHeight + 18
                        radius: 8
                        color: root.surface
                        border.width: 1
                        border.color: critical ? root.urgent : root.overlay

                        ColumnLayout {
                            id: itemBody
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                                      leftMargin: 12; rightMargin: 12 }
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.summary
                                    color: critical ? root.urgent : root.fg
                                    font.family: root.uiFont
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: modelData.appName
                                    color: root.muted
                                    font.family: root.uiFont
                                    font.pixelSize: 10
                                }
                                Rectangle {
                                    implicitWidth: 20; implicitHeight: 20
                                    radius: 4
                                    color: itemClose.containsMouse ? root.overlay : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"
                                        color: root.muted
                                        font.family: root.uiFont
                                        font.pixelSize: 13
                                    }
                                    MouseArea {
                                        id: itemClose
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        // dismiss() drops it from trackedNotifications
                                        onClicked: modelData.dismiss()
                                    }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: modelData.body.length > 0
                                text: modelData.body
                                color: root.fg
                                font.family: root.uiFont
                                font.pixelSize: 11
                                wrapMode: Text.WordWrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }

    // =====================================================================
    //  ALT-TAB SWITCHER — centred, icon row, macOS-style
    // =====================================================================
    PanelWindow {
        // no anchors => layer-shell centres the surface
        implicitWidth: Math.max(260, swRow.implicitWidth + 56)
        implicitHeight: 172
        color: "transparent"
        exclusiveZone: 0
        focusable: false
        visible: root.switcherOpen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: Qt.rgba(0.118, 0.118, 0.180, 0.94)
            border.width: 1
            border.color: root.overlay

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                RowLayout {
                    id: swRow
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10

                    Repeater {
                        model: root.switcherList

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool selected: index === root.switcherIndex

                            implicitWidth: 84
                            implicitHeight: 84
                            radius: 14
                            color: selected ? root.surface : "transparent"
                            border.width: selected ? 2 : 0
                            border.color: root.accent

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 56
                                // appId maps to the icon-theme name for most apps;
                                // fall back to a generic binary icon otherwise.
                                source: Quickshell.iconPath(modelData.wayland ? modelData.wayland.appId : "", "application-x-executable")
                            }

                            Behavior on color  { ColorAnimation { duration: 90 } }
                        }
                    }
                }

                // title of the highlighted window
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: swRow.implicitWidth + 20
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: root.fg
                    font.family: root.uiFont
                    font.pixelSize: 13
                    text: {
                        const t = root.switcherList[root.switcherIndex];
                        return t ? t.title : "";
                    }
                }
            }
        }
    }
}

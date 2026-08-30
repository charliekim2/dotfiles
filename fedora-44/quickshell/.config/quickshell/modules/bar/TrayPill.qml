//
// TrayPill — background apps, gathered into one pill instead of loose icons.
//
// Tray icons are Adwaita *symbolic* SVGs filled #222222, which is invisible on
// a dark bar. ColorOverlay replaces the colour while respecting alpha;
// MultiEffect's colorization multiplies by luminance and so leaves black
// black. Do not "modernise" this to MultiEffect.
//
// Icon themes also need QT_QPA_PLATFORMTHEME=qt6ct set, or Qt searches only
// hicolor and image://icon/<name> never resolves at all.
//
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import qs
import qs.components

Pill {
    id: tray

    accent: Theme.clay
    padH: 8
    visible: rep.count > 0

    // The tray's own items handle clicks; a pill-wide MouseArea would swallow
    // them before they ever arrived.
    interactive: false

    Repeater {
        id: rep
        model: SystemTray.items

        delegate: MouseArea {
            id: item
            required property var modelData

            implicitWidth: 16
            implicitHeight: 16
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: m => m.button === Qt.LeftButton
                            ? item.modelData.activate()
                            : item.modelData.secondaryActivate()

            IconImage {
                id: img
                anchors.fill: parent
                source: item.modelData.icon
                visible: false
            }

            ColorOverlay {
                anchors.fill: parent
                source: img
                color: Theme.text
            }
        }
    }
}

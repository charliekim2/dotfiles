//
// SwitcherOverlay — the alt-tab window picker.
//
// Tiles take their hue from position, so the same window sits at the same
// colour for as long as the MRU order holds and you start recognising the
// second-most-recent window as "the blue one" rather than reading its title.
//
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.services

PanelWindow {
    // no anchors => layer-shell centres the surface
    implicitWidth: Math.max(300, swRow.implicitWidth + 56)
    implicitHeight: 190

    color: "transparent"
    exclusiveZone: 0
    focusable: false
    visible: Switcher.open
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: Qt.rgba(Theme.ink.r, Theme.ink.g, Theme.ink.b, 0.96)
        border.width: 1
        border.color: Theme.line

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 14

            RowLayout {
                id: swRow
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Repeater {
                    model: Switcher.list

                    delegate: Rectangle {
                        id: tile
                        required property var modelData
                        required property int index

                        readonly property bool  selected: index === Switcher.index
                        readonly property color accent: Theme.accent(index)

                        implicitWidth: 82
                        implicitHeight: 82
                        radius: 18

                        color: selected ? Theme.tint(accent, 0.26) : Theme.raised
                        border.width: selected ? 2 : 1
                        border.color: selected ? accent : Theme.line

                        scale: selected ? 1.0 : 0.93
                        opacity: selected ? 1.0 : 0.72

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 52
                            // appId maps to the icon-theme name for most apps;
                            // fall back to a generic binary icon otherwise.
                            source: Quickshell.iconPath(
                                tile.modelData.wayland ? tile.modelData.wayland.appId : "",
                                "application-x-executable")
                        }

                        Behavior on color   { ColorAnimation  { duration: 110 } }
                        Behavior on scale   { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 110 } }
                    }
                }
            }

            // Title of the highlighted window, tinted to match its tile.
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: swRow.implicitWidth + 20
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Theme.fsLarge
                color: Theme.accent(Switcher.index)

                // Guard the title itself, not just the handle. A live
                // HyprlandToplevel can read back title === undefined while
                // Hyprland is still syncing toplevel data: seen as a
                // ~25-warning burst right after "no outputs - creating
                // placeholder screen", i.e. when quickshell starts from
                // exec_cmd before the outputs exist. QML refuses to assign
                // undefined to a QString. (A plain DPMS off/on does NOT
                // reproduce it — the output is never removed.)
                text: {
                    const t = Switcher.list[Switcher.index];
                    return (t && t.title) ? t.title : "";
                }
            }
        }
    }
}

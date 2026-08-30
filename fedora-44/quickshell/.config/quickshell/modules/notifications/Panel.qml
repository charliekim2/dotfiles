//
// Panel — the notification log, plus the click-away backdrop behind it.
//
// The two windows live in one file because their LAYER ORDER is the whole
// trick and splitting them invites someone to "tidy" it.
//
// The backdrop MUST be on a lower layer than the dropdown, not merely declared
// first: layer-shell gives no stacking guarantee between two surfaces of the
// same client on the same layer, and both are destroyed and recreated on every
// toggle, so declaration order does not survive. When the backdrop won that
// race it covered the panel and ate every click — the close and Clear all
// buttons simply did nothing. Top < Overlay is ordered by the protocol itself,
// which is the only ordering that actually holds.
//
// The bar's exclusive zone keeps the backdrop below the bar, so the bell stays
// clickable while the panel is open.
//
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.services

Scope {

    // ---------------------------------------------------------- backdrop
    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusiveZone: 0
        focusable: false
        visible: Notifs.panelOpen
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            onClicked: Notifs.panelOpen = false
        }
    }

    // ---------------------------------------------------------- dropdown
    PanelWindow {
        anchors { top: true; right: true }
        margins {
            // Just a gap, NOT the bar's height. Layer-shell already places this
            // surface below the bar's exclusive zone; adding the bar height here
            // too pushed both popups a full bar-height too far down the screen.
            top  : Theme.gapsOut
            right: Theme.barGapSide
        }

        implicitWidth: 420
        implicitHeight: 540

        color: "transparent"
        exclusiveZone: 0
        visible: Notifs.panelOpen

        // Grab the keyboard only while open so Escape reaches us, and hand it
        // straight back on close. The backdrop also dismisses, so there is
        // always a way out if focus misbehaves.
        focusable: Notifs.panelOpen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: Notifs.panelOpen ? WlrKeyboardFocus.Exclusive
                                                      : WlrKeyboardFocus.None

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: Notifs.panelOpen = false
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.panelRadius
            color: Theme.panel
            border.width: 1
            border.color: Theme.line

            ColumnLayout {
                anchors { fill: parent; margins: 14 }
                spacing: 10

                // ---- header ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.pillGap

                    StyledText {
                        Layout.fillWidth: true
                        text: "Notifications"
                        font.pixelSize: Theme.fsLarge
                        font.bold: true
                    }

                    Pill {
                        id: clearPill
                        accent: Theme.clay
                        visible: Notifs.count > 0
                        implicitHeight: 22
                        padH: 9
                        onClicked: Notifs.clearAll()

                        Icon {
                            text: Icons.clearAll
                            color: clearPill.iconColor
                            font.pixelSize: Theme.fsBody
                        }
                        StyledText {
                            text: "Clear all"
                            color: clearPill.labelColor
                            font.pixelSize: Theme.fsSmall
                        }
                    }

                    Pill {
                        id: closePill
                        accent: Theme.subtext
                        implicitWidth: 22
                        implicitHeight: 22
                        padH: 0
                        onClicked: Notifs.panelOpen = false

                        Icon {
                            text: Icons.close
                            color: closePill.iconColor
                            font.pixelSize: Theme.fsBody
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.line
                }

                // ---- empty state ----
                //
                // A plain Item that fills, with the content ANCHORED to its
                // centre. The obvious version — a ColumnLayout with fillWidth,
                // fillHeight and a stretch Item above and below — did not
                // centre on either axis: the column kept its implicit width,
                // so AlignHCenter centred the bell against the label's width
                // rather than the panel's, and the whole thing sat bottom-left.
                // anchors.centerIn has no such argument with the layout.
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: Notifs.count === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Icon {
                            Layout.alignment: Qt.AlignHCenter
                            text: Icons.bellNone
                            color: Theme.tint(Theme.sage, 0.55)
                            font.pixelSize: 34
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Nothing to catch up on"
                            color: Theme.muted
                        }
                    }
                }

                // ---- history ----
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: Notifs.count > 0
                    clip: true
                    spacing: 8
                    model: Notifs.tracked

                    delegate: NotifCard {
                        id: entry
                        required property var modelData

                        notif: modelData
                        width: entry.ListView.view ? entry.ListView.view.width : 0
                        // dismiss() drops it from trackedNotifications
                        onDismissed: entry.modelData.dismiss()
                    }
                }
            }
        }
    }
}

//
// Toasts — transient popups, tucked under the floating bar's right end so they
// line up with the bell they came from.
//
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs
import qs.services

PanelWindow {
    anchors { top: true; right: true }
    margins {
        // Just a gap, NOT the bar's height. Layer-shell already places this
        // surface below the bar's exclusive zone; adding the bar height here
        // too pushed both popups a full bar-height too far down the screen.
        top  : Theme.gapsOut
        right: Theme.barGapSide
    }

    implicitWidth: 400
    implicitHeight: Math.max(1, toastCol.implicitHeight)

    color: "transparent"
    exclusiveZone: 0                          // must not reserve screen space
    focusable: false                          // never steal keyboard focus
    // Not while the dropdown is up: the two are anchored to the same corner, so
    // a toast would sit on top of the log that already lists it — and being on
    // the same layer as the panel, which of them wins is the same undefined
    // stacking race described in Panel.qml. Suppressing them here means the
    // race can never be run.
    visible: Notifs.toasts.length > 0 && !Notifs.panelOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    ColumnLayout {
        id: toastCol
        anchors { top: parent.top; right: parent.right }
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifs.toasts

            delegate: NotifCard {
                id: toast
                required property var modelData

                notif: modelData
                Layout.fillWidth: true
                onDismissed: Notifs.removeToast(toast.modelData)

                // Slide in via a transform rather than by animating x: the
                // ColumnLayout owns x, and animating it directly means the
                // layout and the animation spend the whole 180ms fighting
                // over the same property.
                opacity: 0
                transform: Translate {
                    id: slide
                    x: 40
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }
                Component.onCompleted: { toast.opacity = 1; slide.x = 0; }
                Behavior on opacity { NumberAnimation { duration: 180 } }

                // Auto-dismiss. Honour the client's expireTimeout when it
                // gives one; -1 means "server decides".
                Timer {
                    // Guarded like the card's fields: removing a toast nulls
                    // modelData while this binding is still live.
                    interval: (toast.modelData && toast.modelData.expireTimeout > 0)
                              ? toast.modelData.expireTimeout
                              : (toast.critical ? 8000 : 5000)
                    running: true
                    repeat: false
                    onTriggered: Notifs.removeToast(toast.modelData)
                }
            }
        }
    }
}

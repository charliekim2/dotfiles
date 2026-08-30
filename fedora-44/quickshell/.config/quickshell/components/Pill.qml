//
// Pill — the one shape the whole bar is built from.
//
// A pill is a *wash* of its accent, not a slab of it: `active` is reserved for
// real state (focused workspace, muted sink, open panel) and is the only thing
// that fills it solid. Hover only deepens the wash. Fill everything solid and
// eight saturated lozenges fight each other instead of reading as one palette.
//
// Children given to a Pill land in its internal row, so a call site reads:
//
//     Pill {
//         accent: Theme.sky
//         Icon { text: Icons.wifi; color: parent.parent.iconColor }
//         StyledText { text: "home"; color: ... }
//     }
//
// The internal RowLayout and MouseArea below are NOT swallowed by that default
// alias — the redirect applies to children written at the *use* site, not to
// ones declared here in the defining file. (Verified; it is the kind of thing
// that silently self-parents if you get it wrong.)
//
import QtQuick
import QtQuick.Layouts
import qs

Rectangle {
    id: pill

    default property alias content: row.data

    property color accent: Theme.sage
    property bool  active: false
    property int   padH: Theme.pillPadH

    // Tray sets this false so its own per-item MouseAreas get the clicks: a
    // disabled MouseArea declines events rather than eating them.
    property bool interactive: true

    signal clicked(var mouse)
    signal wheeled(var wheel)

    // Bind child text/icon colours to these so a pill flipping to `active`
    // inverts its contents in one move.
    readonly property color iconColor  : active ? Theme.ink : accent
    readonly property color labelColor : active ? Theme.ink : Theme.text
    readonly property bool  hovered    : mouse.containsMouse

    implicitWidth : row.implicitWidth + padH * 2
    implicitHeight: Theme.pillHeight
    radius: height / 2

    color: active ? accent
                  : Theme.tint(accent, hovered ? Theme.washHover : Theme.washIdle)
    border.width: 1
    border.color: active ? accent : Theme.tint(accent, Theme.edgeAlpha)

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: pill.interactive
        hoverEnabled: pill.interactive
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => pill.clicked(m)
        onWheel: w => pill.wheeled(w)
    }

    Behavior on color        { ColorAnimation { duration: Theme.anim } }
    Behavior on border.color { ColorAnimation { duration: Theme.anim } }
}

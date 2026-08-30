//
// Bar — a floating island: detached from the screen edge on all three sides,
// with everything inside it built out of pills.
//
// The three clusters are anchored independently rather than being three cells
// of one layout. A centred RowLayout would let a long window title shove the
// clock around; anchoring means the middle can grow and shrink without ever
// moving the edges.
//
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtQuick.Layouts
import qs
import qs.components

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors { top: true; left: true; right: true }
    margins {
        top  : Theme.barGapTop
        left : Theme.barGapSide
        right: Theme.barGapSide
    }

    implicitHeight: Theme.barHeight
    color: "transparent"          // let the rounded corners show the wallpaper

    // JUST the bar's height — not the height plus the top gap.
    //
    // wlr-layer-shell reserves `margin + exclusiveZone` on the anchored edge,
    // so the compositor already counts the 10px margin above; adding barGapTop
    // here charges it a second time. That double-count is what made the gutter
    // between the bar and the tiled windows read as roughly double the gutter
    // between two windows. Reserved top is now 10 + 36 = 46, Hyprland adds its
    // own gaps_out below that, and every gap on screen is the same 10px.
    exclusiveZone: Theme.barHeight

    Rectangle {
        anchors.fill: parent
        radius: Theme.barRadius
        color: Theme.bar
        border.width: 1
        border.color: Theme.line

        // ---------------- LEFT ----------------
        Workspaces {
            anchors {
                left: parent.left
                leftMargin: Theme.barPadH
                verticalCenter: parent.verticalCenter
            }
        }

        // ---------------- CENTRE ----------------
        ActiveWindow {
            anchors.centerIn: parent
            maxWidth: Math.max(120, bar.width * 0.32)
        }

        // ---------------- RIGHT ----------------
        RowLayout {
            anchors {
                right: parent.right
                rightMargin: Theme.barPadH
                verticalCenter: parent.verticalCenter
            }
            spacing: Theme.pillGap

            TrayPill    {}
            CpuPill     {}
            RamPill     {}
            TempPill    {}
            BatteryPill {}
            NetworkPill {}
            VolumePill  {}
            NotifPill   {}
            ClockPill   {}
        }
    }
}

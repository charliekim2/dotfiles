//
// Workspaces — one pill each, hue fixed by workspace id.
//
// Colour comes from the id rather than from position in the list, so
// workspace 3 is the same apricot whether or not 1 and 2 currently exist.
// It makes the left end of the bar navigable by colour alone.
//
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs
import qs.components

RowLayout {
    spacing: Theme.pillGap

    Repeater {
        model: Hyprland.workspaces

        delegate: Pill {
            id: ws
            required property var modelData

            accent: Theme.accent(modelData.id - 1)
            active: modelData.focused
            padH: 9      // squarer than a text pill: these are mostly one glyph

            // hyprctl dispatch parses LUA in 0.56. The legacy "workspace N"
            // string is a syntax error: hl.dispatch(workspace 1).
            onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + ws.modelData.id + " })")

            StyledText {
                text: ws.modelData.name
                color: ws.labelColor
                // font.bold: false would force weight back to 400, below the
                // Medium baseline every other label sits at.
                font.weight: ws.active ? Font.Bold : Font.Medium
                font.pixelSize: Theme.fsBody
            }
        }
    }
}

//
// SignalBars — wifi strength as four rising bars, drawn rather than set.
//
// Classic Material Icons has no graded wifi glyph (wifi_1_bar and friends are
// a Material *Symbols* addition), and rather than pull a second icon font in
// for four shapes, they are four rectangles. It also means strength animates
// bar-by-bar instead of snapping between glyphs.
//
// Laid out with explicit x/y instead of a Row: positioners object to children
// that anchor across the axis they manage, and the bars need to sit on a
// common baseline while growing upward.
//
pragma ComponentBehavior: Bound

import QtQuick
import qs

Item {
    id: root

    property int   strength: 0          // 0..100
    property color accent: Theme.sky
    property bool  dim: false           // associated but going nowhere

    readonly property int count: 4
    readonly property int barW : 3
    readonly property int gap  : 2

    // Ceil, with a floor of one bar: a link that is up but faint should still
    // show something, and 1% must not render as "no signal at all".
    readonly property int lit: strength <= 0
                               ? 0
                               : Math.max(1, Math.min(count, Math.ceil(strength / (100 / count))))

    implicitWidth : count * barW + (count - 1) * gap
    implicitHeight: 13

    Repeater {
        model: root.count

        delegate: Rectangle {
            required property int index

            x: index * (root.barW + root.gap)
            y: root.implicitHeight - height
            width: root.barW
            height: 4 + index * 3
            radius: 1.5

            color: index < root.lit
                   ? (root.dim ? Theme.tint(root.accent, 0.55) : root.accent)
                   : Theme.tint(root.accent, 0.28)

            Behavior on color { ColorAnimation { duration: Theme.anim } }
        }
    }
}

// The battery of whatever peripheral is closest to dying. On a desktop that is
// the mouse; on a machine with several it is still the one worth knowing about.
// Hidden entirely when nothing reports a charge, rather than showing "--".
import QtQuick
import qs
import qs.components
import qs.services

Pill {
    id: batt

    readonly property var cell: Peripherals.lowest

    visible: Peripherals.hasBattery
    interactive: false
    accent: cell ? Peripherals.batteryAccent(cell.percent, cell.charging) : Theme.sage

    Icon {
        text: batt.cell ? (batt.cell.charging ? Icons.charging : batt.cell.icon)
                        : Icons.battery
        color: batt.iconColor
    }

    StyledText {
        text: batt.cell ? batt.cell.percent + "%" : ""
        color: batt.labelColor
        // Tabular figures: without them the pill twitches every time the
        // percentage crosses between narrow and wide digits.
        font.features: ({ "tnum": 1, "lnum": 1 })
    }
}

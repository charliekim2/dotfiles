// Date and time. The seconds tick, so the digits are tabular — a proportional
// serif would resize the pill twice a second and shove the whole right-hand
// cluster sideways as it went.
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

Pill {
    id: clockPill

    accent: Theme.butter
    interactive: false

    SystemClock { id: clock; precision: SystemClock.Seconds }

    StyledText {
        text: Qt.formatDateTime(clock.date, "ddd d MMM")
        color: clockPill.active ? Theme.ink : Theme.subtext
        font.features: ({ "tnum": 1, "lnum": 1 })
    }

    Rectangle {
        implicitWidth: 3
        implicitHeight: 3
        radius: 1.5
        color: Theme.tint(clockPill.accent, 0.7)
        Layout.alignment: Qt.AlignVCenter
    }

    StyledText {
        text: Qt.formatDateTime(clock.date, "HH:mm:ss")
        color: clockPill.labelColor
        font.bold: true
        font.features: ({ "tnum": 1, "lnum": 1 })
    }
}

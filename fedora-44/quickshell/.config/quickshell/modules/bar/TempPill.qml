// CPU package temperature. Hidden entirely on a machine where no coretemp /
// k10temp sensor could be found, rather than sitting there reading 0.
import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

Pill {
    id: tempPill

    visible: SysInfo.tempKnown
    accent: SysInfo.pressure(Theme.apricot, SysInfo.temp, 75, 85)
    onClicked: Quickshell.execDetached(["kitty", "--class", "sysmon", "-e",
        "sh", "-c", "command -v btop >/dev/null && exec btop || exec top"])

    Icon {
        text: Icons.temp
        color: tempPill.iconColor
    }

    StyledText {
        text: SysInfo.temp + "°"
        color: tempPill.labelColor
        font.features: ({ "tnum": 1, "lnum": 1 })
    }
}

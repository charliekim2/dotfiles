// Memory pressure, from MemAvailable rather than MemFree — see SysInfo.
import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

Pill {
    id: ramPill

    accent: SysInfo.pressure(Theme.seafoam, SysInfo.mem, 75, 90)
    onClicked: Quickshell.execDetached(["kitty", "--class", "sysmon", "-e",
        "sh", "-c", "command -v btop >/dev/null && exec btop || exec top"])

    Icon {
        text: Icons.ram
        color: ramPill.iconColor
    }

    StyledText {
        text: SysInfo.mem + "%"
        color: ramPill.labelColor
        font.features: ({ "tnum": 1, "lnum": 1 })
    }
}

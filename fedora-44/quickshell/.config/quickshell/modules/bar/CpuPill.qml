// CPU load. Click opens a system monitor — btop if it is installed, top if not,
// resolved at launch so installing btop later needs no config change.
import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

Pill {
    id: cpuPill

    accent: SysInfo.pressure(Theme.lilac, SysInfo.cpu, 70, 90)
    onClicked: Quickshell.execDetached(["kitty", "--class", "sysmon", "-e",
        "sh", "-c", "command -v btop >/dev/null && exec btop || exec top"])

    Icon {
        text: Icons.cpu
        color: cpuPill.iconColor
    }

    StyledText {
        text: SysInfo.cpu + "%"
        color: cpuPill.labelColor
        font.features: ({ "tnum": 1, "lnum": 1 })
    }
}

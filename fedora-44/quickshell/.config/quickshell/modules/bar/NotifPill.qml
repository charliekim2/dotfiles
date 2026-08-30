// The bell, and the unread count. Fills solid while the dropdown is open, so
// the pill reads as the thing the panel is hanging from.
import QtQuick
import qs
import qs.components
import qs.services

Pill {
    id: bell

    accent: Theme.blush
    active: Notifs.panelOpen

    onClicked: Notifs.panelOpen = !Notifs.panelOpen

    Icon {
        text: Notifs.count > 0 ? Icons.bell : Icons.bellNone
        color: bell.iconColor
    }

    StyledText {
        visible: Notifs.count > 0
        text: Notifs.count
        color: bell.labelColor
        font.bold: true
        font.features: ({ "tnum": 1, "lnum": 1 })
    }
}

// Left click opens nmtui, right click toggles the radio.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs
import qs.components
import qs.services

Pill {
    id: netPill

    accent: Net.accent

    onClicked: m => {
        if (m.button === Qt.RightButton) {
            if (Net.hasRadio) Networking.wifiEnabled = !Networking.wifiEnabled;
        } else {
            Quickshell.execDetached(["kitty", "--class", "nmtui", "-e", "nmtui"]);
        }
    }

    // Bars for an associated radio, a glyph for everything else — a wired link
    // has no "strength" to draw.
    SignalBars {
        visible: Net.showBars
        strength: Net.strength
        accent: netPill.iconColor
        dim: !Net.online
        Layout.alignment: Qt.AlignVCenter
    }

    Icon {
        visible: !Net.showBars
        text: Net.icon
        color: netPill.iconColor
    }

    StyledText {
        text: Net.label
        color: netPill.labelColor
        elide: Text.ElideRight
        Layout.maximumWidth: 130
    }

    // Fault marker: the radio is missing entirely while some other link
    // carries traffic, so the label above is describing that other link.
    // Only ever visible when something is genuinely broken.
    Icon {
        visible: Net.faulted
        text: Icons.wifiNone
        color: Theme.poppy
        font.pixelSize: Theme.fsBody
    }
}

// Scroll to adjust, click to mute. Muting drops the pill to grey rather than
// filling it solid: silence is an absence, and should read as one.
import QtQuick
import qs
import qs.components
import qs.services

Pill {
    id: vol

    accent: Audio.muted ? Theme.muted : Theme.lilac

    onClicked: Audio.toggleMute()
    onWheeled: w => Audio.nudge(w.angleDelta.y > 0 ? 1 : -1)

    Icon {
        text: Audio.muted     ? Icons.volMute
            : Audio.volume < 0.34 ? Icons.volDown
                                  : Icons.volUp
        color: vol.iconColor
    }

    StyledText {
        text: Audio.percent + "%"
        color: vol.labelColor
        font.features: ({ "tnum": 1, "lnum": 1 })
    }
}

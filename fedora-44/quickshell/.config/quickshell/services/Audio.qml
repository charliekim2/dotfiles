//
// Audio — the default sink, and the two things the bar does to it.
//
// The PwObjectTracker at the bottom is load-bearing: without something bound
// to the sink, its audio node stays cold and volume/muted never update. It
// lives here rather than in the pill so that one tracker serves every monitor
// instead of one per bar.
//
pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: audio

    readonly property var  sink  : Pipewire.defaultAudioSink
    readonly property bool ready : !!sink && !!sink.audio
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted : ready ? sink.audio.muted : false
    readonly property int  percent: Math.round(volume * 100)

    function toggleMute() {
        if (audio.ready) audio.sink.audio.muted = !audio.sink.audio.muted;
    }

    function nudge(dir) {
        if (!audio.ready) return;
        audio.sink.audio.volume =
            Math.max(0, Math.min(1, audio.sink.audio.volume + dir * 0.02));
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
}

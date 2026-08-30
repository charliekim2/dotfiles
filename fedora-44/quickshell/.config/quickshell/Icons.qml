//
// Icons - Material Icons codepoints, named.
//
// Written as \uXXXX escapes rather than pasted glyphs. The raw characters live
// in the private use area, so in a diff, a grep, or an editor without the font
// loaded they are an indistinguishable row of tofu, and one careless reflow can
// silently swap two of them. An escape is greppable and survives any editor.
//
// Addressed by codepoint rather than by Material's ligature names ("wifi" ->
// glyph) on purpose: Qt shapes those ligatures correctly, but as soon as a
// Text has elide or wrap set, the shaper can break the run mid-ligature and
// spill the literal word into the bar. A codepoint cannot come apart that way.
//
// Every entry below was checked against MaterialIconsRound-Regular.codepoints
// upstream. Only the classic Material Icons set is used: the bar-graded wifi
// glyphs (wifi_1_bar and friends) are a Material *Symbols* addition, absent
// from this font, so signal strength is drawn in QML by SignalBars.qml.
//
pragma Singleton

import Quickshell

Singleton {
    // network
    readonly property string wifi        : "\ue63e"   // wifi
    readonly property string wifiOff     : "\ue648"   // wifi_off
    readonly property string wifiNone    : "\ue1da"   // signal_wifi_off
    readonly property string ethernet    : "\ue8be"   // settings_ethernet
    readonly property string usb         : "\ue1e0"   // usb

    // peripherals
    readonly property string bluetooth   : "\ue1a7"   // bluetooth
    readonly property string btConnected : "\ue1a8"   // bluetooth_connected
    readonly property string btOff       : "\ue1a9"   // bluetooth_disabled
    readonly property string mouse       : "\ue323"   // mouse
    readonly property string keyboard    : "\ue312"   // keyboard
    readonly property string headset     : "\ue310"   // headset
    readonly property string battery     : "\ue1a4"   // battery_full
    readonly property string batteryLow  : "\ue19c"   // battery_alert
    readonly property string charging    : "\ue1a3"   // battery_charging_full

    // audio
    readonly property string volUp       : "\ue050"   // volume_up
    readonly property string volDown     : "\ue04d"   // volume_down
    readonly property string volMute     : "\ue04f"   // volume_off

    // notifications
    readonly property string bell        : "\ue7f4"   // notifications
    readonly property string bellNone    : "\ue7f5"   // notifications_none
    readonly property string bellOff     : "\ue7f6"   // notifications_off

    // system usage
    // NB: device_thermostat (e1ff) is NOT in the packaged Material Icons 4.0.0
    // even though it exists upstream, so `thermostat` is used instead. Check
    // new codepoints against the INSTALLED font, not the GitHub codepoint list.
    readonly property string cpu         : "\ue30d"   // developer_board
    readonly property string ram         : "\ue322"   // memory
    readonly property string temp        : "\uf076"   // thermostat

    // chrome
    readonly property string close       : "\ue5cd"   // close
    readonly property string clearAll    : "\ue0b8"   // clear_all
    readonly property string apps        : "\ue5c3"   // apps
}

//
// Peripherals — bluetooth radio state, and the batteries of things that are
// not the computer (mouse, keyboard, headset).
//
// This is a desktop: there is no laptop battery, and UPower's `powerSupply`
// flag is exactly the line that separates "the machine's own power" from "a
// gadget that reports charge". Everything here is on the gadget side of it, so
// a laptop battery would deliberately NOT appear in this pill.
//
// `Bluetooth.devices` and `UPower.devices` are lazy models like everything
// else in Quickshell — the hidden Repeaters at the bottom hold them open.
//
pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import qs

Singleton {
    id: periph

    // ------------------------------------------------------------ bluetooth
    readonly property var  adapter   : Bluetooth.defaultAdapter
    readonly property bool btPresent : adapter !== null
    readonly property bool btEnabled : btPresent && adapter.enabled

    property var connected: []                       // BluetoothDevice[]
    readonly property int btCount: connected.length

    function syncBt() {
        const all = Bluetooth.devices ? Bluetooth.devices.values : [];
        const out = [];
        for (var i = 0; i < all.length; i++)
            if (all[i].connected) out.push(all[i]);
        periph.connected = out;
    }

    // One device is worth naming; past that a count is more useful than a
    // truncated list.
    readonly property string btLabel: {
        if (!btPresent)     return "no bt";
        if (!btEnabled)     return "off";
        if (btCount === 0)  return "on";
        if (btCount === 1)  return connected[0].deviceName || connected[0].name || "1 paired";
        return btCount + " paired";
    }

    readonly property string btIcon: (!btPresent || !btEnabled) ? Icons.btOff
                                   : btCount > 0 ? Icons.btConnected
                                                 : Icons.bluetooth

    readonly property color btAccent: !btPresent ? Theme.muted
                                    : btEnabled  ? Theme.seafoam
                                                 : Theme.muted

    function toggleBt() {
        if (periph.btPresent) periph.adapter.enabled = !periph.adapter.enabled;
    }

    // ------------------------------------------------------------ batteries
    // Plain JS records rather than live objects: the delegates only ever want
    // a number and a glyph, and snapshotting keeps a device vanishing
    // mid-render from tearing the pill apart.
    property var batteries: []

    function syncBatteries() {
        const devs = UPower.devices ? UPower.devices.values : [];
        const out = [];
        for (var i = 0; i < devs.length; i++) {
            const d = devs[i];
            if (!d || !d.ready || d.powerSupply || !d.isPresent) continue;
            if (d.type === UPowerDeviceType.LinePower) continue;
            // UPower reports a 0..1 FRACTION here, not 0..100. A mouse at 55%
            // arrives as 0.55 and, taken at face value, rounds to a permanent
            // "1%" alarm. Bluetooth's own BluetoothDevice.battery is the same
            // scale, if this ever grows a second source.
            const pct = Math.round(d.percentage * 100);
            if (pct <= 0) continue;
            out.push({
                name    : d.model && d.model.length ? d.model : "peripheral",
                percent : pct,
                icon    : periph.iconFor(d.type),
                charging: d.state === UPowerDeviceState.Charging
            });
        }
        // Lowest first: the pill shows one, and the one worth showing is the
        // one about to die.
        out.sort(function (a, b) { return a.percent - b.percent; });
        periph.batteries = out;
    }

    readonly property var lowest: batteries.length > 0 ? batteries[0] : null
    readonly property bool hasBattery: lowest !== null

    function iconFor(t) {
        if (t === UPowerDeviceType.Mouse)      return Icons.mouse;
        if (t === UPowerDeviceType.Keyboard)   return Icons.keyboard;
        if (t === UPowerDeviceType.Headset)    return Icons.headset;
        if (t === UPowerDeviceType.Headphones) return Icons.headset;
        return Icons.battery;
    }

    // Green until it is worth noticing, wheat when it is, poppy when it is
    // nearly out. Charging always reads as calm regardless of level.
    function batteryAccent(pct, charging) {
        if (charging)  return Theme.seafoam;
        if (pct <= 15) return Theme.poppy;
        if (pct <= 35) return Theme.butter;
        return Theme.sage;
    }

    // ---- subscription keepers; render nothing --------------------------
    Item {
        Repeater {
            model: Bluetooth.devices
            delegate: Item {
                id: btItem
                required property var modelData
                Component.onCompleted: periph.syncBt()
                Component.onDestruction: Qt.callLater(periph.syncBt)
                Connections {
                    target: btItem.modelData
                    function onConnectedChanged() { periph.syncBt(); }
                    function onStateChanged()     { periph.syncBt(); }
                }
            }
        }

        Repeater {
            model: UPower.devices
            delegate: Item {
                id: upItem
                required property var modelData
                Component.onCompleted: periph.syncBatteries()
                Component.onDestruction: Qt.callLater(periph.syncBatteries)
                Connections {
                    target: upItem.modelData
                    function onPercentageChanged() { periph.syncBatteries(); }
                    function onStateChanged()      { periph.syncBatteries(); }
                    function onReadyChanged()      { periph.syncBatteries(); }
                }
            }
        }
    }

    Connections {
        target: Bluetooth
        function onDefaultAdapterChanged() { periph.syncBt(); }
    }
}

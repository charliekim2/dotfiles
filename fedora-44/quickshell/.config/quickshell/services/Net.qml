//
// Net — the one place that knows what the network is doing.
//
// Quickshell's Networking models are LAZY and they NEST. `Networking.devices`
// only populates while something is bound to it, and a WifiDevice's
// `.networks` needs its OWN bound view one level deeper — without it the
// associated AP never materialises and signal strength reads 0 forever. The
// hidden Repeaters at the bottom exist purely to hold those subscriptions
// open; they render nothing. Do not "clean them up".
//
pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Networking
import QtQuick
import qs

Singleton {
    id: net

    property var wifiDev : null   // WifiDevice, or null when no radio is bound
    property var activeAp: null   // the associated WifiNetwork, or null
    property var wiredDev: null   // a connected wired/tether device, or null

    readonly property bool   hasRadio : wifiDev !== null
    readonly property bool   hardOn   : Networking.wifiHardwareEnabled
    readonly property bool   softOn   : Networking.wifiEnabled
    readonly property bool   wifiUp   : activeAp !== null
    readonly property int    strength : activeAp ? Math.round(activeAp.signalStrength) : 0
    readonly property string ssid     : activeAp ? activeAp.name : ""

    // Portal/Limited mean associated but with no route out — worth showing
    // differently from a clean link. Unknown means NM has connectivity
    // checking off, in which case assume fine rather than cry wolf.
    readonly property bool online: Networking.connectivity === NetworkConnectivity.Full
                                || Networking.connectivity === NetworkConnectivity.Unknown

    // A radio that is missing entirely while some other link carries traffic:
    // the label shows that other link, so the bar needs to say why.
    readonly property bool faulted: !hasRadio && wiredDev !== null

    // systemd predictable names carry a "uN" hop for USB NICs
    // (enp128s20f0u1 = phone tether); onboard PCI NICs (enp129s0) do not.
    function isUsb(name) {
        return name.indexOf("usb") === 0 || /u\d/.test(name);
    }

    function sync() {
        const devs = Networking.devices ? Networking.devices.values : [];
        let wifi = null, wired = null;
        for (let i = 0; i < devs.length; i++) {
            const d = devs[i];
            if (d.type === DeviceType.Wifi) {
                if (!wifi) wifi = d;
            } else if (d.type === DeviceType.Wired && d.connected) {
                if (!wired) wired = d;
            }
        }
        let ap = null;
        if (wifi && wifi.networks) {
            const nets = wifi.networks.values;
            for (let j = 0; j < nets.length; j++) {
                if (nets[j].connected) { ap = nets[j]; break; }
            }
        }
        net.wifiDev  = wifi;
        net.wiredDev = wired;
        net.activeAp = ap;
    }

    // ---- presentation ------------------------------------------------------
    readonly property string label: {
        if (wifiUp)    return ssid + (online ? "" : " · no route");
        if (wiredDev)  return isUsb(wiredDev.name) ? "tethered" : "wired";
        if (!hasRadio) return "no wifi";
        if (!hardOn)   return "blocked";
        if (!softOn)   return "wifi off";
        return "offline";
    }

    // Sky while it works, poppy when something is actually wrong, muted when
    // it is merely idle — "off" is a state, not a fault.
    readonly property color accent: {
        if (wifiUp)    return online ? Theme.sky : Theme.poppy;
        if (wiredDev)  return Theme.sky;
        if (!hasRadio) return Theme.poppy;
        return Theme.muted;
    }

    readonly property string icon: {
        if (wiredDev && !wifiUp) return isUsb(wiredDev.name) ? Icons.usb : Icons.ethernet;
        if (!hasRadio)           return Icons.wifiNone;
        if (!hardOn || !softOn)  return Icons.wifiOff;
        return Icons.wifi;
    }

    // Bars are only meaningful for an associated radio; everything else shows
    // a glyph instead.
    readonly property bool showBars: wifiUp

    Connections {
        target: Networking
        function onWifiEnabledChanged()         { net.sync(); }
        function onWifiHardwareEnabledChanged() { net.sync(); }
        function onConnectivityChanged()        { net.sync(); }
    }

    // ---- subscription keepers; render nothing, see the header note ---------
    Item {
        Repeater {
            model: Networking.devices

            delegate: Item {
                id: devItem
                required property var modelData

                Component.onCompleted: net.sync()
                // modelData is already gone when this fires — defer a tick.
                Component.onDestruction: Qt.callLater(net.sync)

                Connections {
                    target: devItem.modelData
                    function onConnectedChanged() { net.sync(); }
                    function onStateChanged()     { net.sync(); }
                }

                Repeater {
                    model: devItem.modelData.type === DeviceType.Wifi
                           ? devItem.modelData.networks : null

                    delegate: Item {
                        id: apItem
                        required property var modelData

                        Component.onCompleted: net.sync()
                        Component.onDestruction: Qt.callLater(net.sync)

                        Connections {
                            target: apItem.modelData
                            function onConnectedChanged()       { net.sync(); }
                            function onSignalStrengthChanged()  { net.sync(); }
                        }
                    }
                }
            }
        }
    }
}

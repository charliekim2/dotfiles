//
// Quickshell — bar, notifications and alt-tab switcher. Hyprland / Fedora 44.
//
// Layout of this config:
//
//   Theme.qml            palette and every metric        (singleton)
//   Icons.qml            Material Icons codepoints       (singleton)
//   components/          Pill, Icon, StyledText, SignalBars
//   services/            Net, Peripherals, Audio, SysInfo, Notifs, Switcher
//                        (all singletons)
//   modules/bar/         the floating bar and its pills
//   modules/notifications/  toasts, dropdown, shared card
//   modules/switcher/    the alt-tab overlay
//
// Cross-cutting gotchas, learned the hard way — each is repeated in full at
// the place it bites, but they are collected here so they are findable:
//
//  * Singletons need the BARE `pragma Singleton`. Quickshell 0.3.1 does not
//    honour the `//@ pragma Singleton` comment form some docs show: the file
//    still loads as a type, but every property reads back undefined.
//
//  * Quickshell's models are LAZY and some of them NEST. Hyprland.workspaces,
//    Hyprland.toplevels, SystemTray.items, NotificationServer.trackedNotifications,
//    Networking.devices, WifiDevice.networks, Bluetooth.devices and
//    UPower.devices only populate while something is bound to them. Each
//    service keeps a hidden Repeater alive purely to hold that subscription
//    open. They render nothing and must not be "cleaned up".
//
//  * Icon themes need QT_QPA_PLATFORMTHEME=qt6ct in the environment, or Qt
//    searches only hicolor and image://icon/<name> never resolves.
//
//  * Fonts: Noto Sans (google-noto-sans-fonts) and Material Icons Round
//    (material-icons-fonts). Both are dnf packages; see the README. Noto
//    Sans is also what the GTK config uses, so the bar and the apps under
//    it share one UI sans.
//
import Quickshell
import QtQuick
import qs.modules.bar
import qs.modules.notifications
import qs.modules.switcher

ShellRoot {
    // One bar per monitor.
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    // Single instances: these follow the compositor's focused output rather
    // than being duplicated onto every screen.
    Toasts {}
    Panel {}
    SwitcherOverlay {}
}

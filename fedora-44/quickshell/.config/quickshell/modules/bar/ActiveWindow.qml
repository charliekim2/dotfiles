//
// ActiveWindow — the focused window's icon and title.
//
// Kept deliberately colourless. It is the one element in the bar that changes
// on every focus change, and giving it a hue as well would make the middle of
// the bar flicker between colours all day.
//
import QtQuick
import Quickshell
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.components

Pill {
    id: aw

    property int maxWidth: 260

    readonly property var win: ToplevelManager.activeToplevel

    // Guard the fields, not just the handle. A live toplevel can read back
    // title === undefined while Hyprland is still syncing, and QML refuses to
    // assign undefined to a QString.
    readonly property string appId: (win && win.appId) ? win.appId : ""
    readonly property string title: (win && win.title) ? win.title : ""

    accent: Theme.subtext
    interactive: false
    visible: title.length > 0

    IconImage {
        implicitSize: 14
        visible: aw.appId.length > 0
        source: Quickshell.iconPath(aw.appId, "application-x-executable")
    }

    StyledText {
        text: aw.title
        color: Theme.subtext
        elide: Text.ElideRight
        Layout.maximumWidth: aw.maxWidth
    }
}

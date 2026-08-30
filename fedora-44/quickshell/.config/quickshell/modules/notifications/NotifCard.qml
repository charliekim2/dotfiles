//
// NotifCard — one notification, used by both the toasts and the dropdown so
// a popup and its entry in the log are recognisably the same object.
//
// Each card takes a stable hue from its app name (critical always overrides to
// poppy), which is what makes a full dropdown scannable: you find the Slack
// one by colour long before you have read any of the headings.
//
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.components
import qs.services

Rectangle {
    id: card

    required property var notif
    property bool showActions: true

    signal dismissed()

    readonly property color accent   : Notifs.accentFor(notif)
    readonly property bool  critical : Notifs.isCritical(notif)

    // Everything below reads through these rather than touching `notif`
    // directly. Dismissing a notification nulls the delegate's modelData and
    // the bindings re-evaluate BEFORE the delegate is destroyed, so a direct
    // `notif.summary` throws a TypeError for every field on the way out —
    // three cards cleared meant twenty-seven warnings in the log.
    readonly property bool   valid    : notif !== null && notif !== undefined
    readonly property string summary  : valid ? notif.summary : ""
    readonly property string bodyText : valid ? notif.body    : ""
    readonly property string appName  : valid ? notif.appName : ""
    readonly property int    notifId  : valid ? notif.id      : -1
    readonly property string imageSrc : (valid && notif.image)   ? notif.image   : ""
    readonly property string iconName : (valid && notif.appIcon) ? notif.appIcon : ""
    readonly property var    actions  : valid ? notif.actions : []

    implicitHeight: body.implicitHeight + 18
    radius: Theme.cardRadius

    // Opaque, not a wash: this same card is used for toasts, which float over
    // the desktop with nothing behind them. See Theme.over().
    color: Theme.over(Theme.panel, accent, 0.12)
    border.width: critical ? 2 : 1
    border.color: Theme.over(Theme.panel, accent, critical ? 0.85 : 0.32)

    // Accent spine: reads as a colour index down the left edge of the list.
    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            margins: 7
        }
        width: 3
        radius: 1.5
        color: card.accent
    }

    ColumnLayout {
        id: body
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 18
            rightMargin: 12
        }
        spacing: 4

        // ---- heading: icon, summary, app, age, close ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item {
                implicitWidth: 20
                implicitHeight: 20
                Layout.alignment: Qt.AlignVCenter
                visible: img.visible || appIcon.visible

                // A hint-supplied image (album art, avatar) wins over the
                // app's own themed icon when the client sends one.
                Image {
                    id: img
                    anchors.fill: parent
                    visible: card.imageSrc.length > 0
                    source: card.imageSrc
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                }

                IconImage {
                    id: appIcon
                    anchors.fill: parent
                    visible: !img.visible && card.iconName.length > 0
                    source: visible ? Quickshell.iconPath(card.iconName, "dialog-information") : ""
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: card.summary
                color: card.critical ? card.accent : Theme.text
                font.bold: true
                elide: Text.ElideRight
            }

            StyledText {
                text: card.appName
                color: Theme.muted
                font.pixelSize: Theme.fsSmall
                elide: Text.ElideRight
                Layout.maximumWidth: 90
            }

            // Notifs.now is passed only to make this binding re-run each
            // minute; ago() ignores the value itself.
            StyledText {
                text: Notifs.ago(card.notifId, Notifs.now)
                color: Theme.muted
                font.pixelSize: Theme.fsSmall
                visible: text.length > 0
            }

            Rectangle {
                implicitWidth: 18
                implicitHeight: 18
                radius: 9
                Layout.alignment: Qt.AlignVCenter
                color: closeMouse.containsMouse ? Theme.tint(card.accent, 0.45) : "transparent"

                Icon {
                    anchors.centerIn: parent
                    text: Icons.close
                    color: closeMouse.containsMouse ? Theme.text : Theme.muted
                    font.pixelSize: 13
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.dismissed()
                }

                Behavior on color { ColorAnimation { duration: Theme.anim } }
            }
        }

        // ---- body ----
        StyledText {
            Layout.fillWidth: true
            visible: card.bodyText.length > 0
            text: card.bodyText
            color: Theme.subtext
            font.pixelSize: Theme.fsSmall
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
            // The server advertises bodyMarkupSupported, so honour the markup
            // rather than printing raw <b> tags at the user.
            textFormat: Text.StyledText
        }

        // ---- actions ----
        RowLayout {
            Layout.topMargin: 2
            spacing: Theme.pillGap
            visible: card.showActions && card.actions.length > 0

            Repeater {
                model: card.actions

                delegate: Pill {
                    id: actionPill
                    required property var modelData

                    accent: card.accent
                    padH: 9
                    implicitHeight: 20

                    onClicked: {
                        actionPill.modelData.invoke();
                        card.dismissed();
                    }

                    StyledText {
                        text: actionPill.modelData.text
                        color: actionPill.labelColor
                        font.pixelSize: Theme.fsSmall
                    }
                }
            }
        }
    }
}

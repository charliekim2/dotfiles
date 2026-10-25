//
// KeybindPalette — searchable cheat sheet of the Hyprland binds (SUPER+/).
//
// One full-screen surface: a faint scrim that dismisses on click, with the
// card centred on it. Doing the click-away inside the same window sidesteps
// the two-surface layer-ordering race that Panel.qml has to work around.
//
// Type to filter; Up/Down (or Ctrl+J/K) walk the results; Escape clears the
// query, and a second Escape (or SUPER+/ again) closes.
//
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.services

PanelWindow {
    id: palette

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusiveZone: 0
    visible: Keybinds.open

    focusable: Keybinds.open
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Keybinds.open ? WlrKeyboardFocus.Exclusive
                                               : WlrKeyboardFocus.None

    // ListModel rather than a JS array: ListView sections need a real role.
    ListModel { id: results }

    function refresh() {
        results.clear();
        for (const b of Keybinds.filter(search.text))
            results.append({ category: b.category, title: b.title,
                             keys: b.keys.join("\u0001") });
        list.currentIndex = results.count ? 0 : -1;
        list.positionViewAtBeginning();
    }

    function move(d) {
        if (!results.count) return;
        list.currentIndex = Math.max(0, Math.min(results.count - 1, list.currentIndex + d));
    }

    onVisibleChanged: if (visible) {
        search.text = "";
        refresh();
        search.forceActiveFocus();
    }

    // ---------------------------------------------------------- scrim
    Rectangle {
        anchors.fill: parent
        color: Theme.tint(Theme.ink, 0.35)

        MouseArea {
            anchors.fill: parent
            onClicked: Keybinds.open = false
        }
    }

    // ---------------------------------------------------------- card
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: 620
        height: Math.min(600, parent.height - 80)
        radius: Theme.panelRadius
        color: Theme.panel
        border.width: 1
        border.color: Theme.line

        // swallow clicks so they don't fall through to the scrim
        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors { fill: parent; margins: 14 }
            spacing: 10

            // ---- search field ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Theme.cardRadius
                color: Theme.raised
                border.width: 1
                border.color: search.activeFocus ? Theme.tint(Theme.sky, 0.6) : Theme.line

                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    spacing: 10

                    Icon {
                        text: Icons.keyboard
                        color: Theme.sky
                        font.pixelSize: 18
                    }

                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        color: Theme.text
                        selectionColor: Theme.tint(Theme.sky, 0.4)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fsLarge
                        renderType: Text.NativeRendering
                        clip: true
                        focus: true

                        onTextChanged: palette.refresh()

                        Keys.onEscapePressed: {
                            if (search.text.length) search.text = "";
                            else Keybinds.open = false;
                        }
                        Keys.onUpPressed:   palette.move(-1)
                        Keys.onDownPressed: palette.move(1)
                        Keys.onPressed: function (e) {
                            if (!(e.modifiers & Qt.ControlModifier)) return;
                            if (e.key === Qt.Key_J || e.key === Qt.Key_N) { palette.move(1);  e.accepted = true; }
                            else if (e.key === Qt.Key_K || e.key === Qt.Key_P) { palette.move(-1); e.accepted = true; }
                            else if (e.key === Qt.Key_U) { search.text = ""; e.accepted = true; }
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !search.text.length
                            text: "Search binds — move, resize, workspace, split…"
                            color: Theme.muted
                            font.pixelSize: Theme.fsLarge
                        }
                    }

                    StyledText {
                        text: results.count + " / " + Keybinds.binds.length
                        color: Theme.muted
                        font.pixelSize: Theme.fsSmall
                        font.features: { "tnum": 1 }
                    }
                }
            }

            // ---- results ----
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: results
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0
                // keep the current row (and its section header) in view
                preferredHighlightBegin: 30
                preferredHighlightEnd: height - 10
                highlightRangeMode: ListView.ApplyRange

                section.property: "category"
                section.delegate: Item {
                    id: header
                    required property string section
                    width: ListView.view.width
                    height: 30

                    StyledText {
                        anchors { left: parent.left; leftMargin: 6; bottom: parent.bottom; bottomMargin: 6 }
                        text: header.section.toUpperCase()
                        color: Theme.accent(Keybinds.categories.indexOf(header.section))
                        font.pixelSize: Theme.fsSmall
                        font.bold: true
                        font.letterSpacing: 1.2
                    }
                }

                delegate: Rectangle {
                    id: row
                    required property int index
                    required property string category
                    required property string title
                    required property string keys

                    readonly property bool  current: ListView.isCurrentItem
                    readonly property color accent: Theme.accent(Keybinds.categories.indexOf(category))

                    width: ListView.view.width
                    height: 36
                    radius: 10
                    color: current ? Theme.tint(accent, Theme.washIdle) : "transparent"

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: list.currentIndex = row.index
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                        spacing: 6

                        StyledText {
                            Layout.fillWidth: true
                            text: row.title
                            color: row.current ? Theme.text : Theme.subtext
                            elide: Text.ElideRight
                        }

                        Repeater {
                            model: row.keys.split("\u0001")

                            delegate: Rectangle {
                                id: cap
                                required property string modelData
                                implicitWidth: capText.implicitWidth + 14
                                implicitHeight: 22
                                radius: 6
                                color: Theme.raised
                                border.width: 1
                                border.color: row.current ? Theme.tint(row.accent, 0.55) : Theme.line

                                StyledText {
                                    id: capText
                                    anchors.centerIn: parent
                                    text: cap.modelData
                                    color: row.current ? row.accent : Theme.text
                                    font.pixelSize: Theme.fsSmall
                                }
                            }
                        }
                    }
                }

                // ---- empty state ----
                StyledText {
                    anchors.centerIn: parent
                    visible: results.count === 0
                    text: "No binds match “" + search.text + "”"
                    color: Theme.muted
                }
            }

            // ---- footer hint ----
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "↑↓ navigate   ·   Esc clear / close   ·   Super+/ toggle"
                color: Theme.muted
                font.pixelSize: Theme.fsSmall
            }
        }
    }
}

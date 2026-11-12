/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later

    Golden Gate "device bezel" action button used by the top-right header
    cluster of the CachyOS Android Phone Mirroring window (Home Screen, App Switcher
    and Control Center). The glyphs are drawn as vectors so they stay crisp and
    they inherit the `CachyTheme` palette (light/dark aware).
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import CachyOS.UI

Rectangle {
    id: root

    property string iconKind: "home" // "home" | "switcher" | "controlCenter"
    property string tooltipText: ""
    property bool active: false

    signal clicked()

    implicitWidth: 28
    implicitHeight: 24
    radius: 6

    readonly property color glyphColor: root.active ? "#FFFFFF" : CachyTheme.textPrimary

    color: root.active
        ? CachyTheme.accentColor
        : (hoverHandler.hovered ? CachyTheme.cardBackgroundHover : "transparent")

    border.width: root.active ? 1 : 0
    border.color: root.active ? Qt.rgba(1, 1, 1, 0.25) : "transparent"

    Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }

    scale: tapHandler.pressed ? 0.94 : (hoverHandler.hovered ? 1.04 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: CachyTheme.animFast; easing.type: Easing.OutBack }
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tapHandler
        onTapped: root.clicked()
    }

    // ------------------------------------------------------------------------
    // Home Screen — device outline with the home bar
    // ------------------------------------------------------------------------
    Item {
        anchors.centerIn: parent
        width: 16
        height: 12
        visible: root.iconKind === "home"

        Rectangle {
            anchors.fill: parent
            radius: 2.5
            color: "transparent"
            border.width: 1.4
            border.color: root.glyphColor
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1.6
            width: 6
            height: 1.4
            radius: 0.7
            color: root.glyphColor
        }
    }

    // ------------------------------------------------------------------------
    // App Switcher — 2x2 grid
    // ------------------------------------------------------------------------
    Grid {
        anchors.centerIn: parent
        columns: 2
        spacing: 2.5
        visible: root.iconKind === "switcher"

        Repeater {
            model: 4
            Rectangle {
                width: 5.5
                height: 5.5
                radius: 1.2
                color: "transparent"
                border.width: 1.3
                border.color: root.glyphColor
            }
        }
    }

    // ------------------------------------------------------------------------
    // Control Center — two sliders
    // ------------------------------------------------------------------------
    Column {
        anchors.centerIn: parent
        spacing: 2.5
        visible: root.iconKind === "controlCenter"

        Rectangle {
            width: 14
            height: 5
            radius: 2.5
            color: "transparent"
            border.width: 1.2
            border.color: root.glyphColor

            Rectangle {
                width: 3.5
                height: 3.5
                radius: 1.75
                anchors.right: parent.right
                anchors.rightMargin: 1
                anchors.verticalCenter: parent.verticalCenter
                color: root.glyphColor
            }
        }

        Rectangle {
            width: 14
            height: 5
            radius: 2.5
            color: "transparent"
            border.width: 1.2
            border.color: root.glyphColor

            Rectangle {
                width: 3.5
                height: 3.5
                radius: 1.75
                anchors.left: parent.left
                anchors.leftMargin: 1
                anchors.verticalCenter: parent.verticalCenter
                color: root.glyphColor
            }
        }
    }

    ToolTip.visible: hoverHandler.hovered && root.tooltipText.length > 0
    ToolTip.text: root.tooltipText
    ToolTip.delay: 450
}

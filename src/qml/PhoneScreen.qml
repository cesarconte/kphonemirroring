/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later

    Device screen chassis of the CachyOS Android Phone Mirroring window.

    The chassis is *hardware* (titanium bezel + punch-hole camera) and keeps a
    fixed dark finish on purpose: a real device screen never inherits the host
    desktop colour scheme. Every host-side surface (window frame, sidebar,
    toolbars, sheets) is Liquid Glass; the mirrored screen owns its own skin.
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CachyOS.UI

Item {
    id: root

    property string activeTab: "today"

    readonly property bool wide: root.width >= 560

    // =========================================================================
    // Device chassis (titanium bezel)
    // =========================================================================
    Rectangle {
        id: chassis
        anchors.fill: parent
        radius: 30
        color: "#0B0B0E"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)

        // Punch-hole camera
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 8
            width: 9
            height: 9
            radius: 4.5
            color: "#000000"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)
            z: 3
        }

        // Device screen
        Rectangle {
            id: screen
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: parent.top
            anchors.margins: 12
            anchors.topMargin: 26
            radius: 22
            color: "#FFFFFF"
            clip: true

            StackLayout {
                id: pageStack
                anchors.fill: parent
                currentIndex: root.activeTab === "apps" ? 1 : (root.activeTab === "device" ? 2 : 0)

                DeviceTodayPage {
                    onRequestTab: (tab) => root.activeTab = tab
                }
                DeviceAppsPage {
                    onRequestTab: (tab) => root.activeTab = tab
                }
                DeviceLivePage {}
            }

            // -----------------------------------------------------------------
            // Device navigation bar (belongs to the phone, not to the host app)
            // -----------------------------------------------------------------
            Rectangle {
                id: deviceTabBar
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                height: 34
                implicitWidth: deviceTabRow.implicitWidth + 14
                radius: 17
                color: Qt.rgba(1, 1, 1, 0.82)
                border.width: 1
                border.color: Qt.rgba(0, 0, 0, 0.10)

                RowLayout {
                    id: deviceTabRow
                    anchors.centerIn: parent
                    spacing: 2

                    Repeater {
                        model: [
                            { id: "today", label: "Today" },
                            { id: "apps", label: "Apps" },
                            { id: "device", label: "Mirroring" }
                        ]

                        Rectangle {
                            required property var modelData
                            readonly property bool isCurrent: root.activeTab === modelData.id

                            height: 26
                            implicitWidth: tabLabel.implicitWidth + 16
                            radius: 13
                            color: isCurrent ? Qt.rgba(0, 122, 255, 0.12) : "transparent"

                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                id: tabLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                font.pixelSize: 11
                                font.weight: isCurrent ? Font.Bold : Font.Medium
                                color: isCurrent ? "#007AFF" : "#3A3A3C"
                            }

                            TapHandler {
                                onTapped: root.activeTab = modelData.id
                            }
                        }
                    }
                }
            }
        }
    }
}

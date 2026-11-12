/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later

    "Apps" catalogue rendered inside the mirrored device screen. It mirrors the
    Golden Gate discovery "Apps" tab and launches the selected
    Android package through scrcpy.
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CachyOS.UI

Flickable {
    id: root

    signal requestTab(string tab)

    contentWidth: width
    contentHeight: appsColumn.implicitHeight + 76
    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    readonly property bool wide: root.width >= 560

    ColumnLayout {
        id: appsColumn
        width: root.width - 40
        x: 20
        y: 16
        spacing: 16

        // =====================================================================
        // Title row
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Apps"
                font.pixelSize: 28
                font.weight: Font.Bold
                color: "#111114"
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: false
                text: "Android · " + (deviceManager.hasDevice ? deviceManager.selectedDevice.osType : "scrcpy")
                font.pixelSize: 11
                color: "#8E8E93"
                elide: Text.ElideRight
            }
        }

        // =====================================================================
        // App grid
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            // The height must account for the vertical padding of the inner
            // column, otherwise the content overflows the card by a few pixels.
            implicitHeight: gridColumn.implicitHeight + (CachyTheme.marginCard * 2)
            radius: 18
            color: "#F5F5F7"
            border.width: 1
            border.color: "#E5E5EA"

            ColumnLayout {
                id: gridColumn
                anchors.fill: parent
                anchors.margins: CachyTheme.marginCard
                spacing: 14

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: "TOP APPS"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: "#8E8E93"
                    elide: Text.ElideRight
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    columns: root.wide ? 5 : 3
                    columnSpacing: 12
                    rowSpacing: 16

                    Repeater {
                        model: [
                            { id: "chatgpt", title: "ChatGPT", icon: "❂", tint: "#10A37F", pkg: "com.openai.chatgpt" },
                            { id: "whatsapp", title: "WhatsApp", icon: "💬", tint: "#25D366", pkg: "com.whatsapp" },
                            { id: "spotify", title: "Spotify", icon: "🎵", tint: "#1DB954", pkg: "com.spotify.music" },
                            { id: "youtube", title: "YouTube", icon: "▶", tint: "#FF0000", pkg: "com.google.android.youtube" },
                            { id: "instagram", title: "Instagram", icon: "📷", tint: "#E1306C", pkg: "com.instagram.android" },
                            { id: "maps", title: "Maps", icon: "🗺️", tint: "#34A853", pkg: "com.google.android.apps.maps" },
                            { id: "camera", title: "Camera", icon: "📸", tint: "#5856D6", pkg: "com.android.camera2" },
                            { id: "files", title: "Files", icon: "📁", tint: "#0A84FF", pkg: "com.google.android.documentsui" },
                            { id: "settings", title: "Settings", icon: "⚙️", tint: "#8E8E93", pkg: "com.android.settings" },
                            { id: "clock", title: "Clock", icon: "⏰", tint: "#FF9500", pkg: "com.google.android.deskclock" }
                        ]

                        ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 6

                            Rectangle {
                                Layout.preferredWidth: 54
                                Layout.preferredHeight: 54
                                Layout.alignment: Qt.AlignHCenter
                                radius: 14
                                color: modelData.tint

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.pixelSize: 24
                                    color: "#FFFFFF"
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: modelData.title
                                font.pixelSize: 11
                                color: "#111114"
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // Live mirroring shortcut
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            implicitHeight: 74
            radius: 18
            color: "#111114"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: 12
                    color: "#1C1C22"
                    Text { anchors.centerIn: parent; text: "📱"; font.pixelSize: 20 }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: "Live Screen Mirroring"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: mirrorSession.isRunning ? "Sesión scrcpy activa" : "Iniciar sesión scrcpy en vivo"
                        font.pixelSize: 11
                        color: "#CCCCCC"
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 66
                    Layout.preferredHeight: 28
                    radius: 14
                    color: "#0A84FF"

                    Text {
                        anchors.centerIn: parent
                        text: mirrorSession.isRunning ? "Abrir" : "Iniciar"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                    }

                    TapHandler {
                        onTapped: root.requestTab("device")
                    }
                }
            }
        }
    }
}

/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later

    "Today" discovery page rendered inside the mirrored device screen.
    It reproduces the Golden Gate discovery layout and acts
    as the launcher surface for the Android applications handled by scrcpy.
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CachyOS.UI

Flickable {
    id: root

    signal requestTab(string tab)

    contentWidth: width
    contentHeight: storeColumn.implicitHeight + 76
    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    readonly property bool wide: root.width >= 560

    ColumnLayout {
        id: storeColumn
        width: root.width - 40
        x: 20
        y: 16
        spacing: 16

        // =====================================================================
        // Title row — "Today" + account badge
        // =====================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Today"
                font.pixelSize: 28
                font.weight: Font.Bold
                color: "#111114"
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#5CE67E" }
                    GradientStop { position: 1.0; color: "#28CD56" }
                }

                Text {
                    anchors.centerIn: parent
                    text: "😊"
                    font.pixelSize: 18
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: -4
                    anchors.topMargin: -3
                    width: 20
                    height: 15
                    radius: 7.5
                    color: "#FF3B30"

                    // The floating notification badge deliberately overlaps
                    // its avatar, so it is exempt from the layout audit.
                    property bool auditBleed: true

                    Text {
                        anchors.centerIn: parent
                        text: "14"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                    }
                }
            }
        }

        // =====================================================================
        // Hero cards
        // =====================================================================
        GridLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            columns: root.wide ? 2 : 1
            columnSpacing: 16
            rowSpacing: 16

            // ---- Card 1 — "Ready, Aim...Flick!" ----
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 285
                radius: 18
                clip: true

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#7EC8E3" }
                    GradientStop { position: 0.52; color: "#4A7C59" }
                    GradientStop { position: 1.0; color: "#5C4738" }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Row {
                            anchors.centerIn: parent
                            spacing: 12
                            Text { text: "🏹"; font.pixelSize: 44 }
                            Text { text: "🛡️"; font.pixelSize: 48 }
                            Text { text: "⚔️"; font.pixelSize: 44 }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        Layout.bottomMargin: 14
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: "INCREDIBLE INDIE"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: "#D9FFFFFF"
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: "Ready, Aim...Flick!"
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            color: "#FFFFFF"
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: "Tame a troubled treasure island in this roguelike indie gem."
                            font.pixelSize: 11
                            color: "#D9FFFFFF"
                            wrapMode: Text.WordWrap
                        }

                        Item { height: 6 }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                radius: 8
                                color: "#2E1F3B"
                                Text { anchors.centerIn: parent; text: "🎯"; font.pixelSize: 18 }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    text: "Flick Shot Rogues"
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: "#FFFFFF"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    text: "Plan, Aim, Shoot!"
                                    font.pixelSize: 10
                                    color: "#CCFFFFFF"
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 58
                                Layout.preferredHeight: 26
                                radius: 13
                                color: "#4DFFFFFF"
                                Text {
                                    anchors.centerIn: parent
                                    text: "Get"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: "#FFFFFF"
                                }
                                TapHandler {
                                    onTapped: mirrorSession.openApp("flick_shot", "Flick Shot Rogues", "com.android.vending")
                                }
                            }
                        }
                    }
                }
            }

            // ---- Card 2 — "ChatGPT" ----
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 285
                radius: 18
                clip: true

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#D6D6DC" }
                    GradientStop { position: 0.55; color: "#686870" }
                    GradientStop { position: 1.0; color: "#232326" }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.centerIn: parent
                            width: 68
                            height: 68
                            radius: 16
                            color: "#FFFFFF"
                            border.width: 1
                            border.color: "#E5E5EA"

                            Text {
                                anchors.centerIn: parent
                                text: "❂"
                                font.pixelSize: 38
                                color: "#111114"
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        Layout.bottomMargin: 14
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: "ChatGPT"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                color: "#FFFFFF"
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: "Your everyday AI assistant"
                                font.pixelSize: 11
                                color: "#CCCCCC"
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 58
                            Layout.preferredHeight: 26
                            radius: 13
                            color: "#4DFFFFFF"
                            Text {
                                anchors.centerIn: parent
                                text: "Get"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: "#FFFFFF"
                            }
                            TapHandler {
                                onTapped: mirrorSession.openApp("chatgpt", "ChatGPT", "com.openai.chatgpt")
                            }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // "Our favourites" section
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            // The height must account for the vertical padding of the inner
            // column, otherwise the content overflows the card by a few pixels.
            implicitHeight: favouritesColumn.implicitHeight + (CachyTheme.marginCard * 2)
            radius: 18
            color: "#F5F5F7"
            border.width: 1
            border.color: "#E5E5EA"

            ColumnLayout {
                id: favouritesColumn
                anchors.fill: parent
                anchors.margins: CachyTheme.marginCard
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: "OUR FAVORITES"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#8E8E93"
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: "Essential Android Games & Mirroring"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: "#111114"
                        elide: Text.ElideRight
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    columns: root.wide ? 2 : 1
                    columnSpacing: 18
                    rowSpacing: 12

                    Repeater {
                        model: [
                            { id: "pokemongo", title: "Pokémon GO", sub: "Epic AR adventure & online RPG", action: "Open", icon: "🔴", pkg: "com.nianticlabs.pokemongo" },
                            { id: "genshin", title: "Genshin Impact", sub: "Anime Action RPG", action: "Get", icon: "✨", pkg: "com.miHoYo.GenshinImpact" },
                            { id: "minecraft", title: "Minecraft: Play with Friends", sub: "Create, explore and survive!", action: "€6.99", icon: "🟩", pkg: "com.mojang.minecraftpe" },
                            { id: "scrcpy_live", title: deviceManager.hasDevice ? deviceManager.selectedDevice.name : "Live Screen Mirroring", sub: mirrorSession.isRunning ? "Active scrcpy session" : "Launch real scrcpy video & audio", action: mirrorSession.isRunning ? "Stop" : "Mirror", icon: "📱", pkg: "" }
                        ]

                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 42
                                Layout.preferredHeight: 42
                                radius: 10
                                color: "#FFFFFF"
                                border.width: 1
                                border.color: "#E5E5EA"
                                Text { anchors.centerIn: parent; text: modelData.icon; font.pixelSize: 20 }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    text: modelData.title
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    color: "#111114"
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    text: modelData.sub
                                    font.pixelSize: 11
                                    color: "#8E8E93"
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 60
                                Layout.preferredHeight: 26
                                radius: 13
                                color: "#E8E8ED"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.action
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: "#007AFF"
                                }

                                TapHandler {
                                    onTapped: {
                                        if (modelData.id === "scrcpy_live") {
                                            root.requestTab("device");
                                        } else {
                                            mirrorSession.openApp(modelData.id, modelData.title, modelData.pkg);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

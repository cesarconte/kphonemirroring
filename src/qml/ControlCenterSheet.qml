/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-FileCopyrightText: 2026 CachyOS UI contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Golden Gate Control Center (Ctrl+4) rendered as a Liquid Glass sheet on top
 * of the window, replicating the CachyOS Android Phone Mirroring quick controls.
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CachyOS.UI

Rectangle {
    id: root

    signal dismissRequested()

    width: 300
    implicitHeight: sheetColumn.implicitHeight + 24
    radius: CachyTheme.radiusLarge
    color: CachyPalette.sheetBackground
    border.width: 1
    border.color: CachyPalette.specularBorder

    // Liquid Glass depth: specular highlight on the upper edge
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: parent.radius - 1
        color: "transparent"
        opacity: 0.5

        gradient: Gradient {
            GradientStop { position: 0.0; color: CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.55) }
            GradientStop { position: 0.5; color: "transparent" }
        }
    }

    ColumnLayout {
        id: sheetColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: CachyTheme.spacingMedium

        // ---- Header ----
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 8

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Control Center"
                font.pixelSize: 13
                font.weight: Font.Bold
                color: CachyPalette.text
                elide: Text.ElideRight
            }

            CachyToolbarButton {
                iconName: "window-close"
                tooltipText: "Cerrar"
                onClicked: root.dismissRequested()
            }
        }

        // ---- Quick controls ----
        GridLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: CachyTheme.radiusMedium
                color: mirrorSession.audioEnabled ? CachyTheme.accentColor : CachyPalette.surfacePill
                border.width: 1
                border.color: mirrorSession.audioEnabled ? CachyTheme.accentColor : CachyPalette.specularBorder

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    CachyIcon {
                        name: "audio-volume-high"
                        size: 14
                        color: mirrorSession.audioEnabled ? "#FFFFFF" : CachyPalette.text
                    }
                    Text {
                        text: "Audio PC"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: mirrorSession.audioEnabled ? "#FFFFFF" : CachyPalette.text
                    }
                }

                TapHandler {
                    onTapped: mirrorSession.audioEnabled = !mirrorSession.audioEnabled
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: CachyTheme.radiusMedium
                color: mirrorSession.turnScreenOff ? "#30D158" : CachyPalette.surfacePill
                border.width: 1
                border.color: mirrorSession.turnScreenOff ? "#30D158" : CachyPalette.specularBorder

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    CachyIcon {
                        name: "weather-clear-night"
                        size: 14
                        color: mirrorSession.turnScreenOff ? "#FFFFFF" : CachyPalette.text
                    }
                    Text {
                        text: "Pantalla Off"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: mirrorSession.turnScreenOff ? "#FFFFFF" : CachyPalette.text
                    }
                }

                TapHandler {
                    onTapped: mirrorSession.turnScreenOff = !mirrorSession.turnScreenOff
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: CachyTheme.radiusMedium
                color: CachyPalette.surfacePill
                border.width: 1
                border.color: CachyPalette.specularBorder

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    CachyIcon {
                        name: "camera-photo"
                        size: 14
                        color: CachyPalette.text
                    }
                    Text {
                        text: "Captura"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: CachyPalette.text
                    }
                }

                TapHandler {
                    onTapped: mirrorSession.takeScreenshot()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: CachyTheme.radiusMedium
                color: CachyPalette.surfacePill
                border.width: 1
                border.color: CachyPalette.specularBorder

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    CachyIcon {
                        name: "notifications"
                        size: 14
                        color: CachyPalette.text
                    }
                    Text {
                        text: "Avisos"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: CachyPalette.text
                    }
                }

                TapHandler {
                    onTapped: mirrorSession.sendExpandNotifications()
                }
            }
        }

        // ---- Routing hint ----
        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: "El audio se captura desde el stream por defecto de PipeWire para respetar los filtros DSP de EasyEffects."
            font.pixelSize: 10
            color: CachyPalette.textMuted
            wrapMode: Text.WordWrap
        }
    }
}

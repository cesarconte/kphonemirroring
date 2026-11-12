/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later

    Golden Gate Control Center (Ctrl+4) rendered as a Liquid Glass sheet on top
    of the window, replicating the macOS 27 iPhone Mirroring quick controls.
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
    color: CachyTheme.sheetBackground
    border.width: 1
    border.color: CachyTheme.specularBorder

    // Liquid Glass depth: specular highlight on the upper edge
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: parent.radius - 1
        color: "transparent"
        opacity: 0.5

        gradient: Gradient {
            GradientStop { position: 0.0; color: CachyTheme.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.55) }
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
                color: CachyTheme.textPrimary
                elide: Text.ElideRight
            }

            CachyToolbarButton {
                text: "✕"
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
                color: mirrorSession.audioEnabled ? CachyTheme.accentColor : CachyTheme.surfacePill
                border.width: 1
                border.color: mirrorSession.audioEnabled ? CachyTheme.accentColor : CachyTheme.specularBorder

                Text {
                    anchors.centerIn: parent
                    text: "🔊 Audio PC"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: mirrorSession.audioEnabled ? "#FFFFFF" : CachyTheme.textPrimary
                }

                TapHandler {
                    onTapped: mirrorSession.audioEnabled = !mirrorSession.audioEnabled
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: CachyTheme.radiusMedium
                color: mirrorSession.turnScreenOff ? "#30D158" : CachyTheme.surfacePill
                border.width: 1
                border.color: mirrorSession.turnScreenOff ? "#30D158" : CachyTheme.specularBorder

                Text {
                    anchors.centerIn: parent
                    text: "🌙 Pantalla Off"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: mirrorSession.turnScreenOff ? "#FFFFFF" : CachyTheme.textPrimary
                }

                TapHandler {
                    onTapped: mirrorSession.turnScreenOff = !mirrorSession.turnScreenOff
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: CachyTheme.radiusMedium
                color: CachyTheme.surfacePill
                border.width: 1
                border.color: CachyTheme.specularBorder

                Text {
                    anchors.centerIn: parent
                    text: "📸 Captura"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: CachyTheme.textPrimary
                }

                TapHandler {
                    onTapped: mirrorSession.takeScreenshot()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: CachyTheme.radiusMedium
                color: CachyTheme.surfacePill
                border.width: 1
                border.color: CachyTheme.specularBorder

                Text {
                    anchors.centerIn: parent
                    text: "🔔 Avisos"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: CachyTheme.textPrimary
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
            color: CachyTheme.textMuted
            wrapMode: Text.WordWrap
        }
    }
}

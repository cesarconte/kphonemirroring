/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later

    Golden Gate preferences sheet (⚙, far right of the header) holding every
    mirroring option. It is the single source of truth for the scrcpy stream:
    the values are owned by `MirrorSession` and persisted between sessions.
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CachyOS.UI

Rectangle {
    id: root

    signal dismissRequested()

    width: 380
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
        spacing: CachyTheme.spacingSmall

        // ---- Header ----
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 8

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Preferencias de duplicación"
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

        CachyDivider {}

        // ---- Switches ----
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 10

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Apagar la pantalla física del móvil"
                font.pixelSize: 12
                color: CachyTheme.textPrimary
                wrapMode: Text.WordWrap
            }

            CachySwitch {
                checked: mirrorSession.turnScreenOff
                onToggled: mirrorSession.turnScreenOff = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 10

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Mantener el dispositivo despierto"
                font.pixelSize: 12
                color: CachyTheme.textPrimary
                wrapMode: Text.WordWrap
            }

            CachySwitch {
                checked: mirrorSession.stayAwake
                onToggled: mirrorSession.stayAwake = checked
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 10

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Transmitir el audio por PipeWire"
                font.pixelSize: 12
                color: CachyTheme.textPrimary
                wrapMode: Text.WordWrap
            }

            CachySwitch {
                checked: mirrorSession.audioEnabled
                onToggled: mirrorSession.audioEnabled = checked
            }
        }

        CachyDivider {}

        // ---- Frame rate ----
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 10

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Tasa de fotogramas"
                font.pixelSize: 12
                color: CachyTheme.textPrimary
                wrapMode: Text.WordWrap
            }

            CachySegmentedControl {
                model: ["30", "60", "120"]
                currentIndex: mirrorSession.maxFps <= 30 ? 0 : (mirrorSession.maxFps >= 120 ? 2 : 1)
                onCurrentIndexChanged: mirrorSession.maxFps = [30, 60, 120][currentIndex]
            }
        }

        // ---- Bitrate ----
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 10

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Tasa de bits"
                font.pixelSize: 12
                color: CachyTheme.textPrimary
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.preferredWidth: 66
                horizontalAlignment: Text.AlignRight
                text: mirrorSession.bitrateMbps + " Mbps"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                color: CachyTheme.textSecondary
                elide: Text.ElideRight
            }
        }

        CachySlider {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            from: 4
            to: 64
            stepSize: 1
            value: mirrorSession.bitrateMbps
            onMoved: mirrorSession.bitrateMbps = Math.round(value)
        }

        // ---- Routing hint ----
        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: "El audio nunca se fija a un dispositivo físico (hw:*): se captura del stream por defecto de WirePlumber para atravesar la cadena DSP de EasyEffects."
            font.pixelSize: 10
            color: CachyTheme.textMuted
            wrapMode: Text.WordWrap
        }
    }
}

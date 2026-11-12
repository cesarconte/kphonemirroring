/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later

    Live mirroring page rendered inside the mirrored device screen. It shows the
    scrcpy session state, the routing of the audio stream through PipeWire and
    the quality parameters that are currently applied.
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    signal requestTab(string tab)

    Rectangle {
        id: livePanel
        anchors.fill: parent
        anchors.margins: 18
        radius: 24
        color: "#141418"
        border.width: mirrorSession.isRunning ? 2 : 1
        border.color: mirrorSession.isRunning ? "#0A84FF" : "#3A3A3C"

        ColumnLayout {
            anchors.centerIn: parent
            width: Math.min(360, parent.width - 32)
            spacing: 12

            // -----------------------------------------------------------------
            // Device identity
            // -----------------------------------------------------------------
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: deviceManager.hasDevice ? deviceManager.selectedDevice.name : "Sin dispositivo conectado"
                font.pixelSize: 18
                font.weight: Font.Bold
                color: "#FFFFFF"
                elide: Text.ElideRight
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: deviceManager.hasDevice
                    ? (deviceManager.selectedDevice.osType + " • Android " + deviceManager.selectedDevice.androidVersion + " (" + (deviceManager.selectedDevice.isWireless ? "Wi-Fi" : "USB") + ")")
                    : "Conecta tu teléfono por USB o Wi-Fi ADB"
                font.pixelSize: 12
                color: "#8E8E93"
                wrapMode: Text.WordWrap
            }

            // -----------------------------------------------------------------
            // Session status pill
            // -----------------------------------------------------------------
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                height: 24
                implicitWidth: stateLabel.implicitWidth + 20
                radius: 12
                color: mirrorSession.isRunning ? "#1A3828" : (deviceManager.hasDevice ? "#1E2A38" : "#381E1E")
                border.width: 1
                border.color: mirrorSession.isRunning ? "#30D158" : (deviceManager.hasDevice ? "#0A84FF" : "#FF453A")

                Text {
                    id: stateLabel
                    anchors.centerIn: parent
                    text: mirrorSession.isRunning ? "● Duplicación activa" : (deviceManager.hasDevice ? "● Listo para duplicar" : "○ Esperando dispositivo")
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: mirrorSession.isRunning ? "#30D158" : (deviceManager.hasDevice ? "#0A84FF" : "#FF453A")
                }
            }

            // -----------------------------------------------------------------
            // Primary action
            // -----------------------------------------------------------------
            Rectangle {
                id: actionButton
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 220
                Layout.preferredHeight: 42
                radius: 21
                enabled: deviceManager.hasDevice || mirrorSession.isRunning
                color: !actionButton.enabled ? "#3A3A3C" : (mirrorSession.isRunning ? "#FF453A" : "#0A84FF")

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: mirrorSession.isRunning ? "Detener Duplicación" : "Duplicar Pantalla (scrcpy)"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: actionButton.enabled ? "#FFFFFF" : "#8E8E93"
                }

                TapHandler {
                    enabled: actionButton.enabled
                    onTapped: {
                        if (mirrorSession.isRunning) {
                            mirrorSession.stopMirroring();
                        } else {
                            mirrorSession.startMirroring(
                                deviceManager.selectedDevice.serial,
                                deviceManager.selectedDevice.name
                            );
                        }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------------------
    // Stream parameters (PipeWire / scrcpy)
    // ---------------------------------------------------------------------
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        anchors.bottomMargin: 56
        height: 46
        radius: 14
        color: "#1C1C22"
        border.width: 1
        border.color: "#2C2C2E"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "🔊 " + (mirrorSession.audioEnabled ? "Audio → PipeWire" : "Audio desactivado")
                font.pixelSize: 11
                color: "#E5E5EA"
                elide: Text.ElideRight
            }

            Text {
                text: "•"
                font.pixelSize: 11
                color: "#8E8E93"
            }

            Text {
                text: mirrorSession.maxFps + " fps"
                font.pixelSize: 11
                color: "#E5E5EA"
            }

            Text {
                text: "•"
                font.pixelSize: 11
                color: "#8E8E93"
            }

            Text {
                text: mirrorSession.bitrateMbps + " Mbps"
                font.pixelSize: 11
                color: "#E5E5EA"
            }
        }
    }
}

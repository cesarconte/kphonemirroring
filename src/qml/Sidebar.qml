/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-FileCopyrightText: 2026 CachyOS UI contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Golden Gate edge-to-edge sidebar for the Phone Mirroring window.
 *
 * It hosts the *host side* of the application (device discovery and session
 * control). The mirrored device keeps its own navigation inside the device
 * screen, so there is zero redundancy between both layers.
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CachyOS.UI

ColumnLayout {
    id: root

    anchors.leftMargin: 12
    anchors.rightMargin: 12
    anchors.bottomMargin: 12
    spacing: CachyTheme.spacingSmall

    // =========================================================================
    // Brand block
    // =========================================================================
    ColumnLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.topMargin: 10
        spacing: 1

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: "iPhone / Android Mirroring"
            font.pixelSize: 13
            font.weight: Font.Bold
            color: CachyPalette.text
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: CachyTheme.distroName
            font.pixelSize: 11
            color: CachyPalette.textSecondary
            elide: Text.ElideRight
        }
    }

    Item { Layout.preferredHeight: 4 }

    // =========================================================================
    // Devices
    // =========================================================================
    Text {
        text: "DISPOSITIVOS"
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: CachyPalette.textMuted
        Layout.leftMargin: 6
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        spacing: 3

        Repeater {
            model: deviceManager.devices

            CachySidebarItem {
                id: deviceSidebarItem
                required property var modelData

                readonly property bool isSelected: deviceManager.selectedDevice.serial === deviceSidebarItem.modelData.serial

                text: deviceSidebarItem.modelData.name || deviceSidebarItem.modelData.model || deviceSidebarItem.modelData.serial
                iconName: "smartphone"
                iconColor: "#30D158"
                squircleIconBadge: true
                accentSelected: true
                badgeText: deviceSidebarItem.modelData.batteryLevel >= 0 ? (deviceSidebarItem.modelData.batteryLevel + "%") : ""
                selected: isSelected

                onClicked: deviceManager.selectDevice(deviceSidebarItem.modelData.serial)
            }
        }

        // Empty state
        Rectangle {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            implicitHeight: emptyStateCol.implicitHeight + 20
            radius: CachyTheme.radiusMedium
            color: CachyPalette.cardBackground
            border.width: 1
            border.color: CachyPalette.specularBorder
            visible: deviceManager.devices.length === 0

            ColumnLayout {
                id: emptyStateCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: "Sin dispositivos"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: CachyPalette.text
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: "Conecta un teléfono por USB o activa el modo Wi-Fi ADB."
                    font.pixelSize: 11
                    color: CachyPalette.textSecondary
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Item { Layout.fillHeight: true }

    // =========================================================================
    // Session status card
    // =========================================================================
    Rectangle {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        implicitHeight: sessionCol.implicitHeight + 20
        radius: CachyTheme.radiusMedium
        color: CachyPalette.cardBackground
        border.width: 1
        border.color: CachyPalette.specularBorder

        ColumnLayout {
            id: sessionCol
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: 4
                    color: mirrorSession.isRunning ? "#30D158" : CachyPalette.textMuted
                }

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: mirrorSession.isRunning ? "Duplicación activa" : "Sesión inactiva"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: CachyPalette.text
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: mirrorSession.isRunning
                    ? (deviceManager.selectedDevice.name + " • " + deviceManager.selectedDevice.osType + " " + deviceManager.selectedDevice.androidVersion)
                    : "scrcpy listo para conectar"
                font.pixelSize: 11
                color: CachyPalette.textSecondary
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: "Audio PipeWire • " + mirrorSession.maxFps + " fps • " + mirrorSession.bitrateMbps + " Mbps"
                font.pixelSize: 10
                color: CachyPalette.textMuted
                wrapMode: Text.WordWrap
            }
        }
    }

    // =========================================================================
    // Session actions
    // =========================================================================
    CachyButton {
        Layout.fillWidth: true
        text: mirrorSession.isRunning ? "Detener Duplicación" : "Duplicar Pantalla"
        pillStyle: true
        primary: !mirrorSession.isRunning
        destructive: mirrorSession.isRunning
        enabled: mirrorSession.isRunning || deviceManager.hasDevice
        onClicked: {
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

    CachyButton {
        Layout.fillWidth: true
        text: "Conectar por Wi-Fi"
        pillStyle: true
        flat: true
        enabled: deviceManager.hasDevice
        onClicked: deviceManager.enableWirelessMode()
    }

    // Platform identification: distribution and desktop shell generation.
    Text {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        Layout.topMargin: 2
        text: CachyTheme.desktopShell
        font.pixelSize: 10
        color: CachyPalette.textMuted
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }
}

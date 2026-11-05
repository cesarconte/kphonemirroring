import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic as QQC2
import QtQuick.Layouts

Window {
    id: window
    width: 440
    height: 720
    minimumWidth: 400
    minimumHeight: 640
    visible: true
    title: "Phone Mirroring"
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint

    // Settings state
    property bool optTurnScreenOff: true
    property bool optStayAwake: true
    property bool optAudio: true
    property int optMaxFps: 60
    property int optBitrate: 16

    // Root Card with Apple Glass & Border
    Rectangle {
        id: rootCard
        anchors.fill: parent
        anchors.margins: 10
        radius: 20
        color: "#E61E1E22"
        border.color: "#383842"
        border.width: 1
        clip: true

        // Drag Handler to move frameless window
        DragHandler {
            target: window
            grabPermissions: TapHandler.CanTakeOverFromItems | TapHandler.Approvals
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // --- HEADER: Traffic lights + Title + Battery Badge ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // macOS Traffic Lights
                Row {
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: "#FF5F56"
                        border.color: "#E0443E"
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.close()
                        }
                    }
                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: "#FFBD2E"
                        border.color: "#DEA123"
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.showMinimized()
                        }
                    }
                    Rectangle {
                        width: 12
                        height: 12
                        radius: 6
                        color: "#27C93F"
                        border.color: "#1AAB29"
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (window.visibility === Window.Maximized) {
                                    window.showNormal()
                                } else {
                                    window.showMaximized()
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // App Title
                Text {
                    text: "Phone Mirroring"
                    font.family: "SF Pro Text, -apple-system, Cantarell, sans-serif"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: "#E5E5EA"
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // Battery / Device Badge
                Rectangle {
                    visible: deviceManager.hasDevice
                    height: 24
                    implicitWidth: badgeRow.implicitWidth + 14
                    radius: 12
                    color: "#2C2C2E"
                    border.color: "#3A3A3C"
                    Layout.alignment: Qt.AlignVCenter

                    RowLayout {
                        id: badgeRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: (deviceManager.selectedDevice.isWireless ? "📶" : "⚡")
                            font.pixelSize: 11
                        }

                        Text {
                            text: (deviceManager.selectedDevice.batteryLevel >= 0) ? (deviceManager.selectedDevice.batteryLevel + "%") : "--%"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: deviceManager.selectedDevice.batteryLevel <= 20 ? "#FF453A" : "#30D158"
                        }
                    }
                }
            }

            // --- SMARTPHONE CHASSIS PREVIEW ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 330
                radius: 36
                color: "#151518"
                border.color: mirrorSession.isRunning ? "#0A84FF" : "#3A3A3C"
                border.width: mirrorSession.isRunning ? 2 : 1
                clip: true

                // Screen Background
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 30
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#1C1C1E" }
                        GradientStop { position: 0.5; color: "#24242A" }
                        GradientStop { position: 1.0; color: "#16161A" }
                    }

                    // Punch-Hole Camera cutout
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        width: 14
                        height: 14
                        radius: 7
                        color: "#08080A"
                        border.color: "#1E1E24"
                        border.width: 1.5

                        Rectangle {
                            anchors.centerIn: parent
                            width: 5
                            height: 5
                            radius: 2.5
                            color: "#0A84FF"
                            opacity: 0.6
                        }
                    }

                    // Screen Content / Status
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12
                        width: parent.width - 40

                        // Device Name / Status
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: deviceManager.hasDevice ? deviceManager.selectedDevice.name : "Sin dispositivo conectado"
                            font.pixelSize: 17
                            font.weight: Font.Bold
                            color: "#FFFFFF"
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: deviceManager.hasDevice ?
                                  (deviceManager.selectedDevice.osType + " • Android " + deviceManager.selectedDevice.androidVersion + " (" + (deviceManager.selectedDevice.isWireless ? "Wi-Fi" : "USB") + ")") :
                                  "Conecta tu teléfono por USB o Wi-Fi"
                            font.pixelSize: 12
                            color: "#8E8E93"
                        }

                        // State Indicator Pill
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            height: 24
                            implicitWidth: stateText.implicitWidth + 20
                            radius: 12
                            color: mirrorSession.isRunning ? "#1A3828" : (deviceManager.hasDevice ? "#1E2A38" : "#381E1E")
                            border.color: mirrorSession.isRunning ? "#30D158" : (deviceManager.hasDevice ? "#0A84FF" : "#FF453A")
                            border.width: 1

                            Text {
                                id: stateText
                                anchors.centerIn: parent
                                text: mirrorSession.isRunning ? "● Duplicación activa" : (deviceManager.hasDevice ? "● Listo para duplicar" : "○ Esperando dispositivo")
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: mirrorSession.isRunning ? "#30D158" : (deviceManager.hasDevice ? "#0A84FF" : "#FF453A")
                            }
                        }

                        Item { height: 8 }

                        // Primary Action Button (Start / Stop)
                        Rectangle {
                            id: actionBtn
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 220
                            Layout.preferredHeight: 44
                            radius: 22
                            enabled: deviceManager.hasDevice

                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: !actionBtn.enabled ? "#3A3A3C" : (mirrorSession.isRunning ? "#FF453A" : "#0A84FF")
                                }
                                GradientStop {
                                    position: 1.0
                                    color: !actionBtn.enabled ? "#2C2C2E" : (mirrorSession.isRunning ? "#D70015" : "#0066CC")
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: mirrorSession.isRunning ? "Detener Duplicación" : "Duplicar Pantalla"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: actionBtn.enabled ? "#FFFFFF" : "#636366"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: actionBtn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (mirrorSession.isRunning) {
                                        mirrorSession.stopMirroring()
                                    } else {
                                        mirrorSession.startMirroring(
                                            deviceManager.selectedDevice.serial,
                                            window.optTurnScreenOff,
                                            window.optStayAwake,
                                            window.optAudio,
                                            window.optMaxFps,
                                            window.optBitrate,
                                            deviceManager.selectedDevice.name
                                        )
                                    }
                                }
                            }
                        }
                    }

                    // Home swipe indicator at bottom of smartphone screen
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        width: 80
                        height: 4
                        radius: 2
                        color: "#FFFFFF"
                        opacity: 0.4
                    }
                }
            }

            // --- SEQUOIA COMPANION TOOLBAR ---
            SequoiaToolbar {
                Layout.fillWidth: true
                visible: mirrorSession.isRunning
            }

            // --- CONTROLS / OPTIONS CARD ---
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: "#18181B"
                border.color: "#2C2C2E"
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    // Toggle: Turn Screen Off
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Apagar pantalla física del móvil"
                            font.pixelSize: 12
                            color: "#E5E5EA"
                            Layout.fillWidth: true
                        }
                        QQC2.Switch {
                            checked: window.optTurnScreenOff
                            onToggled: window.optTurnScreenOff = checked
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#252528" }

                    // Toggle: Audio
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Transmitir audio por PipeWire al PC"
                            font.pixelSize: 12
                            color: "#E5E5EA"
                            Layout.fillWidth: true
                        }
                        QQC2.Switch {
                            checked: window.optAudio
                            onToggled: window.optAudio = checked
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#252528" }

                    // Mode switch: USB vs Wi-Fi Wireless
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Modo inalámbrico Wi-Fi:"
                            font.pixelSize: 12
                            color: "#E5E5EA"
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            height: 28
                            implicitWidth: wifiBtnText.implicitWidth + 18
                            radius: 14
                            color: "#2C2C2E"
                            border.color: "#3A3A3C"

                            Text {
                                id: wifiBtnText
                                anchors.centerIn: parent
                                text: "📶 Conectar por Wi-Fi"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: "#0A84FF"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: deviceManager.enableWirelessMode()
                            }
                        }
                    }

                    Text {
                        visible: deviceManager.statusMessage.length > 0
                        text: deviceManager.statusMessage
                        font.pixelSize: 11
                        color: "#30D158"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Screenshot notification toast
        Rectangle {
            id: toast
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            height: 36
            implicitWidth: toastText.implicitWidth + 24
            radius: 18
            color: "#D91C1C1E"
            border.color: "#30D158"
            border.width: 1
            opacity: 0

            Text {
                id: toastText
                anchors.centerIn: parent
                text: "📸 Captura guardada en Imágenes"
                font.pixelSize: 12
                color: "#FFFFFF"
            }

            NumberAnimation on opacity {
                id: toastAnim
                from: 1.0
                to: 0.0
                duration: 2500
                running: false
            }
        }
    }

    Connections {
        target: mirrorSession
        function onScreenshotTaken(path) {
            toast.opacity = 1.0
            toastAnim.restart()
        }
    }
}

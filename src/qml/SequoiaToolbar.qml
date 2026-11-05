import QtQuick
import QtQuick.Controls.Basic as QQC2
import QtQuick.Layouts

Rectangle {
    id: root
    height: 48
    radius: 24
    color: "#D91C1C1E"
    border.color: "#3A3A3C"
    border.width: 1

    RowLayout {
        anchors.centerIn: parent
        spacing: 6

        // Home Button
        ToolPillButton {
            iconText: "􀎟" // SF / Unicode fallback
            label: "Inicio"
            fallbackSymbol: "🏠"
            tooltipText: "Pantalla de inicio (Home)"
            onClicked: mirrorSession.sendHome()
        }

        // App Switcher
        ToolPillButton {
            iconText: "􀏧"
            label: "Multitarea"
            fallbackSymbol: "🗂️"
            tooltipText: "Aplicaciones recientes (App Switcher)"
            onClicked: mirrorSession.sendAppSwitcher()
        }

        // Lock / Screen Off
        ToolPillButton {
            iconText: "􀎠"
            label: "Bloquear"
            fallbackSymbol: "🔒"
            tooltipText: "Bloquear / Apagar pantalla"
            onClicked: mirrorSession.sendLock()
        }

        Rectangle {
            width: 1
            height: 20
            color: "#3A3A3C"
            Layout.alignment: Qt.AlignVCenter
        }

        // Notifications
        ToolPillButton {
            iconText: "􀝖"
            label: "Avisos"
            fallbackSymbol: "🔔"
            tooltipText: "Panel de notificaciones"
            onClicked: mirrorSession.sendExpandNotifications()
        }

        // Quick Settings
        ToolPillButton {
            iconText: "􀍟"
            label: "Ajustes"
            fallbackSymbol: "⚙️"
            tooltipText: "Ajustes rápidos de Android"
            onClicked: mirrorSession.sendExpandSettings()
        }

        // Screenshot
        ToolPillButton {
            iconText: "􀌞"
            label: "Captura"
            fallbackSymbol: "📸"
            tooltipText: "Capturar pantalla y guardar en Imágenes"
            onClicked: mirrorSession.takeScreenshot()
        }

        Rectangle {
            width: 1
            height: 20
            color: "#3A3A3C"
            Layout.alignment: Qt.AlignVCenter
        }

        // Vol -
        ToolPillButton {
            iconText: "􀊦"
            label: "Vol -"
            fallbackSymbol: "🔉"
            tooltipText: "Bajar volumen"
            onClicked: mirrorSession.sendVolumeDown()
        }

        // Vol +
        ToolPillButton {
            iconText: "􀊨"
            label: "Vol +"
            fallbackSymbol: "🔊"
            tooltipText: "Subir volumen"
            onClicked: mirrorSession.sendVolumeUp()
        }
    }

    component ToolPillButton: Rectangle {
        id: btn
        property string iconText: ""
        property string fallbackSymbol: ""
        property string label: ""
        property string tooltipText: ""
        signal clicked()

        implicitWidth: 36
        implicitHeight: 36
        radius: 18
        color: mouseArea.containsPress ? "#48484A" : (mouseArea.containsMouse ? "#3A3A3C" : "transparent")

        Text {
            anchors.centerIn: parent
            text: btn.fallbackSymbol
            font.pixelSize: 15
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }

        QQC2.ToolTip.visible: mouseArea.containsMouse && btn.tooltipText.length > 0
        QQC2.ToolTip.text: btn.tooltipText
        QQC2.ToolTip.delay: 400
    }
}

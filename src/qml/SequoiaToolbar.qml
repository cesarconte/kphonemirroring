/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later

    Host-side quick actions for the scrcpy session. It lives *outside* of the
    device screen (it belongs to the host application, not to the phone), so it
    is rendered with the canonical Liquid Glass tokens of `CachyOS.UI`.
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CachyOS.UI

Rectangle {
    id: root

    implicitHeight: 44
    radius: CachyTheme.radiusLarge
    color: CachyTheme.cardBackground
    border.width: 1
    border.color: CachyTheme.specularBorder

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 4

        Item { Layout.fillWidth: true }

        Repeater {
            model: [
                { glyph: "🏠", label: "Inicio", tip: "Pantalla de inicio (Home)", action: "home" },
                { glyph: "🗂️", label: "Multitarea", tip: "Aplicaciones recientes (App Switcher)", action: "switcher" },
                { glyph: "🔒", label: "Bloquear", tip: "Bloquear / apagar la pantalla", action: "lock" },
                { glyph: "🔔", label: "Avisos", tip: "Panel de notificaciones", action: "notifications" },
                { glyph: "⚙️", label: "Ajustes", tip: "Ajustes rápidos de Android", action: "settings" },
                { glyph: "📸", label: "Captura", tip: "Capturar pantalla y guardar en Imágenes", action: "screenshot" },
                { glyph: "🔉", label: "Vol −", tip: "Bajar volumen", action: "volDown" },
                { glyph: "🔊", label: "Vol +", tip: "Subir volumen", action: "volUp" }
            ]

            CachyToolbarButton {
                required property var modelData

                text: modelData.glyph
                tooltipText: modelData.tip

                onClicked: {
                    switch (modelData.action) {
                    case "home": mirrorSession.sendHome(); break;
                    case "switcher": mirrorSession.sendAppSwitcher(); break;
                    case "lock": mirrorSession.sendLock(); break;
                    case "notifications": mirrorSession.sendExpandNotifications(); break;
                    case "settings": mirrorSession.sendExpandSettings(); break;
                    case "screenshot": mirrorSession.takeScreenshot(); break;
                    case "volDown": mirrorSession.sendVolumeDown(); break;
                    case "volUp": mirrorSession.sendVolumeUp(); break;
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }
    }
}

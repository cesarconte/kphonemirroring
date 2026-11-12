/*
    SPDX-FileCopyrightText: 2026 Cesar
    SPDX-License-Identifier: GPL-3.0-or-later

    macOS 27 "Golden Gate" iPhone/Android Mirroring — KDE Plasma 6 (Wayland).

    Design contract (cachyos-ui / DESIGN_SYSTEM.md):
      * Liquid Glass frame: NO opaque `backgroundColor` override, the window keeps
        the translucent `CachyTheme.windowBackground` + KWin blur + gloss sheen
        + 1px specular rim implemented by `CachyWindow`.
      * 44px title bar with the canonical hard 1px divider (`showTitleBarDivider`).
      * 18px canonical perimeter margin (`contentPadded`).
      * Unified 20px squircle corner radius (`CachyTheme.radiusWindow`).
      * Edge-to-edge sidebar with colorful icons and bold selection.
      * Every colour/metric comes from `CachyTheme` — zero hardcoded chrome.
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import CachyOS.UI

CachyWindow {
    id: root

    // =========================================================================
    // 0. GOLDEN GATE CANONICAL GEOMETRY
    // =========================================================================
    title: "iPhone & Android Mirroring"
    width: 980
    height: 680
    minimumWidth: 620
    minimumHeight: 520
    visible: true

    showTrafficLights: true
    showTitleBarDivider: true          // hard 1px divider under the 44px header
    showWindowFrame: true              // Liquid Glass: KWin blur + gloss + specular rim
    resizable: true
    cornerRadius: CachyTheme.radiusWindow
    contentPadded: true                // canonical 18px perimeter margin
    sidebarWidth: 232

    // NOTE: `backgroundColor` is intentionally NOT overridden here. Setting an
    // opaque colour would cancel the Liquid Glass translucency, the KWin blur
    // region and the gloss sheen gradient drawn by `CachyWindow`.

    // =========================================================================
    // 1. APPLICATION STATE
    // =========================================================================
    property bool showSidebar: true
    sidebarVisible: root.showSidebar

    property string activeTab: "today"
    property bool preferencesVisible: false
    property bool programmaticResize: false

    readonly property int viewportWidth: root.width - (root.showSidebar ? root.sidebarWidth : 0)
    readonly property int viewportHeight: root.height - CachyTheme.titleBarHeight - (CachyTheme.marginWindow * 2)

    // =========================================================================
    // 2. KEYBOARD SHORTCUTS (macOS 27 iPhone Mirroring parity)
    // =========================================================================
    Shortcut {
        sequence: "Ctrl+1"
        onActivated: {
            root.activeTab = "today";
            mirrorSession.returnToHomeScreen();
        }
    }
    Shortcut {
        sequence: "Ctrl+2"
        onActivated: mirrorSession.sendAppSwitcher()
    }
    Shortcut {
        sequence: "Ctrl+3"
        onActivated: mirrorSession.openSpotlight()
    }
    Shortcut {
        sequence: "Ctrl+4"
        onActivated: mirrorSession.openControlCenter()
    }
    Shortcut {
        sequence: "Ctrl+,"
        onActivated: root.preferencesVisible = !root.preferencesVisible
    }

    // =========================================================================
    // 3. BACKEND WIRING
    // =========================================================================
    Connections {
        target: mirrorSession
        function onRequestWindowResize(targetW, targetH) {
            // The backend reasons in *content* pixels; the sidebar is host chrome.
            root.programmaticResize = true;
            root.width = targetW + (root.showSidebar ? root.sidebarWidth : 0);
            root.height = targetH;
            resizeResetTimer.restart();
        }
        function onScreenshotTaken(path) {
            toast.opacity = 1.0;
            toastAnim.restart();
        }
    }

    Timer {
        id: resizeResetTimer
        interval: 250
        onTriggered: root.programmaticResize = false
    }

    onWidthChanged: {
        if (!root.programmaticResize && mirrorSession.currentAppId !== "home") {
            mirrorSession.saveAppWindowSize(mirrorSession.currentAppId, root.viewportWidth, root.viewportHeight);
        }
    }
    onHeightChanged: {
        if (!root.programmaticResize && mirrorSession.currentAppId !== "home") {
            mirrorSession.saveAppWindowSize(mirrorSession.currentAppId, root.viewportWidth, root.viewportHeight);
        }
    }

    // =========================================================================
    // 4. HEADER LEADING — Sidebar toggle + "View" menu pill
    // =========================================================================
    headerLeading: [
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Sidebar visibility toggle (macOS 27 collapsible sidebar)
            CachyToolbarButton {
                text: root.showSidebar ? "◧" : "◨"
                tooltipText: root.showSidebar ? "Ocultar la barra lateral" : "Mostrar la barra lateral"
                onClicked: root.showSidebar = !root.showSidebar
            }

            Rectangle {
                id: viewMenuPill
                height: 28
                implicitWidth: viewMenuLabel.implicitWidth + 18
                radius: 14
                color: viewMenuHover.hovered ? CachyTheme.cardBackgroundHover : CachyTheme.surfacePill
                border.width: 1
                border.color: CachyTheme.specularBorder

                Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }

                HoverHandler { id: viewMenuHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: goldenGateViewMenu.popup(viewMenuPill, 0, viewMenuPill.height + 4) }

                Text {
                    id: viewMenuLabel
                    anchors.centerIn: parent
                    text: "View ▾"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    color: CachyTheme.textPrimary
                }

                QQC2.Menu {
                    id: goldenGateViewMenu

                    QQC2.MenuItem {
                        text: "Home Screen\tCtrl+1"
                        onTriggered: {
                            root.activeTab = "today";
                            mirrorSession.returnToHomeScreen();
                        }
                    }
                    QQC2.MenuItem {
                        text: "App Switcher\tCtrl+2"
                        onTriggered: mirrorSession.sendAppSwitcher()
                    }
                    QQC2.MenuItem {
                        text: "Spotlight\tCtrl+3"
                        onTriggered: mirrorSession.openSpotlight()
                    }
                    QQC2.MenuItem {
                        text: "Control Center\tCtrl+4"
                        onTriggered: mirrorSession.openControlCenter()
                    }

                    QQC2.MenuSeparator {}

                    QQC2.MenuItem {
                        text: "Compact Portrait Size (440×700)"
                        onTriggered: mirrorSession.returnToHomeScreen()
                    }
                    QQC2.MenuItem {
                        text: "Multi-Column Expanded Size (780×620)"
                        onTriggered: mirrorSession.openApp("today", "Today")
                    }
                    QQC2.MenuItem {
                        text: "Preferencias…\tCtrl+,"
                        onTriggered: root.preferencesVisible = !root.preferencesVisible
                    }
                }
            }
        }
    ]

    // =========================================================================
    // 5. HEADER TRAILING — Golden Gate bezel cluster + Preferences (far right)
    // =========================================================================
    headerActions: [
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            BezelActionButton {
                iconKind: "home"
                tooltipText: "Home Screen (Ctrl+1 — restaura el tamaño vertical)"
                onClicked: {
                    root.activeTab = "today";
                    mirrorSession.returnToHomeScreen();
                }
            }

            BezelActionButton {
                iconKind: "switcher"
                tooltipText: "App Switcher (Ctrl+2)"
                onClicked: mirrorSession.sendAppSwitcher()
            }

            BezelActionButton {
                iconKind: "controlCenter"
                active: mirrorSession.controlCenterVisible
                tooltipText: "Control Center (Ctrl+4)"
                onClicked: {
                    root.preferencesVisible = false;
                    mirrorSession.openControlCenter();
                }
            }

            // Golden Gate hard separator between the bezel cluster and the
            // preferences gear (always the last element of the header).
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignVCenter
                color: CachyTheme.hardDividerColor
            }

            CachyToolbarButton {
                text: "⚙"
                tooltipText: "Preferencias de duplicación (Ctrl+,)"
                onClicked: {
                    mirrorSession.controlCenterVisible = false;
                    root.preferencesVisible = !root.preferencesVisible;
                }
            }
        }
    ]

    // =========================================================================
    // 6. EDGE-TO-EDGE GOLDEN GATE SIDEBAR
    // =========================================================================
    sidebarHeaderActions: [
        Row {
            spacing: 6
            anchors.verticalCenter: parent.verticalCenter

            CachyToolbarButton {
                text: "↻"
                tooltipText: "Buscar dispositivos conectados (ADB)"
                onClicked: deviceManager.refresh()
            }
        }
    ]

    sidebar: [
        Sidebar {
            anchors.fill: parent
        }
    ]

    // =========================================================================
    // 7. CONTENT AREA — Device chassis + host-side quick actions
    // =========================================================================
    contentData: [
        ColumnLayout {
            anchors.fill: parent
            spacing: CachyTheme.spacingMedium

            // Device chassis hosting the mirrored screen
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0

                PhoneScreen {
                    anchors.fill: parent
                    activeTab: root.activeTab
                }
            }

            // Host-side scrcpy quick actions (outside of the device screen)
            SequoiaToolbar {
                Layout.fillWidth: true
                visible: root.activeTab === "device"
            }
        },

        // Modal scrim: dismisses the Control Center / Preferences sheets
        Rectangle {
            anchors.fill: parent
            z: 10
            color: Qt.rgba(0, 0, 0, CachyTheme.isDark ? 0.32 : 0.16)
            visible: mirrorSession.controlCenterVisible || root.preferencesVisible

            Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }

            TapHandler {
                onTapped: {
                    mirrorSession.controlCenterVisible = false;
                    root.preferencesVisible = false;
                }
            }
        }
    ]

    // =========================================================================
    // 8. WINDOW-LEVEL GLASS OVERLAYS (Control Center + Preferences)
    // =========================================================================
    overlay: [
        ControlCenterSheet {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: CachyTheme.titleBarHeight + 4
            anchors.rightMargin: CachyTheme.marginWindow
            visible: mirrorSession.controlCenterVisible
            onDismissRequested: mirrorSession.controlCenterVisible = false
        },

        PreferencesSheet {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: CachyTheme.titleBarHeight + 4
            anchors.rightMargin: CachyTheme.marginWindow
            visible: root.preferencesVisible
            onDismissRequested: root.preferencesVisible = false
        },

        // Screenshot toast
        Rectangle {
            id: toast
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: CachyTheme.marginWindow
            height: 34
            implicitWidth: toastText.implicitWidth + 24
            radius: 17
            color: CachyTheme.cardBackground
            border.width: 1
            border.color: CachyTheme.specularBorder
            opacity: 0
            z: 5

            Text {
                id: toastText
                anchors.centerIn: parent
                text: "Captura guardada en Imágenes"
                font.pixelSize: 12
                color: CachyTheme.textPrimary
            }

            NumberAnimation on opacity {
                id: toastAnim
                from: 1.0
                to: 0.0
                duration: 2500
                running: false
            }
        }
    ]
}

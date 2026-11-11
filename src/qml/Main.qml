import QtQuick
import QtQuick.Window
import QtQuick.Controls.Basic as QQC2
import QtQuick.Layouts
import CachyOS.UI

CachyWindow {
    id: window
    width: 780
    height: 620
    minimumWidth: 400
    minimumHeight: 520
    visible: true
    title: "iPhone & Android Mirroring"

    showTrafficLights: true
    showTitleBarDivider: false
    showWindowFrame: true
    resizable: true
    cornerRadius: CachyTheme.radiusWindow
    backgroundColor: "#1F2026"

    // Settings state for scrcpy session
    property bool optTurnScreenOff: true
    property bool optStayAwake: true
    property bool optAudio: true
    property int optMaxFps: 60
    property int optBitrate: 16

    // Active tab inside the mirrored canvas: "today", "apps", "device"
    property string activeTab: "today"
    readonly property bool isWideMultiColumn: window.width >= 600
    property bool programmaticResize: false

    // Keyboard Shortcuts from macOS 27 Golden Gate iPhone Mirroring
    Shortcut {
        sequence: "Ctrl+1"
        onActivated: {
            window.activeTab = "today";
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

    Connections {
        target: mirrorSession
        function onRequestWindowResize(targetW, targetH) {
            window.programmaticResize = true;
            window.width = targetW;
            window.height = targetH;
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
        onTriggered: window.programmaticResize = false
    }

    onWidthChanged: {
        if (!window.programmaticResize && mirrorSession.currentAppId !== "home") {
            mirrorSession.saveAppWindowSize(mirrorSession.currentAppId, window.width, window.height);
        }
    }
    onHeightChanged: {
        if (!window.programmaticResize && mirrorSession.currentAppId !== "home") {
            mirrorSession.saveAppWindowSize(mirrorSession.currentAppId, window.width, window.height);
        }
    }

    // Suppress default centered title so the dark bezel matches 13_iphone_mirroring.png
    headerCenter: [
        Item { width: 1; height: 1 }
    ]

    // =========================================================================
    // 1. HEADER LEADING: "View" Menu (with Cmd+4 Control Center) + Device Pill
    // =========================================================================
    headerLeading: [
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                id: viewMenuPill
                height: 26
                implicitWidth: viewMenuLabel.implicitWidth + 18
                radius: 13
                color: viewMenuHover.hovered ? "#343640" : "#282A32"
                border.width: 1
                border.color: "#3E404C"

                HoverHandler { id: viewMenuHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: goldenGateViewMenu.popup(0, viewMenuPill.height + 4) }

                Text {
                    id: viewMenuLabel
                    anchors.centerIn: parent
                    text: "View ▾"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: "#E5E5EA"
                }

                QQC2.Menu {
                    id: goldenGateViewMenu

                    QQC2.MenuItem {
                        text: "Home Screen\t⌘1"
                        onTriggered: {
                            window.activeTab = "today";
                            mirrorSession.returnToHomeScreen();
                        }
                    }
                    QQC2.MenuItem {
                        text: "App Switcher\t⌘2"
                        onTriggered: mirrorSession.sendAppSwitcher()
                    }
                    QQC2.MenuItem {
                        text: "Spotlight\t⌘3"
                        onTriggered: mirrorSession.openSpotlight()
                    }
                    QQC2.MenuItem {
                        text: "Control Center\t⌘4"
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
                }
            }

            // Connected Device Status Pill
            Rectangle {
                height: 24
                implicitWidth: Math.min(220, devStatusRow.implicitWidth + 16)
                radius: 12
                color: "#282A32"
                border.width: 1
                border.color: mirrorSession.isRunning ? "#30D158" : "#3E404C"

                RowLayout {
                    id: devStatusRow
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 5

                    Rectangle {
                        width: 7
                        height: 7
                        radius: 3.5
                        color: mirrorSession.isRunning ? "#30D158" : (deviceManager.hasDevice ? "#0A84FF" : "#8E8E93")
                    }

                    Text {
                        Layout.fillWidth: true
                        text: deviceManager.hasDevice
                            ? (deviceManager.selectedDevice.name + (deviceManager.selectedDevice.batteryLevel >= 0 ? " • " + deviceManager.selectedDevice.batteryLevel + "%" : ""))
                            : ( window.isWideMultiColumn ? "Golden Gate Resizable Mirroring" : "Mirroring" )
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: "#D1D1D6"
                        elide: Text.ElideRight
                    }
                }
            }
        }
    ]

    // =========================================================================
    // 2. HEADER ACTIONS: Exact 3 Top-Right Bezel Icons from 13_iphone_mirroring.png
    //    (Home Screen, App Switcher 2x2 Grid, Control Center Cmd+4)
    // =========================================================================
    headerActions: [
        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // 1. Home Screen Icon (Rectangle with Home Bar at bottom)
            Rectangle {
                width: 28
                height: 24
                radius: 6
                color: homeHdrHover.hovered ? "#343640" : "transparent"

                HoverHandler { id: homeHdrHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        window.activeTab = "today";
                        mirrorSession.returnToHomeScreen();
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 15
                    height: 11
                    radius: 2.5
                    color: "transparent"
                    border.width: 1.4
                    border.color: "#C7C7CC"

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1.5
                        width: 6
                        height: 1.4
                        radius: 0.7
                        color: "#C7C7CC"
                    }
                }

                QQC2.ToolTip.visible: homeHdrHover.hovered
                QQC2.ToolTip.text: "Home Screen (⌘1 — Restaura tamaño vertical)"
            }

            // 2. App Switcher Icon (2x2 Grid from 13_iphone_mirroring.png)
            Rectangle {
                width: 28
                height: 24
                radius: 6
                color: switcherHdrHover.hovered ? "#343640" : "transparent"

                HoverHandler { id: switcherHdrHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: mirrorSession.sendAppSwitcher() }

                Grid {
                    anchors.centerIn: parent
                    columns: 2
                    spacing: 2.5
                    Repeater {
                        model: 4
                        Rectangle {
                            width: 5
                            height: 5
                            radius: 1.2
                            color: "transparent"
                            border.width: 1.3
                            border.color: "#C7C7CC"
                        }
                    }
                }

                QQC2.ToolTip.visible: switcherHdrHover.hovered
                QQC2.ToolTip.text: "App Switcher (⌘2)"
            }

            // 3. Control Center Icon (⌘4 in macOS 27 Golden Gate)
            Rectangle {
                width: 28
                height: 24
                radius: 6
                color: mirrorSession.controlCenterVisible
                    ? "#0A84FF"
                    : (ccHdrHover.hovered ? "#343640" : "transparent")

                HoverHandler { id: ccHdrHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: mirrorSession.openControlCenter() }

                Column {
                    anchors.centerIn: parent
                    spacing: 2.5

                    Rectangle {
                        width: 14
                        height: 5
                        radius: 2.5
                        color: "transparent"
                        border.width: 1.2
                        border.color: mirrorSession.controlCenterVisible ? "#FFFFFF" : "#C7C7CC"
                        Rectangle {
                            width: 3.5; height: 3.5; radius: 1.75
                            anchors.right: parent.right; anchors.rightMargin: 1
                            anchors.verticalCenter: parent.verticalCenter
                            color: mirrorSession.controlCenterVisible ? "#FFFFFF" : "#C7C7CC"
                        }
                    }
                    Rectangle {
                        width: 14
                        height: 5
                        radius: 2.5
                        color: "transparent"
                        border.width: 1.2
                        border.color: mirrorSession.controlCenterVisible ? "#FFFFFF" : "#C7C7CC"
                        Rectangle {
                            width: 3.5; height: 3.5; radius: 1.75
                            anchors.left: parent.left; anchors.leftMargin: 1
                            anchors.verticalCenter: parent.verticalCenter
                            color: mirrorSession.controlCenterVisible ? "#FFFFFF" : "#C7C7CC"
                        }
                    }
                }

                QQC2.ToolTip.visible: ccHdrHover.hovered
                QQC2.ToolTip.text: "Control Center (⌘4 / Ctrl+4)"
            }
        }
    ]

    // =========================================================================
    // 3. INNER ROUNDED PHONE SCREEN CANVAS (13_iphone_mirroring.png)
    // =========================================================================
    contentData: [
        Item {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.bottomMargin: 8

            Rectangle {
                id: phoneScreenCanvas
                anchors.fill: parent
                radius: 16
                color: window.activeTab === "device" ? "#141418" : "#FFFFFF"
                clip: true

                // =============================================================
                // TAB A: MULTI-COLUMN RESIZABLE APP VIEW (13_iphone_mirroring.png)
                // =============================================================
                Flickable {
                    id: storeFlick
                    anchors.fill: parent
                    visible: window.activeTab !== "device"
                    contentWidth: width
                    contentHeight: storeCol.implicitHeight + 84
                    flickableDirection: Flickable.VerticalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    ColumnLayout {
                        id: storeCol
                        width: storeFlick.width - 40
                        x: 20
                        y: 16
                        spacing: 16

                        // Top Title Row: "Today" + Avatar Badge "14" (Exact match of 13_iphone_mirroring.png)
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: window.activeTab === "apps" ? "Apps & Mirroring" : "Today"
                                font.pixelSize: 28
                                font.weight: Font.Bold
                                color: "#111114"
                                elide: Text.ElideRight
                            }

                            // Green Avatar Circle with Red "14" Notification Badge
                            Item {
                                width: 36
                                height: 36

                                Rectangle {
                                    anchors.fill: parent
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

                                    TapHandler {
                                        onTapped: window.activeTab = "device"
                                    }
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

                        // Hero Featured Cards Grid (2 Columns when window is resized wide, 1 Column when narrow!)
                        GridLayout {
                            Layout.fillWidth: true
                            columns: window.isWideMultiColumn ? 2 : 1
                            columnSpacing: 16
                            rowSpacing: 16

                            // Card 1: "Ready, Aim...Flick!" (Left Hero Card in 13_iphone_mirroring.png)
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

                                // Decorative Hero Illustration Banner
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

                                    // Bottom Overlay Text + App Strip
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 16
                                        Layout.rightMargin: 16
                                        Layout.bottomMargin: 14
                                        spacing: 4

                                        Text {
                                            text: "INCREDIBLE INDIE"
                                            font.pixelSize: 10
                                            font.weight: Font.Bold
                                            color: "#D9FFFFFF"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "Ready, Aim...Flick!"
                                            font.pixelSize: 20
                                            font.weight: Font.Bold
                                            color: "#FFFFFF"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "Tame a troubled treasure island in this roguelike indie gem."
                                            font.pixelSize: 11
                                            color: "#D9FFFFFF"
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Item { height: 6 }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            Rectangle {
                                                width: 34; height: 34; radius: 8
                                                color: "#2E1F3B"
                                                Text { anchors.centerIn: parent; text: "🎯"; font.pixelSize: 18 }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                Text {
                                                    text: "Flick Shot Rogues"
                                                    font.pixelSize: 12
                                                    font.weight: Font.DemiBold
                                                    color: "#FFFFFF"
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                Text {
                                                    text: "Plan, Aim, Shoot!"
                                                    font.pixelSize: 10
                                                    color: "#CCFFFFFF"
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            Rectangle {
                                                width: 58; height: 26; radius: 13
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

                            // Card 2: "ChatGPT / Kity AI" (Right Hero Card in 13_iphone_mirroring.png)
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

                                        // Center Rounded White Icon Tile (Exact match of 13_iphone_mirroring.png)
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

                                    // Bottom App Strip
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 16
                                        Layout.rightMargin: 16
                                        Layout.bottomMargin: 14
                                        spacing: 10

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text {
                                                text: "ChatGPT"
                                                font.pixelSize: 13
                                                font.weight: Font.Bold
                                                color: "#FFFFFF"
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                            Text {
                                                text: "Your everyday AI assistant"
                                                font.pixelSize: 11
                                                color: "#CCCCCC"
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        Rectangle {
                                            width: 58; height: 26; radius: 13
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

                        // Bottom Section Card: "OUR FAVORITES / Essential iPhone Games" (13_iphone_mirroring.png)
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: favSectionCol.implicitHeight + 28
                            radius: 18
                            color: "#F5F5F7"
                            border.width: 1
                            border.color: "#E5E5EA"

                            ColumnLayout {
                                id: favSectionCol
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: "OUR FAVORITES"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: "#8E8E93"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: "Essential iPhone Games & Mirroring"
                                        font.pixelSize: 18
                                        font.weight: Font.Bold
                                        color: "#111114"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: window.isWideMultiColumn ? 2 : 1
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
                                            spacing: 10

                                            Rectangle {
                                                width: 42; height: 42; radius: 10
                                                color: "#FFFFFF"
                                                border.width: 1
                                                border.color: "#E5E5EA"
                                                Text { anchors.centerIn: parent; text: modelData.icon; font.pixelSize: 20 }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                Text {
                                                    text: modelData.title
                                                    font.pixelSize: 13
                                                    font.weight: Font.DemiBold
                                                    color: "#111114"
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                Text {
                                                    text: modelData.sub
                                                    font.pixelSize: 11
                                                    color: "#8E8E93"
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            Rectangle {
                                                width: 60; height: 26; radius: 13
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
                                                            window.activeTab = "device";
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

                // =============================================================
                // TAB B: LIVE HARDWARE MIRRORING & SCRCPY DEVICE PANEL
                // =============================================================
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    anchors.bottomMargin: 72
                    spacing: 14
                    visible: window.activeTab === "device"

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 24
                        color: "#1C1C22"
                        border.color: mirrorSession.isRunning ? "#0A84FF" : "#3A3A3C"
                        border.width: mirrorSession.isRunning ? 2 : 1

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: Math.min(360, parent.width - 32)
                            spacing: 12

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
                                elide: Text.ElideRight
                            }

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

                            Rectangle {
                                id: actionBtn
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 220
                                Layout.preferredHeight: 42
                                radius: 21
                                enabled: deviceManager.hasDevice
                                color: !actionBtn.enabled ? "#3A3A3C" : (mirrorSession.isRunning ? "#FF453A" : "#0A84FF")

                                Text {
                                    anchors.centerIn: parent
                                    text: mirrorSession.isRunning ? "Detener Duplicación" : "Duplicar Pantalla (scrcpy)"
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    color: actionBtn.enabled ? "#FFFFFF" : "#8E8E93"
                                }

                                TapHandler {
                                    enabled: actionBtn.enabled
                                    onTapped: {
                                        if (mirrorSession.isRunning) {
                                            mirrorSession.stopMirroring();
                                        } else {
                                            mirrorSession.startMirroring(
                                                deviceManager.selectedDevice.serial,
                                                window.optTurnScreenOff,
                                                window.optStayAwake,
                                                window.optAudio,
                                                window.optMaxFps,
                                                window.optBitrate,
                                                deviceManager.selectedDevice.name
                                            );
                                        }
                                    }
                                }
                            }
                        }
                    }

                    SequoiaToolbar {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: optsCol.implicitHeight + 24
                        radius: 14
                        color: "#1C1C22"
                        border.color: "#2C2C2E"
                        border.width: 1

                        ColumnLayout {
                            id: optsCol
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Apagar pantalla física del móvil"
                                    font.pixelSize: 12
                                    color: "#E5E5EA"
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                QQC2.Switch {
                                    checked: window.optTurnScreenOff
                                    onToggled: window.optTurnScreenOff = checked
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Transmitir audio por PipeWire al PC"
                                    font.pixelSize: 12
                                    color: "#E5E5EA"
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                QQC2.Switch {
                                    checked: window.optAudio
                                    onToggled: window.optAudio = checked
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Modo inalámbrico Wi-Fi ADB:"
                                    font.pixelSize: 12
                                    color: "#E5E5EA"
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Rectangle {
                                    height: 26
                                    implicitWidth: wifiBtnText.implicitWidth + 16
                                    radius: 13
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
                                    TapHandler { onTapped: deviceManager.enableWirelessMode() }
                                }
                            }
                        }
                    }
                }

                // =============================================================
                // FLOATING GOLDEN GATE BOTTOM TAB PILL (13_iphone_mirroring.png)
                // (Today | Games | Apps | Device | Search)
                // =============================================================
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    height: 36
                    implicitWidth: bottomTabRow.implicitWidth + 16
                    radius: 18
                    color: "#EBFFFFFF"
                    border.width: 1
                    border.color: "#D1D1D6"

                    RowLayout {
                        id: bottomTabRow
                        anchors.centerIn: parent
                        spacing: 4

                        Repeater {
                            model: [
                                { id: "today", label: "Today", icon: "📅" },
                                { id: "apps", label: "Apps", icon: "🚀" },
                                { id: "device", label: "Mirroring", icon: "📱" }
                            ]

                            Rectangle {
                                required property var modelData
                                readonly property bool isCurrent: window.activeTab === modelData.id
                                height: 28
                                implicitWidth: tabItemRow.implicitWidth + 16
                                radius: 14
                                color: isCurrent ? "#E5F1FF" : "transparent"

                                RowLayout {
                                    id: tabItemRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: modelData.icon
                                        font.pixelSize: 11
                                    }
                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 11
                                        font.weight: isCurrent ? Font.Bold : Font.Medium
                                        color: isCurrent ? "#007AFF" : "#3A3A3C"
                                    }
                                }

                                TapHandler {
                                    onTapped: window.activeTab = modelData.id
                                }
                            }
                        }

                        // Search Pill Button
                        Rectangle {
                            width: 28; height: 28; radius: 14
                            color: "#F2F2F7"
                            Text { anchors.centerIn: parent; text: "🔍"; font.pixelSize: 11 }
                            TapHandler { onTapped: mirrorSession.openSpotlight() }
                        }
                    }
                }

                // =============================================================
                // GOLDEN GATE CONTROL CENTER OVERLAY (Cmd+4 / Ctrl+4)
                // =============================================================
                Rectangle {
                    id: controlCenterDrawer
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 12
                    width: 260
                    implicitHeight: ccCol.implicitHeight + 24
                    radius: 20
                    color: "#EB1E1E24"
                    border.width: 1
                    border.color: "#484854"
                    visible: mirrorSession.controlCenterVisible
                    z: 200

                    ColumnLayout {
                        id: ccCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Control Center (⌘4)"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                color: "#FFFFFF"
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: "✕"
                                font.pixelSize: 12
                                color: "#8E8E93"
                                TapHandler { onTapped: mirrorSession.controlCenterVisible = false }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 8
                            rowSpacing: 8

                            Rectangle {
                                Layout.fillWidth: true; height: 44; radius: 12
                                color: window.optAudio ? "#0A84FF" : "#2C2C34"
                                Text {
                                    anchors.centerIn: parent
                                    text: "🔊 Audio PC"
                                    font.pixelSize: 11; font.weight: Font.DemiBold; color: "#FFFFFF"
                                }
                                TapHandler { onTapped: window.optAudio = !window.optAudio }
                            }

                            Rectangle {
                                Layout.fillWidth: true; height: 44; radius: 12
                                color: window.optTurnScreenOff ? "#30D158" : "#2C2C34"
                                Text {
                                    anchors.centerIn: parent
                                    text: "🌙 Pantalla Off"
                                    font.pixelSize: 11; font.weight: Font.DemiBold; color: "#FFFFFF"
                                }
                                TapHandler { onTapped: window.optTurnScreenOff = !window.optTurnScreenOff }
                            }

                            Rectangle {
                                Layout.fillWidth: true; height: 44; radius: 12
                                color: "#2C2C34"
                                Text {
                                    anchors.centerIn: parent
                                    text: "📸 Captura"
                                    font.pixelSize: 11; font.weight: Font.DemiBold; color: "#FFFFFF"
                                }
                                TapHandler { onTapped: mirrorSession.takeScreenshot() }
                            }

                            Rectangle {
                                Layout.fillWidth: true; height: 44; radius: 12
                                color: "#2C2C34"
                                Text {
                                    anchors.centerIn: parent
                                    text: "🔔 Avisos"
                                    font.pixelSize: 11; font.weight: Font.DemiBold; color: "#FFFFFF"
                                }
                                TapHandler { onTapped: mirrorSession.sendExpandNotifications() }
                            }
                        }
                    }
                }

                // Screenshot Toast
                Rectangle {
                    id: toast
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 56
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 34
                    implicitWidth: toastText.implicitWidth + 24
                    radius: 17
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
        }
    ]
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import ".."
import "../components"

Dialog {
    id: root
    title: "Preferences & Settings"
    width: 840
    height: 600
    modal: true
    anchors.centerIn: parent

    property int activeCategory: 1 // default to Themes & Appearance

    component StyledComboBox: ComboBox {
        id: cbRoot
        Layout.preferredWidth: 220
        Layout.preferredHeight: 28
        background: Rectangle {
            implicitWidth: 220
            implicitHeight: 28
            color: Theme.surfaceElevated
            border.color: cbRoot.activeFocus ? Theme.accent : Theme.panelBorder
            border.width: 1
            radius: Theme.cornerRadiusSmall
        }
        contentItem: Text {
            leftPadding: Theme.spacingMedium
            rightPadding: cbRoot.indicator.width + Theme.spacingMedium
            text: cbRoot.displayText
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
            color: Theme.textPrimary
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        indicator: VectorIcon {
            x: cbRoot.width - width - Theme.spacingMedium
            y: (cbRoot.height - height) / 2
            width: 10
            height: 10
            name: "arrow_down"
            color: Theme.textSecondary
        }
        popup: Popup {
            y: cbRoot.height + 2
            width: cbRoot.width
            implicitHeight: Math.min(220, contentItem.implicitHeight + 8)
            padding: 4
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: cbRoot.popup.visible ? cbRoot.delegateModel : null
                currentIndex: cbRoot.highlightedIndex
                ScrollIndicator.vertical: ScrollIndicator { }
            }
            background: Rectangle {
                color: Theme.surfaceElevated
                border.color: Theme.panelBorder
                border.width: 1
                radius: Theme.cornerRadiusSmall
            }
        }
        delegate: ItemDelegate {
            width: cbRoot.width - 8
            height: 26
            highlighted: cbRoot.highlightedIndex === index
            contentItem: Text {
                text: modelData
                color: highlighted ? Theme.accentHover : Theme.textPrimary
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: highlighted ? Theme.selection : "transparent"
                radius: Theme.cornerRadiusSmall
            }
        }
    }

    component StyledCheckBox: CheckBox {
        id: cbControl
        implicitHeight: 28
        indicator: Rectangle {
            implicitWidth: 16
            implicitHeight: 16
            x: cbControl.leftPadding
            y: parent.height / 2 - height / 2
            radius: Theme.cornerRadiusSmall
            color: cbControl.checked ? Theme.accent : Theme.surfaceElevated
            border.color: cbControl.checked ? Theme.accent : Theme.panelBorder
            border.width: 1

            VectorIcon {
                anchors.centerIn: parent
                width: 10
                height: 10
                name: "check"
                color: Theme.background
                visible: cbControl.checked
            }
        }
        contentItem: Text {
            text: cbControl.text
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
            color: Theme.textPrimary
            verticalAlignment: Text.AlignVCenter
            leftPadding: cbControl.indicator.width + Theme.spacingMedium
            elide: Text.ElideRight
        }
    }

    component StyledSlider: Slider {
        id: sldControl
        implicitHeight: 28
        background: Rectangle {
            x: sldControl.leftPadding
            y: sldControl.topPadding + sldControl.availableHeight / 2 - 2
            implicitWidth: 160
            implicitHeight: 4
            width: sldControl.availableWidth
            height: 4
            radius: 2
            color: Theme.surfaceElevated

            Rectangle {
                width: sldControl.visualPosition * parent.width
                height: parent.height
                color: Theme.accent
                radius: 2
            }
        }
        handle: Rectangle {
            x: sldControl.leftPadding + sldControl.visualPosition * (sldControl.availableWidth - width)
            y: sldControl.topPadding + sldControl.availableHeight / 2 - height / 2
            implicitWidth: 14
            implicitHeight: 14
            radius: 7
            color: sldControl.pressed ? Theme.textPrimary : Theme.accentHover
            border.color: Theme.panelBorder
            border.width: 1
        }
    }

    component StyledButton: Button {
        id: btnControl
        implicitHeight: 28
        padding: Theme.spacingMedium
        contentItem: Text {
            text: btnControl.text
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
            font.bold: btnControl.highlighted
            color: btnControl.highlighted ? Theme.accentHover : Theme.textPrimary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            color: btnControl.highlighted ? Theme.selection : (btnControl.hovered ? Theme.surfaceElevated : Theme.background)
            border.color: btnControl.highlighted ? Theme.accent : Theme.panelBorder
            border.width: 1
            radius: Theme.cornerRadiusSmall
        }
    }

    FileDialog {
        id: themeFileDialog
        title: "Select Theme File (.json)"
        nameFilters: ["JSON Theme files (*.json)"]
        onAccepted: {
            bridge.theme.installTheme(selectedFile.toString());
        }
    }

    FolderDialog {
        id: addFolderDialog
        title: "Add Folder to Monitored Music Folders"
        onAccepted: {
            bridge.addMonitoredFolder(selectedFolder.toString());
        }
    }

    background: Rectangle {
        color: Theme.surface
        border.color: Theme.panelBorder
        border.width: 1
        radius: Theme.cornerRadiusMedium
    }

    header: Rectangle {
        height: 38
        color: Theme.surfaceElevated
        border.color: Theme.panelBorder
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            Text {
                text: "PREFERENCES & SETTINGS"
                font.pixelSize: Theme.fontSizeSmall
                font.bold: true
                font.letterSpacing: 1.0
                color: Theme.textPrimary
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 22
                height: 22
                radius: 3
                color: closeBtnMouse.containsMouse ? Theme.selection : "transparent"
                VectorIcon {
                    anchors.centerIn: parent
                    name: "close"
                    width: 10
                    height: 10
                    color: Theme.textSecondary
                }
                MouseArea {
                    id: closeBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }
    }

    contentItem: RowLayout {
        spacing: 0

        // Categories
        Rectangle {
            Layout.preferredWidth: 190
            Layout.fillHeight: true
            color: Theme.background
            border.color: Theme.panelBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 8
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 2

                Repeater {
                    model: [
                        { idx: 0, label: "General", icon: "music" },
                        { idx: 1, label: "Themes & Appearance", icon: "grid" },
                        { idx: 2, label: "Audio Output", icon: "volume" },
                        { idx: 3, label: "Playback & Queue", icon: "queue" },
                        { idx: 4, label: "Library & Folders", icon: "folder" },
                        { idx: 5, label: "Plugins & Extensions", icon: "equalizer" },
                        { idx: 6, label: "Keyboard Shortcuts", icon: "info" }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: Theme.cornerRadiusSmall
                        color: activeCategory === modelData.idx ? Theme.selection : (catMouse.containsMouse ? Theme.surfaceElevated : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            VectorIcon {
                                name: modelData.icon
                                width: 12
                                height: 12
                                color: activeCategory === modelData.idx ? Theme.accent : Theme.textMuted
                            }

                            Text {
                                text: modelData.label
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: activeCategory === modelData.idx
                                color: activeCategory === modelData.idx ? Theme.textPrimary : Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: catMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: activeCategory = modelData.idx
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // Settings content
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.surface

            // General Settings
            ScrollView {
                anchors.fill: parent
                anchors.margins: 20
                visible: activeCategory === 0
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                clip: true

                ColumnLayout {
                    width: parent.width - 24
                    spacing: 16

                    Text {
                        text: "General Settings"
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Text {
                        text: "Configure interface localization, application startup behavior, window closing actions, and desktop alerts."
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textMuted
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // Language
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Interface Language"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Select application display language for menus, tooltips, and dialogs."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        StyledComboBox {
                            id: languageCombo
                            model: ["System Default", "English", "Deutsch", "Français", "Español", "日本語"]
                            currentIndex: Math.max(0, model.indexOf(bridge.language))
                            onActivated: function(index) {
                                bridge.setLanguage(model[index])
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // Startup Action
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Startup Action"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Behavior when launching Parakeet."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        StyledComboBox {
                            id: startupCombo
                            model: ["Restore Session", "Open Empty", "Play Immediately"]
                            currentIndex: Math.max(0, model.indexOf(bridge.startupAction))
                            onActivated: function(index) {
                                bridge.setStartupAction(model[index])
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // Window Lifecycle: Close Action & Minimize Action
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Window Close Action"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Choose what happens when the main window close button is pressed."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        StyledComboBox {
                            id: closeActionCombo
                            model: ["Exit Application", "Minimize to System Tray"]
                            currentIndex: Math.max(0, model.indexOf(bridge.closeAction))
                            onActivated: function(index) {
                                bridge.setCloseAction(model[index])
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Window Minimize Action"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Choose where the application goes when minimized."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        StyledComboBox {
                            id: minimizeActionCombo
                            model: ["Minimize to Taskbar", "Minimize to System Tray"]
                            currentIndex: Math.max(0, model.indexOf(bridge.minimizeAction))
                            onActivated: function(index) {
                                bridge.setMinimizeAction(model[index])
                            }
                        }
                    }

                    // Single-Instance
                    StyledCheckBox {
                        Layout.fillWidth: true
                        text: "Allow only a single instance of Parakeet (forward tracks to running instance)"
                        checked: bridge.singleInstance
                        onToggled: bridge.setSingleInstance(checked)
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // Software Updates
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Software Updates"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Check for new releases and security patches."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            spacing: 8
                            StyledComboBox {
                                id: updateIntervalCombo
                                Layout.preferredWidth: 140
                                model: ["Never", "On Startup", "Daily", "Weekly", "Monthly"]
                                currentIndex: Math.max(0, model.indexOf(bridge.updateCheckInterval))
                                onActivated: function(index) {
                                    bridge.setUpdateCheckInterval(model[index])
                                }
                            }
                            StyledButton {
                                text: "Check Now"
                                onClicked: bridge.checkForUpdates()
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // Notifications Section
                    Text {
                        text: "Desktop Notifications"
                        font.pixelSize: Theme.fontSizeBase
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    StyledCheckBox {
                        Layout.fillWidth: true
                        text: "Show native desktop notifications on track changes"
                        checked: bridge.showNotifications
                        onToggled: bridge.setShowNotifications(checked)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        opacity: bridge.showNotifications ? 1.0 : 0.4
                        enabled: bridge.showNotifications

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Notification Duration"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "How long toast alerts remain visible before fading out."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            spacing: 10
                            StyledSlider {
                                id: notifDurationSlider
                                Layout.preferredWidth: 140
                                from: 1
                                to: 10
                                stepSize: 1
                                value: bridge.notificationDurationSec
                                onMoved: bridge.setNotificationDurationSec(Math.round(value))
                            }
                            Text {
                                text: Math.round(notifDurationSlider.value) + "s"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.accentHover
                                Layout.preferredWidth: 30
                            }
                        }
                    }

                    StyledCheckBox {
                        Layout.fillWidth: true
                        opacity: bridge.showNotifications ? 1.0 : 0.4
                        enabled: bridge.showNotifications
                        text: "Suppress notifications when Parakeet is the focused foreground window"
                        checked: bridge.suppressNotificationsWhenFocused
                        onToggled: bridge.setSuppressNotificationsWhenFocused(checked)
                    }
                }
            }

            // Themes & Appearance
            ScrollView {
                anchors.fill: parent
                anchors.margins: 20
                visible: activeCategory === 1
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                clip: true

                ColumnLayout {
                    width: parent.width - 24
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Installed Themes"
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }

                        StyledButton {
                            text: "Install Theme from File..."
                            onClicked: themeFileDialog.open()
                        }

                        StyledButton {
                            text: "Open Themes Folder"
                            onClicked: bridge.theme.openThemesFolder()
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // Theme Cards Grid
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 12
                        columnSpacing: 12

                        Repeater {
                            model: bridge.theme.availableThemes

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 110
                                radius: Theme.cornerRadiusSmall
                                color: bridge.theme.themeId === modelData.id ? Theme.selection : (themeCardMouse.containsMouse ? Theme.surfaceElevated : Theme.background)
                                border.color: bridge.theme.themeId === modelData.id ? Theme.accent : Theme.panelBorder
                                border.width: bridge.theme.themeId === modelData.id ? 2 : 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: modelData.name
                                            font.pixelSize: Theme.fontSizeBase
                                            font.bold: true
                                            color: Theme.textPrimary
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: "v" + modelData.version
                                            font.pixelSize: Theme.fontSizeSmall - 1
                                            color: Theme.textMuted
                                        }
                                    }

                                    Text {
                                        text: "By " + modelData.author
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.textSecondary
                                    }

                                    Text {
                                        text: modelData.description
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        color: Theme.textMuted
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Item { Layout.fillHeight: true }

                                    // Palette Swatches
                                    RowLayout {
                                        spacing: 6
                                        Repeater {
                                            model: modelData.colors ? [
                                                modelData.colors.background,
                                                modelData.colors.surface,
                                                modelData.colors.surfaceElevated,
                                                modelData.colors.accent,
                                                modelData.colors.textPrimary
                                            ] : []

                                            delegate: Rectangle {
                                                width: 18
                                                height: 14
                                                radius: 2
                                                color: modelData || Theme.surfaceElevated
                                                border.color: Theme.panelBorder
                                                border.width: 1
                                            }
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: bridge.theme.themeId === modelData.id ? "ACTIVE" : "CLICK TO ACTIVATE"
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: bridge.theme.themeId === modelData.id ? Theme.accent : Theme.textMuted
                                        }
                                    }
                                }

                                MouseArea {
                                    id: themeCardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        bridge.theme.themeId = modelData.id;
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // Display Density
                    Text {
                        text: "Display Density & Metrics Scale"
                        font.pixelSize: Theme.fontSizeBase
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    RowLayout {
                        spacing: 12
                        Repeater {
                            model: ["Compact", "Standard", "Comfortable"]
                            delegate: StyledButton {
                                text: modelData
                                highlighted: bridge.theme.densityPreset === modelData
                                onClicked: bridge.theme.densityPreset = modelData
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // Typography & Font Settings
                    Text {
                        text: "Typography & Font Customization"
                        font.pixelSize: Theme.fontSizeBase
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Font Family"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Global typeface family for the UI."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        StyledComboBox {
                            id: fontCombo
                            model: ["Inter, sans-serif", "Segoe UI, sans-serif", "SF Pro, sans-serif", "Roboto, sans-serif", "System Monospace"]
                            currentIndex: Math.max(0, model.indexOf(bridge.fontFamily))
                            onActivated: function(index) {
                                bridge.setFontFamily(model[index])
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Base Font Size"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Controls baseline font scaling throughout the interface."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            spacing: 10
                            StyledSlider {
                                id: baseFontSizeSlider
                                Layout.preferredWidth: 140
                                from: 9
                                to: 16
                                stepSize: 1
                                value: bridge.baseFontSize
                                onMoved: bridge.setBaseFontSize(Math.round(value))
                            }
                            Text {
                                text: Math.round(baseFontSizeSlider.value) + " pt"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.accentHover
                                Layout.preferredWidth: 40
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // Track Table & UI Layout
                    Text {
                        text: "Table & Interface Layout"
                        font.pixelSize: Theme.fontSizeBase
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Track Table Row Height"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Compact spacing for large libraries or taller rows for touch ergonomics."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            spacing: 10
                            StyledSlider {
                                id: rowHeightSlider
                                Layout.preferredWidth: 140
                                from: 24
                                to: 48
                                stepSize: 2
                                value: bridge.tableRowHeight
                                onMoved: bridge.setTableRowHeight(Math.round(value))
                            }
                            Text {
                                text: Math.round(rowHeightSlider.value) + " px"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.accentHover
                                Layout.preferredWidth: 40
                            }
                        }
                    }

                    StyledCheckBox {
                        Layout.fillWidth: true
                        text: "Enable alternating row background zebra striping in track tables"
                        checked: bridge.tableAlternatingRows
                        onToggled: bridge.setTableAlternatingRows(checked)
                    }

                    StyledCheckBox {
                        Layout.fillWidth: true
                        text: "Display high-density audio waveform seekbar in player deck"
                        checked: bridge.waveformSeekbar
                        onToggled: bridge.setWaveformSeekbar(checked)
                    }

                    StyledCheckBox {
                        Layout.fillWidth: true
                        text: "Display bottom status bar (track count, engine specs, scanning state)"
                        checked: bridge.showStatusBar
                        onToggled: bridge.setShowStatusBar(checked)
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // Cover Art & Cache
                    Text {
                        text: "Artwork & Thumbnail Cache"
                        font.pixelSize: Theme.fontSizeBase
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Thumbnail Scaling Quality"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Trade off image rendering speed against sharpness."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        StyledComboBox {
                            id: artQualityCombo
                            model: ["Fast (Nearest)", "Balanced (Bilinear)", "Smooth (High Quality)"]
                            currentIndex: Math.max(0, model.indexOf(bridge.artThumbnailQuality))
                            onActivated: function(index) {
                                bridge.setArtThumbnailQuality(model[index])
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Disk Cache Size Limit"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Maximum local storage dedicated to cached album covers."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            spacing: 10
                            StyledSlider {
                                id: artCacheSlider
                                Layout.preferredWidth: 140
                                from: 128
                                to: 4096
                                stepSize: 128
                                value: bridge.artCacheLimitMb
                                onMoved: bridge.setArtCacheLimitMb(Math.round(value))
                            }
                            Text {
                                text: Math.round(artCacheSlider.value) + " MB"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.accentHover
                                Layout.preferredWidth: 50
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Item { Layout.fillWidth: true }
                        StyledButton {
                            text: "Clear Artwork Disk Cache"
                            onClicked: bridge.clearArtCache()
                        }
                    }
                }
            }

            // Audio Output & Hardware Pipeline
            ScrollView {
                anchors.fill: parent
                anchors.margins: 20
                visible: activeCategory === 2
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                clip: true

                ColumnLayout {
                    width: parent.width - 24
                    spacing: 16

                    Text {
                        text: "Audio Hardware & Output Pipeline"
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Text {
                        text: "Configure audio output drivers, hardware exclusivity, buffers, and bit-perfect playback pipeline."
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textMuted
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // Hardware Status Card
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 74
                        radius: Theme.cornerRadiusSmall
                        color: Theme.background
                        border.color: Theme.panelBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 14

                            Rectangle {
                                width: 36
                                height: 36
                                radius: Theme.cornerRadiusSmall
                                color: Theme.selection
                                border.color: Theme.accent
                                border.width: 1

                                VectorIcon {
                                    anchors.centerIn: parent
                                    name: "volume"
                                    width: 18
                                    height: 18
                                    color: Theme.accentHover
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 8
                                    Text {
                                        text: "Active Audio Engine:"
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.bold: true
                                        color: Theme.textPrimary
                                    }
                                    Text {
                                        text: bridge.audioBackend
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.bold: true
                                        color: Theme.accentHover
                                    }
                                    Badge {
                                        text: bridge.bitPerfectExclusive ? "BIT-PERFECT" : "SHARED MIXER"
                                        textColor: bridge.bitPerfectExclusive ? Theme.accentHover : Theme.warning
                                        badgeBorderColor: bridge.bitPerfectExclusive ? Theme.accent : Theme.warning
                                    }
                                }

                                Text {
                                    text: bridge.currentAudioSpecs + " • Device: " + bridge.currentAudioDevice
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    color: Theme.textMuted
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }

                    // Audio Backend
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Audio Output Backend"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Select low-level audio driver interface."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        StyledComboBox {
                            id: backendCombo
                            Layout.preferredWidth: 260
                            model: ["Linux PipeWire Lock-Free Client", "ALSA Direct Hardware (hw:)", "PulseAudio Legacy Client"]
                            currentIndex: Math.max(0, model.indexOf(bridge.audioBackend))
                            onActivated: function(index) {
                                bridge.setAudioBackend(model[index])
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // Output Device
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Output Device"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Select physical sound card, DAC, or virtual output sink."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            spacing: 8
                            StyledComboBox {
                                id: audioDeviceCombo
                                Layout.preferredWidth: 220
                                model: bridge.availableAudioDevices
                                currentIndex: Math.max(0, model.indexOf(bridge.currentAudioDevice))
                                onActivated: function(index) {
                                    bridge.setCurrentAudioDevice(model[index])
                                }
                            }
                            StyledButton {
                                text: "Refresh"
                                onClicked: bridge.refreshAudioDevices()
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // Bit-Perfect Mode
                    StyledCheckBox {
                        Layout.fillWidth: true
                        text: "Bit-perfect integer routing (exclusive mode, bypass OS mixer & resampling)"
                        checked: bridge.bitPerfectExclusive
                        onToggled: bridge.setBitPerfectExclusive(checked)
                    }

                    // Buffer Latency
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Hardware Buffer Latency"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Buffer duration in milliseconds. Lower values decrease seek delay; higher values prevent underruns."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            spacing: 10
                            StyledSlider {
                                id: latencySlider
                                Layout.preferredWidth: 140
                                from: 10
                                to: 500
                                stepSize: 5
                                value: bridge.bufferLatencyMs
                                onMoved: bridge.setBufferLatencyMs(Math.round(value))
                            }
                            Text {
                                text: Math.round(latencySlider.value) + " ms"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.accentHover
                                Layout.preferredWidth: 45
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // DSP & Pipeline Preferences
                    Text {
                        text: "DSP & Resampling Pipeline"
                        font.pixelSize: Theme.fontSizeBase
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Resampler Engine & Quality"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Algorithm used when source sample rate does not match DAC native rate."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        StyledComboBox {
                            id: resamplerCombo
                            Layout.preferredWidth: 260
                            model: ["SoX Resampler Very High Quality (VHQ)", "SoX Resampler High Quality", "Speex Resampler", "Linear Resampler (Low Latency)"]
                            currentIndex: Math.max(0, model.indexOf(bridge.resamplerQuality))
                            onActivated: function(index) {
                                bridge.setResamplerQuality(model[index])
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Dithering Algorithm"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Applied during bit-depth truncation (e.g. 24-bit to 16-bit output)."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        StyledComboBox {
                            id: ditherCombo
                            Layout.preferredWidth: 260
                            model: ["None (Direct Truncation)", "Flat TPDF (Triangular)", "High-Pass TPDF", "Shibata Noise Shaping"]
                            currentIndex: Math.max(0, model.indexOf(bridge.ditherMode))
                            onActivated: function(index) {
                                bridge.setDitherMode(model[index])
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Channel Processing & Downmix"
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: "Multi-channel conversion strategy for stereo outputs."
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.textMuted
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        StyledComboBox {
                            id: channelCombo
                            Layout.preferredWidth: 260
                            model: ["Stereo Passthrough", "Downmix Surround to Stereo", "Upmix Stereo to 5.1", "Mono Downmix"]
                            currentIndex: Math.max(0, model.indexOf(bridge.channelProcessing))
                            onActivated: function(index) {
                                bridge.setChannelProcessing(model[index])
                            }
                        }
                    }
                }
            }

            // Playback & Queue
            ScrollView {
                anchors.fill: parent
                anchors.margins: 20
                visible: activeCategory === 3
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: 16

                    Text {
                        text: "Playback & Queue Behavior"
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // Double-click Action
                    ColumnLayout {
                        spacing: 4
                        Text { text: "Action on Double-Clicking a Track:"; font.bold: true; color: Theme.textPrimary }
                        RowLayout {
                            spacing: 8
                            Repeater {
                                model: ["Play Now", "Play Next", "Queue Last"]
                                delegate: Button {
                                    text: modelData
                                    highlighted: bridge.doubleClickAction === modelData
                                    onClicked: bridge.setDoubleClickAction(modelData)
                                }
                            }
                        }
                    }

                    // Queue Auto-Fill Mode
                    ColumnLayout {
                        spacing: 4
                        Text { text: "When Queue Ends:"; font.bold: true; color: Theme.textPrimary }
                        RowLayout {
                            spacing: 8
                            Repeater {
                                model: ["Stop", "Loop Album", "Continue Library"]
                                delegate: Button {
                                    text: modelData
                                    highlighted: bridge.queueAutoFillMode === modelData
                                    onClicked: bridge.setQueueAutoFillMode(modelData)
                                }
                            }
                        }
                    }

                    // Shuffle Mode Selector
                    ColumnLayout {
                        spacing: 4
                        Text { text: "Default Shuffle Strategy:"; font.bold: true; color: Theme.textPrimary }
                        RowLayout {
                            spacing: 8
                            Button {
                                text: "Track Shuffle (Pure Random)"
                                highlighted: bridge.shuffleMode === 1
                                onClicked: bridge.setShuffleMode(1)
                            }
                            Button {
                                text: "Album Shuffle (Keep Album Tracks in Order)"
                                highlighted: bridge.shuffleMode === 2
                                onClicked: bridge.setShuffleMode(2)
                            }
                        }
                    }
                }
            }

            // Library & Folders
            ScrollView {
                anchors.fill: parent
                anchors.margins: 20
                visible: activeCategory === 4
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Monitored Music Folders"
                            font.pixelSize: Theme.fontSizeLarge
                            font.bold: true
                            color: Theme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "Add Folder..."
                            onClicked: addFolderDialog.open()
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    // List of monitored directories
                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(100, count * 36)
                        model: bridge.monitoredFolders
                        clip: true

                        delegate: Rectangle {
                            width: parent.width
                            height: 32
                            color: Theme.background
                            border.color: Theme.panelBorder
                            border.width: 1
                            radius: Theme.cornerRadiusSmall

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                VectorIcon { name: "folder"; width: 12; height: 12; color: Theme.accent }
                                Text {
                                    text: modelData
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.textPrimary
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }
                                Button {
                                    text: "Remove"
                                    onClicked: bridge.removeMonitoredFolder(index)
                                }
                            }
                        }
                    }

                    CheckBox {
                        text: "Automatically rescan monitored folders on startup"
                        checked: bridge.autoScanOnStartup
                        onToggled: bridge.setAutoScanOnStartup(checked)
                    }

                    Text {
                        text: "Library Maintenance Actions"
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    RowLayout {
                        spacing: 8
                        Button {
                            text: "Rescan All Folders"
                            onClicked: bridge.rescanAllMonitoredFolders()
                        }
                        Button {
                            text: "Purge Missing Tracks"
                            onClicked: bridge.purgeMissingTracks()
                        }
                        Button {
                            text: "Clear Database"
                            onClicked: bridge.clearLibrary()
                        }
                    }
                }
            }

            // Plugins
            ScrollView {
                anchors.fill: parent
                anchors.margins: 20
                visible: activeCategory === 5
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: 16

                    Text {
                        text: "Plugins & Extensions (Parakeet SDK)"
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    Text {
                        text: "Capability ports active: IPlayerPlugin, ILibraryPlugin, IVisualizerPlugin"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textMuted
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        color: Theme.background
                        border.color: Theme.panelBorder
                        radius: Theme.cornerRadiusSmall
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            VectorIcon { name: "equalizer"; width: 20; height: 20; color: Theme.accent }
                            ColumnLayout {
                                Text { text: "Spectrum Visualizer"; font.bold: true; color: Theme.textPrimary }
                                Text { text: "FFT Audio Spectrum Analyzer using IVisualizerPlugin"; font.pixelSize: Theme.fontSizeSmall; color: Theme.textMuted }
                            }
                        }
                    }
                }
            }

            // Keyboard shortcuts
            ScrollView {
                anchors.fill: parent
                anchors.margins: 20
                visible: activeCategory === 6
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    Text {
                        text: "Keyboard Shortcuts & Accelerators"
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    GridLayout {
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 24

                        Text { text: "Space"; font.bold: true; color: Theme.accent }
                        Text { text: "Play / Pause playback"; color: Theme.textSecondary }

                        Text { text: "Ctrl + ,"; font.bold: true; color: Theme.accent }
                        Text { text: "Open Preferences & Settings Dialog"; color: Theme.textSecondary }

                        Text { text: "Ctrl + 1"; font.bold: true; color: Theme.accent }
                        Text { text: "Toggle Left Library Explorer"; color: Theme.textSecondary }

                        Text { text: "Ctrl + 2"; font.bold: true; color: Theme.accent }
                        Text { text: "Toggle 3-Column Filter Browser"; color: Theme.textSecondary }

                        Text { text: "Ctrl + 3"; font.bold: true; color: Theme.accent }
                        Text { text: "Toggle Right Inspector / Queue"; color: Theme.textSecondary }

                        Text { text: "Ctrl + Right"; font.bold: true; color: Theme.accent }
                        Text { text: "Next track"; color: Theme.textSecondary }

                        Text { text: "Ctrl + Left"; font.bold: true; color: Theme.accent }
                        Text { text: "Previous track (Reversible History)"; color: Theme.textSecondary }

                        Text { text: "Ctrl + Up / Down"; font.bold: true; color: Theme.accent }
                        Text { text: "Volume adjust (+/- 5%)"; color: Theme.textSecondary }

                        Text { text: "Ctrl + M"; font.bold: true; color: Theme.accent }
                        Text { text: "Mute / Unmute audio"; color: Theme.textSecondary }

                        Text { text: "Ctrl + S"; font.bold: true; color: Theme.accent }
                        Text { text: "Cycle Shuffle mode (Off / Tracks / Albums)"; color: Theme.textSecondary }

                        Text { text: "Ctrl + R"; font.bold: true; color: Theme.accent }
                        Text { text: "Cycle Repeat mode (Off / All / One)"; color: Theme.textSecondary }

                        Text { text: "Ctrl + F"; font.bold: true; color: Theme.accent }
                        Text { text: "Focus Instant Search input"; color: Theme.textSecondary }

                        Text { text: "Left / Right Arrow"; font.bold: true; color: Theme.accent }
                        Text { text: "Seek 5 seconds backward / forward"; color: Theme.textSecondary }

                        Text { text: "Shift + Left / Right"; font.bold: true; color: Theme.accent }
                        Text { text: "Seek 30 seconds backward / forward"; color: Theme.textSecondary }

                        Text { text: "Escape"; font.bold: true; color: Theme.accent }
                        Text { text: "Clear filter / Close dialog"; color: Theme.textSecondary }
                    }
                }
            }
        }
    }
}

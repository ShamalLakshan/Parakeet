import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import ".."

Dialog {
    id: root
    title: "Preferences & Settings"
    width: 820
    height: 560
    modal: true
    anchors.centerIn: parent

    property int activeCategory: 1 // default to Themes & Appearance

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

            // General
            ScrollView {
                anchors.fill: parent
                anchors.margins: 20
                visible: activeCategory === 0
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: 16

                    Text {
                        text: "General Settings"
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    CheckBox {
                        text: "Automatically check for updates on startup"
                        checked: true
                    }

                    CheckBox {
                        text: "Minimize to system tray when closing window"
                        checked: false
                    }

                    CheckBox {
                        text: "Show desktop notifications on track change"
                        checked: true
                    }
                }
            }

            // Themes & Appearance
            ScrollView {
                anchors.fill: parent
                anchors.margins: 20
                visible: activeCategory === 1
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
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

                        // Install Theme Button
                        Button {
                            text: "Install Theme from File..."
                            onClicked: themeFileDialog.open()
                        }

                        // Open Folder Button
                        Button {
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

                    Item { height: 8 }

                    Text {
                        text: "Display Density & Typography Scale"
                        font.pixelSize: Theme.fontSizeBase
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    RowLayout {
                        spacing: 12
                        Repeater {
                            model: ["Compact", "Standard", "Comfortable"]
                            delegate: Button {
                                text: modelData
                                highlighted: bridge.theme.densityPreset === modelData
                                onClicked: bridge.theme.densityPreset = modelData
                            }
                        }
                    }
                }
            }

            // Audio Output
            ScrollView {
                anchors.fill: parent
                anchors.margins: 20
                visible: activeCategory === 2
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: 16

                    Text {
                        text: "Audio Hardware & Output Routing"
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        radius: Theme.cornerRadiusSmall
                        color: Theme.background
                        border.color: Theme.panelBorder

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            VectorIcon { name: "volume"; width: 24; height: 24; color: Theme.accent }
                            ColumnLayout {
                                spacing: 2
                                Text { text: "Active Audio Backend: Qt 6 Direct PipeWire / ALSA"; font.bold: true; color: Theme.textPrimary }
                                Text { text: "Bit-perfect integer routing enabled • Sample Rate: 96,000 Hz / 24-bit"; font.pixelSize: Theme.fontSizeSmall; color: Theme.textMuted }
                            }
                        }
                    }

                    CheckBox {
                        text: "Exclusive hardware mode lock (bypass OS software mixer)"
                        checked: true
                    }

                    CheckBox {
                        text: "Sample-accurate gapless transitions"
                        checked: true
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

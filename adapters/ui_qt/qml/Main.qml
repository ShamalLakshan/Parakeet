import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ApplicationWindow {
    id: root
    width: 1400
    height: 840
    minimumWidth: 1024
    minimumHeight: 640
    visible: true
    title: "Parakeet - Audiophile Music Player"
    color: "#141416"

    // UI state & panel visibility toggles (MusicBee style)
    property bool showLeftPanel: true
    property bool showRightPanel: true
    property bool showColumnBrowser: true
    property bool showStatusBar: true
    property int mainViewMode: 1 // 0: Album Grid, 1: Track Details Table, 2: Album & Tracks View
    property int activeNavSection: 0 // 0: All Tracks, 1: Albums, 2: Artists, 3: Genres, 4: Now Playing
    property string activeLetterFilter: "All"
    property string selectedGenreFilter: "All"
    property string selectedArtistFilter: "All"
    property int rightPanelTab: 0 // 0: Properties, 1: Queue

    FolderDialog {
        id: folderDialog
        title: "Select Directory to Scan for Music"
        currentFolder: "file:///home/shamal/Music"
        onAccepted: {
            bridge.scanDirectory(selectedFolder.toString())
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // =========================================================================
        // ROW 1: MENU STRIP & ENGINE STATUS BAR
        // =========================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            color: "#111113"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 4

                // Brand logo / title
                RowLayout {
                    spacing: 6
                    VectorIcon {
                        name: "music"
                        width: 13
                        height: 13
                        color: "#3a82f7"
                    }
                    Text {
                        text: "PARAKEET"
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.5
                        color: "#ffffff"
                    }
                }

                Rectangle { width: 1; height: 14; color: "#25252b"; Layout.leftMargin: 6; Layout.rightMargin: 6 }

                // Desktop Menu Items (File, Edit, View, Controls, Tools, Help)
                RowLayout {
                    spacing: 2

                    // File Menu Button
                    Rectangle {
                        width: fileMenuText.implicitWidth + 14
                        height: 22
                        radius: 3
                        color: fileMenuMouse.containsMouse ? "#24242c" : "transparent"
                        Text {
                            id: fileMenuText
                            anchors.centerIn: parent
                            text: "File"
                            font.pixelSize: 11
                            color: "#c0c0cc"
                        }
                        MouseArea {
                            id: fileMenuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: fileMenu.open()
                        }
                        Menu {
                            id: fileMenu
                            y: parent.height
                            MenuItem {
                                text: "Scan Music Directory..."
                                onTriggered: folderDialog.open()
                            }
                            MenuItem {
                                text: "Purge Missing / Dead Files"
                                onTriggered: bridge.purgeMissingTracks()
                            }
                            MenuItem {
                                text: "Clear Entire Library"
                                onTriggered: bridge.clearLibrary()
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Exit"
                                onTriggered: Qt.quit()
                            }
                        }
                    }

                    // View Menu Button
                    Rectangle {
                        width: viewMenuText.implicitWidth + 14
                        height: 22
                        radius: 3
                        color: viewMenuMouse.containsMouse ? "#24242c" : "transparent"
                        Text {
                            id: viewMenuText
                            anchors.centerIn: parent
                            text: "View"
                            font.pixelSize: 11
                            color: "#c0c0cc"
                        }
                        MouseArea {
                            id: viewMenuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: viewMenu.open()
                        }
                        Menu {
                            id: viewMenu
                            y: parent.height
                            MenuItem {
                                text: (showLeftPanel ? "Hide" : "Show") + " Left Navigator"
                                onTriggered: showLeftPanel = !showLeftPanel
                            }
                            MenuItem {
                                text: (showColumnBrowser ? "Hide" : "Show") + " 3-Column Browser"
                                onTriggered: showColumnBrowser = !showColumnBrowser
                            }
                            MenuItem {
                                text: (showRightPanel ? "Hide" : "Show") + " Right Inspector"
                                onTriggered: showRightPanel = !showRightPanel
                            }
                            MenuItem {
                                text: (showStatusBar ? "Hide" : "Show") + " Bottom Status Bar"
                                onTriggered: showStatusBar = !showStatusBar
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Track Details Table View"
                                onTriggered: mainViewMode = 1
                            }
                            MenuItem {
                                text: "Album Grid View"
                                onTriggered: mainViewMode = 0
                            }
                            MenuItem {
                                text: "Album & Tracks View"
                                onTriggered: mainViewMode = 2
                            }
                        }
                    }

                    // Controls Menu Button
                    Rectangle {
                        width: ctrlMenuText.implicitWidth + 14
                        height: 22
                        radius: 3
                        color: ctrlMenuMouse.containsMouse ? "#24242c" : "transparent"
                        Text {
                            id: ctrlMenuText
                            anchors.centerIn: parent
                            text: "Controls"
                            font.pixelSize: 11
                            color: "#c0c0cc"
                        }
                        MouseArea {
                            id: ctrlMenuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ctrlMenu.open()
                        }
                        Menu {
                            id: ctrlMenu
                            y: parent.height
                            MenuItem {
                                text: bridge.isPlaying ? "Pause" : "Play"
                                onTriggered: bridge.togglePlayPause()
                            }
                            MenuItem {
                                text: "Stop"
                                onTriggered: bridge.stop()
                            }
                            MenuItem {
                                text: "Next Track"
                                onTriggered: bridge.nextTrack()
                            }
                            MenuItem {
                                text: "Previous Track"
                                onTriggered: bridge.previousTrack()
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Play All Tracks"
                                onTriggered: bridge.playAll()
                            }
                            MenuItem {
                                text: "Shuffle All Tracks"
                                onTriggered: bridge.shuffleAll()
                            }
                        }
                    }

                    // Tools Menu Button
                    Rectangle {
                        width: toolsMenuText.implicitWidth + 14
                        height: 22
                        radius: 3
                        color: toolsMenuMouse.containsMouse ? "#24242c" : "transparent"
                        Text {
                            id: toolsMenuText
                            anchors.centerIn: parent
                            text: "Tools"
                            font.pixelSize: 11
                            color: "#c0c0cc"
                        }
                        MouseArea {
                            id: toolsMenuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: toolsMenu.open()
                        }
                        Menu {
                            id: toolsMenu
                            y: parent.height
                            MenuItem {
                                text: "Rescan Library"
                                onTriggered: {
                                    if (bridge.currentFilePath.length > 0) {
                                        var p = bridge.currentFilePath;
                                        var dir = p.substring(0, p.lastIndexOf('/'));
                                        bridge.scanDirectory(dir);
                                    } else {
                                        folderDialog.open();
                                    }
                                }
                            }
                            MenuItem {
                                text: "Purge Dead Tracks"
                                onTriggered: bridge.purgeMissingTracks()
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Audio Engine Status Pill
                Rectangle {
                    height: 18
                    width: engineStatusLayout.implicitWidth + 14
                    radius: 2
                    color: "#181820"
                    border.color: "#282834"

                    RowLayout {
                        id: engineStatusLayout
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: bridge.isPlaying ? "#28c840" : "#888899"
                        }

                        Text {
                            text: bridge.isPlaying ? "BIT-PERFECT OUTPUT • PLAYING" : "BIT-PERFECT OUTPUT • IDLE"
                            font.pixelSize: 9
                            font.bold: true
                            color: bridge.isPlaying ? "#e0e0e0" : "#888899"
                        }
                    }
                }
            }
        }

        // 1px divider
        Rectangle { Layout.fillWidth: true; height: 1; color: "#24242c" }

        // =========================================================================
        // ROW 2: PRIMARY COMMAND & NAVIGATION TOOLBAR
        // =========================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            color: "#18181c"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                // Navigation Tabs
                RowLayout {
                    spacing: 2

                    Repeater {
                        model: [
                            { name: "ALL TRACKS", icon: "table", mode: 1, nav: 0 },
                            { name: "ALBUMS", icon: "grid", mode: 0, nav: 1 },
                            { name: "EXPANDED", icon: "album_tracks", mode: 2, nav: 0 },
                            { name: "NOW PLAYING", icon: "queue", mode: 1, nav: 4 }
                        ]

                        delegate: Rectangle {
                            width: tabRowLayout.implicitWidth + 16
                            height: 30
                            radius: 3
                            color: (activeNavSection === modelData.nav && mainViewMode === modelData.mode) ? "#262632" : (tabMouse.containsMouse ? "#202028" : "transparent")
                            border.color: (activeNavSection === modelData.nav && mainViewMode === modelData.mode) ? "#3e3e50" : "transparent"
                            border.width: 1

                            RowLayout {
                                id: tabRowLayout
                                anchors.centerIn: parent
                                spacing: 6

                                VectorIcon {
                                    name: modelData.icon
                                    width: 12
                                    height: 12
                                    color: (activeNavSection === modelData.nav && mainViewMode === modelData.mode) ? "#3a82f7" : "#888899"
                                }

                                Text {
                                    text: modelData.name
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.letterSpacing: 0.8
                                    color: (activeNavSection === modelData.nav && mainViewMode === modelData.mode) ? "#ffffff" : "#a0a0b0"
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    activeNavSection = modelData.nav;
                                    mainViewMode = modelData.mode;
                                }
                            }
                        }
                    }
                }

                Rectangle { width: 1; height: 20; color: "#282832" }

                // Quick Playback Actions
                RowLayout {
                    spacing: 4

                    Rectangle {
                        width: playAllText.implicitWidth + 18
                        height: 28
                        radius: 3
                        color: playAllMouse.containsMouse ? "#262632" : "#1e1e26"
                        border.color: "#2c2c38"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            VectorIcon { name: "play"; width: 10; height: 10; color: "#ffffff" }
                            Text { id: playAllText; text: "Play All"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
                        }

                        MouseArea {
                            id: playAllMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bridge.playAll()
                        }
                    }

                    Rectangle {
                        width: shuffleAllText.implicitWidth + 18
                        height: 28
                        radius: 3
                        color: shuffleAllMouse.containsMouse ? "#262632" : "#1e1e26"
                        border.color: "#2c2c38"

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            VectorIcon { name: "shuffle"; width: 11; height: 11; color: "#b0b0c0" }
                            Text { id: shuffleAllText; text: "Shuffle"; font.pixelSize: 11; color: "#b0b0c0" }
                        }

                        MouseArea {
                            id: shuffleAllMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bridge.shuffleAll()
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Live Search Input (Compact MusicBee style)
                Rectangle {
                    width: 250
                    height: 28
                    radius: 3
                    color: "#131316"
                    border.color: searchTextInput.activeFocus ? "#3a82f7" : "#2c2c36"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        VectorIcon {
                            name: "search"
                            width: 11
                            height: 11
                            color: "#707080"
                        }

                        TextInput {
                            id: searchTextInput
                            Layout.fillWidth: true
                            color: "#ffffff"
                            font.pixelSize: 11
                            clip: true
                            onTextChanged: bridge.search(text)

                            Text {
                                text: "Search title, artist, album..."
                                color: "#555566"
                                font.pixelSize: 11
                                visible: !searchTextInput.text && !searchTextInput.activeFocus
                            }
                        }

                        VectorIcon {
                            visible: searchTextInput.text.length > 0
                            name: "clear"
                            width: 10
                            height: 10
                            color: "#888899"
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchTextInput.text = "";
                                    bridge.search("");
                                }
                            }
                        }
                    }
                }

                // Scan Directory Action Button
                Rectangle {
                    width: scanBtnLayout.implicitWidth + 18
                    height: 28
                    radius: 3
                    color: scanMouse.containsMouse ? "#2b3b55" : "#1c2638"
                    border.color: "#2a4268"

                    RowLayout {
                        id: scanBtnLayout
                        anchors.centerIn: parent
                        spacing: 6

                        VectorIcon {
                            name: "folder"
                            width: 12
                            height: 12
                            color: "#5c9eff"
                        }

                        Text {
                            text: "Scan Directory..."
                            font.pixelSize: 11
                            font.bold: true
                            color: "#7ab3ff"
                        }
                    }

                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: folderDialog.open()
                    }
                }

                // Panel Toggle Quick Buttons
                RowLayout {
                    spacing: 2

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 3
                        color: showLeftPanel ? "#262632" : (pnlLeftMouse.containsMouse ? "#202028" : "#181820")
                        border.color: "#2c2c38"
                        VectorIcon { anchors.centerIn: parent; name: "panel_left"; width: 13; height: 13; color: showLeftPanel ? "#ffffff" : "#666677" }
                        MouseArea {
                            id: pnlLeftMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showLeftPanel = !showLeftPanel
                        }
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 3
                        color: showRightPanel ? "#262632" : (pnlRightMouse.containsMouse ? "#202028" : "#181820")
                        border.color: "#2c2c38"
                        VectorIcon { anchors.centerIn: parent; name: "panel_right"; width: 13; height: 13; color: showRightPanel ? "#ffffff" : "#666677" }
                        MouseArea {
                            id: pnlRightMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showRightPanel = !showRightPanel
                        }
                    }
                }
            }
        }

        // 1px divider
        Rectangle { Layout.fillWidth: true; height: 1; color: "#222228" }

        // =========================================================================
        // ROW 3: MULTI-PANE WORKSPACE (LEFT NAVIGATOR + CENTER + RIGHT INSPECTOR)
        // =========================================================================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ---------------------------------------------------------------------
            // LEFT PANEL: MUSICBEE EXPLORER & SOURCES TREE
            // ---------------------------------------------------------------------
            Rectangle {
                Layout.preferredWidth: 210
                Layout.fillHeight: true
                color: "#161619"
                visible: showLeftPanel

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Explorer Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        color: "#131316"
                        border.color: "#222228"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            Text {
                                text: "LIBRARY EXPLORER"
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1.2
                                color: "#888899"
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: bridge.totalTracks + " items"
                                font.pixelSize: 10
                                color: "#666677"
                            }
                        }
                    }

                    // Navigation Tree Scroll
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded

                        ColumnLayout {
                            width: 210
                            spacing: 1

                            // Section: LIBRARY
                            Item { height: 6; width: 1 }
                            Text {
                                text: "  LIBRARY"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 1.0
                                color: "#666677"
                                Layout.leftMargin: 8
                            }

                            Repeater {
                                model: [
                                    { title: "All Music Tracks", count: bridge.totalTracks, icon: "table", nav: 0, mode: 1 },
                                    { title: "Albums", count: bridge.totalAlbums, icon: "grid", nav: 1, mode: 0 },
                                    { title: "Artists", count: bridge.artistsList.length, icon: "disc", nav: 2, mode: 1 },
                                    { title: "Genres", count: bridge.genresList.length, icon: "music", nav: 3, mode: 1 }
                                ]

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 26
                                    color: activeNavSection === modelData.nav ? "#24242e" : (navItemMouse.containsMouse ? "#1c1c22" : "transparent")

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        VectorIcon {
                                            name: modelData.icon
                                            width: 11
                                            height: 11
                                            color: activeNavSection === modelData.nav ? "#3a82f7" : "#777788"
                                        }

                                        Text {
                                            text: modelData.title
                                            font.pixelSize: 11
                                            color: activeNavSection === modelData.nav ? "#ffffff" : "#c0c0d0"
                                            Layout.fillWidth: true
                                        }

                                        Rectangle {
                                            height: 16
                                            width: countText.implicitWidth + 8
                                            radius: 2
                                            color: activeNavSection === modelData.nav ? "#1c2638" : "#1e1e24"
                                            Text {
                                                id: countText
                                                anchors.centerIn: parent
                                                text: modelData.count
                                                font.pixelSize: 9
                                                color: activeNavSection === modelData.nav ? "#7ab3ff" : "#777788"
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: navItemMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            activeNavSection = modelData.nav;
                                            mainViewMode = modelData.mode;
                                            bridge.resetFilters();
                                        }
                                    }
                                }
                            }

                            // Section: PLAYLISTS
                            Item { height: 10; width: 1 }
                            Text {
                                text: "  PLAYLISTS & QUEUE"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 1.0
                                color: "#666677"
                                Layout.leftMargin: 8
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 26
                                color: activeNavSection === 4 ? "#24242e" : (npMouse.containsMouse ? "#1c1c22" : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 10
                                    spacing: 8
                                    VectorIcon { name: "queue"; width: 11; height: 11; color: activeNavSection === 4 ? "#3a82f7" : "#777788" }
                                    Text { text: "Now Playing Queue"; font.pixelSize: 11; color: activeNavSection === 4 ? "#ffffff" : "#c0c0d0"; Layout.fillWidth: true }
                                }
                                MouseArea {
                                    id: npMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        activeNavSection = 4;
                                        rightPanelTab = 1;
                                        showRightPanel = true;
                                    }
                                }
                            }

                            // Section: SOURCES
                            Item { height: 10; width: 1 }
                            Text {
                                text: "  SOURCES"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 1.0
                                color: "#666677"
                                Layout.leftMargin: 8
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 26
                                color: scanMouse2.containsMouse ? "#1c1c22" : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 10
                                    spacing: 8
                                    VectorIcon { name: "folder"; width: 11; height: 11; color: "#5c9eff" }
                                    Text { text: "Add Music Folder..."; font.pixelSize: 11; color: "#7ab3ff"; Layout.fillWidth: true }
                                }
                                MouseArea {
                                    id: scanMouse2
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: folderDialog.open()
                                }
                            }

                            // Section: QUALITY FILTERS
                            Item { height: 10; width: 1 }
                            Text {
                                text: "  QUALITY TIERS"
                                font.pixelSize: 9
                                font.bold: true
                                font.letterSpacing: 1.0
                                color: "#666677"
                                Layout.leftMargin: 8
                            }

                            Repeater {
                                model: [
                                    { name: "Hi-Res Audio (24-bit)", filter: "Hi-Res" },
                                    { name: "Lossless FLAC", filter: "FLAC" },
                                    { name: "Standard (MP3/AAC)", filter: "MP3" }
                                ]

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24
                                    color: qfMouse.containsMouse ? "#1c1c22" : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 20
                                        anchors.rightMargin: 10
                                        spacing: 6
                                        Rectangle { width: 4; height: 4; radius: 2; color: "#777788" }
                                        Text { text: modelData.name; font.pixelSize: 10; color: "#9999aa"; Layout.fillWidth: true }
                                    }
                                    MouseArea {
                                        id: qfMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: bridge.search(modelData.filter)
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    // Mini Now-Playing Summary Card at bottom of Left Panel
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 68
                        color: "#121214"
                        border.color: "#222228"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Rectangle {
                                width: 48
                                height: 48
                                color: "#000000"
                                border.color: "#282832"
                                border.width: 1
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: bridge.currentArtUrl
                                    fillMode: Image.PreserveAspectCrop
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: bridge.currentTrackTitle
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: "#ffffff"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: bridge.currentArtist
                                    font.pixelSize: 10
                                    color: "#888899"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: bridge.currentCodec + (bridge.currentBitDepth > 0 ? " " + bridge.currentBitDepth + "-bit" : "")
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: "#5c9eff"
                                }
                            }
                        }
                    }
                }
            }

            // 1px vertical divider
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: "#222228"
                visible: showLeftPanel
            }

            // ---------------------------------------------------------------------
            // CENTER PANEL: MUSICBEE MULTI-VIEW WORKSPACE
            // ---------------------------------------------------------------------
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#18181c"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Top Sub-Toolbar: View Mode Buttons, Alphabet Ribbon & Column Browser Toggle
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        color: "#141417"
                        border.color: "#222228"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            // View Mode Toggle Icons
                            RowLayout {
                                spacing: 2

                                Rectangle {
                                    width: 26
                                    height: 24
                                    radius: 2
                                    color: mainViewMode === 1 ? "#262632" : (vm1Mouse.containsMouse ? "#1e1e24" : "transparent")
                                    border.color: mainViewMode === 1 ? "#3a82f7" : "transparent"
                                    VectorIcon { anchors.centerIn: parent; name: "table"; width: 12; height: 12; color: mainViewMode === 1 ? "#3a82f7" : "#888899" }
                                    MouseArea {
                                        id: vm1Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: mainViewMode = 1
                                    }
                                }

                                Rectangle {
                                    width: 26
                                    height: 24
                                    radius: 2
                                    color: mainViewMode === 0 ? "#262632" : (vm0Mouse.containsMouse ? "#1e1e24" : "transparent")
                                    border.color: mainViewMode === 0 ? "#3a82f7" : "transparent"
                                    VectorIcon { anchors.centerIn: parent; name: "grid"; width: 12; height: 12; color: mainViewMode === 0 ? "#3a82f7" : "#888899" }
                                    MouseArea {
                                        id: vm0Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: mainViewMode = 0
                                    }
                                }

                                Rectangle {
                                    width: 26
                                    height: 24
                                    radius: 2
                                    color: mainViewMode === 2 ? "#262632" : (vm2Mouse.containsMouse ? "#1e1e24" : "transparent")
                                    border.color: mainViewMode === 2 ? "#3a82f7" : "transparent"
                                    VectorIcon { anchors.centerIn: parent; name: "album_tracks"; width: 12; height: 12; color: mainViewMode === 2 ? "#3a82f7" : "#888899" }
                                    MouseArea {
                                        id: vm2Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: mainViewMode = 2
                                    }
                                }
                            }

                            Rectangle { width: 1; height: 16; color: "#282832" }

                            // Toggle Column Browser Button
                            Rectangle {
                                width: colBtnLayout.implicitWidth + 12
                                height: 22
                                radius: 2
                                color: showColumnBrowser ? "#202838" : (cbMouse.containsMouse ? "#1c1c22" : "transparent")
                                border.color: showColumnBrowser ? "#2a4268" : "#282832"

                                RowLayout {
                                    id: colBtnLayout
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "Columns"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: showColumnBrowser ? "#7ab3ff" : "#888899"
                                    }
                                }

                                MouseArea {
                                    id: cbMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: showColumnBrowser = !showColumnBrowser
                                }
                            }

                            // Alphabet Quick Jump Ribbon (Classic MusicBee Feature)
                            Flickable {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                contentWidth: alphaRow.implicitWidth
                                clip: true

                                RowLayout {
                                    id: alphaRow
                                    spacing: 1

                                    Repeater {
                                        model: ["All", "#", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

                                        delegate: Rectangle {
                                            width: alphaText.implicitWidth + 8
                                            height: 20
                                            radius: 2
                                            color: activeLetterFilter === modelData ? "#3a82f7" : (alphaMouse.containsMouse ? "#24242c" : "transparent")

                                            Text {
                                                id: alphaText
                                                anchors.centerIn: parent
                                                text: modelData
                                                font.pixelSize: 10
                                                font.bold: activeLetterFilter === modelData
                                                color: activeLetterFilter === modelData ? "#ffffff" : "#888899"
                                            }

                                            MouseArea {
                                                id: alphaMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    activeLetterFilter = modelData;
                                                    bridge.filterByLetter(modelData);
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Item counter
                            Text {
                                text: bridge.trackModel.count + " tracks"
                                font.pixelSize: 10
                                color: "#777788"
                            }
                        }
                    }

                    // -------------------------------------------------------------
                    // MUSICBEE 3-COLUMN BROWSER (GENRE | ARTIST | ALBUM)
                    // -------------------------------------------------------------
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: showColumnBrowser ? 120 : 0
                        visible: showColumnBrowser
                        color: "#131316"
                        clip: true

                        RowLayout {
                            anchors.fill: parent
                            spacing: 1

                            // Column 1: Genre Filter
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#161619"

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 0

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 20
                                        color: "#1a1a20"
                                        Text { anchors.centerIn: parent; text: "GENRE"; font.pixelSize: 9; font.bold: true; color: "#888899" }
                                    }

                                    ListView {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        model: ["All (" + bridge.totalTracks + ")"].concat(bridge.genresList)

                                        delegate: Rectangle {
                                            width: parent.width
                                            height: 20
                                            color: (selectedGenreFilter === modelData || (modelData.indexOf("All") === 0 && selectedGenreFilter === "All")) ? "#262634" : (gMouse.containsMouse ? "#1d1d24" : "transparent")

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.leftMargin: 8
                                                text: modelData
                                                font.pixelSize: 10
                                                color: (selectedGenreFilter === modelData || (modelData.indexOf("All") === 0 && selectedGenreFilter === "All")) ? "#3a82f7" : "#b0b0be"
                                                elide: Text.ElideRight
                                            }

                                            MouseArea {
                                                id: gMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.indexOf("All") === 0) {
                                                        selectedGenreFilter = "All";
                                                        bridge.filterByGenre("All");
                                                    } else {
                                                        selectedGenreFilter = modelData;
                                                        bridge.filterByGenre(modelData);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Column 2: Artist Filter
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#161619"

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 0

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 20
                                        color: "#1a1a20"
                                        Text { anchors.centerIn: parent; text: "ARTIST"; font.pixelSize: 9; font.bold: true; color: "#888899" }
                                    }

                                    ListView {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        model: ["All (" + bridge.artistsList.length + ")"].concat(bridge.artistsList)

                                        delegate: Rectangle {
                                            width: parent.width
                                            height: 20
                                            color: (selectedArtistFilter === modelData || (modelData.indexOf("All") === 0 && selectedArtistFilter === "All")) ? "#262634" : (aMouse.containsMouse ? "#1d1d24" : "transparent")

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.leftMargin: 8
                                                text: modelData
                                                font.pixelSize: 10
                                                color: (selectedArtistFilter === modelData || (modelData.indexOf("All") === 0 && selectedArtistFilter === "All")) ? "#3a82f7" : "#b0b0be"
                                                elide: Text.ElideRight
                                            }

                                            MouseArea {
                                                id: aMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (modelData.indexOf("All") === 0) {
                                                        selectedArtistFilter = "All";
                                                        bridge.filterByArtist("All");
                                                    } else {
                                                        selectedArtistFilter = modelData;
                                                        bridge.filterByArtist(modelData);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Column 3: Album Filter
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#161619"

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 0

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 20
                                        color: "#1a1a20"
                                        Text { anchors.centerIn: parent; text: "ALBUM"; font.pixelSize: 9; font.bold: true; color: "#888899" }
                                    }

                                    ListView {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        model: bridge.albumModel

                                        delegate: Rectangle {
                                            width: parent.width
                                            height: 20
                                            color: albColMouse.containsMouse ? "#1d1d24" : "transparent"

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                Text {
                                                    text: model.title
                                                    font.pixelSize: 10
                                                    color: "#b0b0be"
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                Text {
                                                    text: model.trackCount
                                                    font.pixelSize: 9
                                                    color: "#666677"
                                                }
                                            }

                                            MouseArea {
                                                id: albColMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    bridge.openAlbumDetails(model.title, model.artist);
                                                    mainViewMode = 2;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 1px divider
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#222228"; visible: showColumnBrowser }

                    // -------------------------------------------------------------
                    // VIEW 1: DENSE TRACK DETAILS TABLE (CLASSIC MUSICBEE DATA VIEW)
                    // -------------------------------------------------------------
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: mainViewMode === 1

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            // Table Header Row
                            Rectangle {
                                Layout.fillWidth: true
                                height: 26
                                color: "#131316"
                                border.color: "#222228"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Item { Layout.preferredWidth: 28; Layout.fillHeight: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "#"; font.pixelSize: 9; font.bold: true; color: "#777788" } }
                                    Item { Layout.preferredWidth: 16; Layout.fillHeight: true }
                                    Item { Layout.fillWidth: true; Layout.preferredWidth: 220; Layout.minimumWidth: 160; Layout.fillHeight: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "TITLE"; font.pixelSize: 9; font.bold: true; color: "#777788" } }
                                    Item { Layout.preferredWidth: 140; Layout.fillHeight: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "ARTIST"; font.pixelSize: 9; font.bold: true; color: "#777788" } }
                                    Item { Layout.preferredWidth: 140; Layout.fillHeight: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "ALBUM"; font.pixelSize: 9; font.bold: true; color: "#777788" } }
                                    Item { Layout.preferredWidth: 100; Layout.fillHeight: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "GENRE"; font.pixelSize: 9; font.bold: true; color: "#777788" } }
                                    Item { Layout.preferredWidth: 46; Layout.fillHeight: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "YEAR"; font.pixelSize: 9; font.bold: true; color: "#777788" } }
                                    Item { Layout.preferredWidth: 76; Layout.fillHeight: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "FORMAT"; font.pixelSize: 9; font.bold: true; color: "#777788" } }
                                    Item { Layout.preferredWidth: 68; Layout.fillHeight: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "BITRATE"; font.pixelSize: 9; font.bold: true; color: "#777788" } }
                                    Item { Layout.preferredWidth: 46; Layout.fillHeight: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "TIME"; font.pixelSize: 9; font.bold: true; color: "#777788" } }
                                }
                            }

                            // Table Rows ScrollView
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                                ListView {
                                    id: trackTableListView
                                    anchors.fill: parent
                                    model: bridge.trackModel
                                    clip: true

                                    delegate: Rectangle {
                                        width: trackTableListView.width
                                        height: 25
                                        color: (bridge.currentFilePath === model.filePath) ? "#1f2a3e" : (tableRowMouse.containsMouse ? "#202028" : (index % 2 === 0 ? "#17171a" : "#141417"))

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 8

                                            Item {
                                                Layout.preferredWidth: 28
                                                Layout.fillHeight: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: model.trackNumber > 0 ? model.trackNumber : (index + 1)
                                                    font.pixelSize: 10
                                                    color: (bridge.currentFilePath === model.filePath) ? "#5c9eff" : "#666677"
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 16
                                                Layout.fillHeight: true
                                                VectorIcon {
                                                    anchors.centerIn: parent
                                                    visible: bridge.currentFilePath === model.filePath
                                                    name: bridge.isPlaying ? "volume" : "play"
                                                    width: 10
                                                    height: 10
                                                    color: "#3a82f7"
                                                }
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                                Layout.preferredWidth: 220
                                                Layout.minimumWidth: 160
                                                Layout.fillHeight: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    text: model.title
                                                    font.pixelSize: 11
                                                    font.bold: (bridge.currentFilePath === model.filePath)
                                                    color: (bridge.currentFilePath === model.filePath) ? "#ffffff" : "#d8d8e0"
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 140
                                                Layout.fillHeight: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    text: model.artist
                                                    font.pixelSize: 11
                                                    color: (bridge.currentFilePath === model.filePath) ? "#b0b0c0" : "#9999aa"
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 140
                                                Layout.fillHeight: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    text: model.album
                                                    font.pixelSize: 11
                                                    color: "#777788"
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 100
                                                Layout.fillHeight: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    text: model.genre
                                                    font.pixelSize: 10
                                                    color: "#666677"
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 46
                                                Layout.fillHeight: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: model.year > 0 ? model.year : ""
                                                    font.pixelSize: 10
                                                    color: "#666677"
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 76
                                                Layout.fillHeight: true
                                                Rectangle {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: 72
                                                    height: 17
                                                    radius: 2
                                                    color: model.codec === "FLAC" ? "#1a2536" : "#1a1a22"
                                                    border.color: model.codec === "FLAC" ? "#283b58" : "#282832"

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: model.codec + (model.bitDepth > 16 ? " " + model.bitDepth + "b" : "")
                                                        font.pixelSize: 9
                                                        font.bold: true
                                                        color: model.codec === "FLAC" ? "#7ab3ff" : "#888899"
                                                    }
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 68
                                                Layout.fillHeight: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: model.bitrate > 0 ? model.bitrate + " kbps" : ""
                                                    font.pixelSize: 10
                                                    color: "#777788"
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 46
                                                Layout.fillHeight: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: model.durationFormatted
                                                    font.pixelSize: 10
                                                    color: "#888899"
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: tableRowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onDoubleClicked: bridge.playTrackAtIndex(index)
                                            onClicked: {
                                                bridge.openAlbumDetails(model.album, model.artist);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // -------------------------------------------------------------
                    // VIEW 2: ALBUM GRID VIEW
                    // -------------------------------------------------------------
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: mainViewMode === 0
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded

                        GridView {
                            id: albumGridView
                            anchors.fill: parent
                            anchors.margins: 14
                            cellWidth: Math.max(170, width / Math.floor(width / 175))
                            cellHeight: 230
                            model: bridge.albumModel
                            clip: true

                            delegate: Rectangle {
                                width: albumGridView.cellWidth - 10
                                height: albumGridView.cellHeight - 10
                                radius: 4
                                color: albCardMouse.containsMouse ? "#202028" : "#17171a"
                                border.color: albCardMouse.containsMouse ? "#3a82f7" : "#24242c"
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: width
                                        color: "#0c0c0e"
                                        border.color: "#222228"
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            source: "image://albumart/" + (model.artHash ? model.artHash : "default")
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                        }

                                        // Quality Badge
                                        Rectangle {
                                            anchors.top: parent.top
                                            anchors.right: parent.right
                                            anchors.margins: 4
                                            height: 16
                                            width: qBadgeText.implicitWidth + 8
                                            radius: 2
                                            color: model.qualityBadge === "Hi-Res Lossless" ? "#1e3352" : "#1a1a22"
                                            border.color: model.qualityBadge === "Hi-Res Lossless" ? "#38659f" : "#2a2a34"

                                            Text {
                                                id: qBadgeText
                                                anchors.centerIn: parent
                                                text: model.qualityBadge === "Hi-Res Lossless" ? "HI-RES" : "LOSSLESS"
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: model.qualityBadge === "Hi-Res Lossless" ? "#84beff" : "#a0a0b0"
                                            }
                                        }

                                        // Hover Play Button
                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.right: parent.right
                                            anchors.margins: 6
                                            width: 28
                                            height: 28
                                            radius: 14
                                            color: "#3a82f7"
                                            visible: albCardMouse.containsMouse

                                            VectorIcon {
                                                anchors.centerIn: parent
                                                name: "play"
                                                width: 12
                                                height: 12
                                                color: "#ffffff"
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: bridge.playAlbum(model.title, model.artist)
                                            }
                                        }
                                    }

                                    Text {
                                        text: model.title
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: "#ffffff"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: model.artist + (model.year > 0 ? " • " + model.year : "")
                                        font.pixelSize: 10
                                        color: "#888899"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: model.trackCount + " tracks • " + model.primaryCodec
                                        font.pixelSize: 9
                                        color: "#5c9eff"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    id: albCardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        bridge.openAlbumDetails(model.title, model.artist);
                                        mainViewMode = 2;
                                    }
                                }
                            }
                        }
                    }

                    // -------------------------------------------------------------
                    // VIEW 3: ALBUM & TRACKS VIEW (EXPANDED ALBUM BANNER)
                    // -------------------------------------------------------------
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: mainViewMode === 2

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            // Expanded Album Header Banner
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 140
                                color: "#141418"
                                border.color: "#222228"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 16

                                    Rectangle {
                                        width: 116
                                        height: 116
                                        color: "#000000"
                                        border.color: "#282832"
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            source: "image://albumart/" + (bridge.selectedAlbumArtHash ? bridge.selectedAlbumArtHash : "default")
                                            fillMode: Image.PreserveAspectCrop
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        RowLayout {
                                            spacing: 8
                                            Text {
                                                text: bridge.selectedAlbumTitle.length > 0 ? bridge.selectedAlbumTitle : "Select an Album"
                                                font.pixelSize: 18
                                                font.bold: true
                                                color: "#ffffff"
                                            }

                                            Rectangle {
                                                height: 18
                                                width: albQualBadge.implicitWidth + 8
                                                radius: 2
                                                color: "#1e3352"
                                                border.color: "#38659f"
                                                Text {
                                                    id: albQualBadge
                                                    anchors.centerIn: parent
                                                    text: bridge.selectedAlbumQuality
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    color: "#84beff"
                                                }
                                            }
                                        }

                                        Text {
                                            text: bridge.selectedAlbumArtist + (bridge.selectedAlbumYear ? " (" + bridge.selectedAlbumYear + ")" : "")
                                            font.pixelSize: 13
                                            color: "#3a82f7"
                                        }

                                        Text {
                                            text: (bridge.selectedAlbumGenre ? bridge.selectedAlbumGenre + " • " : "") +
                                                  bridge.selectedAlbumTrackCount + " Tracks • " +
                                                  bridge.selectedAlbumDuration
                                            font.pixelSize: 11
                                            color: "#888899"
                                        }

                                        Item { height: 4; width: 1 }

                                        RowLayout {
                                            spacing: 8

                                            Rectangle {
                                                width: albPlayBtnText.implicitWidth + 20
                                                height: 26
                                                radius: 2
                                                color: albPlayMouse.containsMouse ? "#458eff" : "#3a82f7"

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 6
                                                    VectorIcon { name: "play"; width: 10; height: 10; color: "#ffffff" }
                                                    Text { id: albPlayBtnText; text: "Play Album"; font.pixelSize: 11; font.bold: true; color: "#ffffff" }
                                                }

                                                MouseArea {
                                                    id: albPlayMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: bridge.playAlbum(bridge.selectedAlbumTitle, bridge.selectedAlbumArtist)
                                                }
                                            }

                                            Rectangle {
                                                width: backToGridText.implicitWidth + 16
                                                height: 26
                                                radius: 2
                                                color: backGridMouse.containsMouse ? "#24242c" : "#1c1c22"
                                                border.color: "#2c2c36"

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 6
                                                    VectorIcon { name: "grid"; width: 10; height: 10; color: "#888899" }
                                                    Text { id: backToGridText; text: "All Albums"; font.pixelSize: 11; color: "#888899" }
                                                }

                                                MouseArea {
                                                    id: backGridMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: mainViewMode = 0
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Album Tracklist Table
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                                ListView {
                                    id: albumDetailListView
                                    anchors.fill: parent
                                    model: bridge.albumDetailTrackModel
                                    clip: true

                                    delegate: Rectangle {
                                        width: albumDetailListView.width
                                        height: 26
                                        color: (bridge.currentFilePath === model.filePath) ? "#1f2a3e" : (dtRowMouse.containsMouse ? "#202028" : (index % 2 === 0 ? "#17171a" : "#141417"))

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 10

                                            Text {
                                                text: model.trackNumber > 0 ? model.trackNumber : (index + 1)
                                                font.pixelSize: 10
                                                color: (bridge.currentFilePath === model.filePath) ? "#5c9eff" : "#666677"
                                                Layout.preferredWidth: 28
                                            }

                                            VectorIcon {
                                                visible: bridge.currentFilePath === model.filePath
                                                name: bridge.isPlaying ? "volume" : "play"
                                                width: 10
                                                height: 10
                                                color: "#3a82f7"
                                                Layout.preferredWidth: 14
                                            }

                                            Text {
                                                text: model.title
                                                font.pixelSize: 11
                                                font.bold: (bridge.currentFilePath === model.filePath)
                                                color: (bridge.currentFilePath === model.filePath) ? "#ffffff" : "#d0d0d8"
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: model.artist
                                                font.pixelSize: 10
                                                color: "#888899"
                                                Layout.preferredWidth: 140
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: model.codec + " " + model.sampleRate / 1000 + "kHz"
                                                font.pixelSize: 9
                                                color: "#5c9eff"
                                                Layout.preferredWidth: 90
                                            }

                                            Text {
                                                text: model.durationFormatted
                                                font.pixelSize: 10
                                                color: "#888899"
                                                Layout.preferredWidth: 45
                                            }
                                        }

                                        MouseArea {
                                            id: dtRowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onDoubleClicked: bridge.playTrackFromDetail(index)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // 1px vertical divider
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: "#222228"
                visible: showRightPanel
            }

            // ---------------------------------------------------------------------
            // RIGHT PANEL: MUSICBEE AUDIOPHILE INSPECTOR & NOW PLAYING QUEUE
            // ---------------------------------------------------------------------
            Rectangle {
                Layout.preferredWidth: 270
                Layout.fillHeight: true
                color: "#151518"
                visible: showRightPanel

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Right Panel Tabs
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        color: "#121214"
                        border.color: "#222228"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: rightPanelTab === 0 ? "#1c1c22" : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "PROPERTIES"
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.letterSpacing: 1.0
                                    color: rightPanelTab === 0 ? "#ffffff" : "#777788"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rightPanelTab = 0
                                }
                            }

                            Rectangle { width: 1; height: 16; color: "#25252b" }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: rightPanelTab === 1 ? "#1c1c22" : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "PLAY QUEUE"
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.letterSpacing: 1.0
                                    color: rightPanelTab === 1 ? "#ffffff" : "#777788"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rightPanelTab = 1
                                }
                            }
                        }
                    }

                    // TAB 0: TRACK PROPERTIES & AUDIOPHILE SPECS
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: rightPanelTab === 0
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded

                        ColumnLayout {
                            width: 270
                            spacing: 10

                            // Large Album Cover Art
                            Item { height: 4; width: 1 }
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 236
                                Layout.preferredHeight: 236
                                color: "#0c0c0e"
                                border.color: "#282832"
                                border.width: 1
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: bridge.currentArtUrl
                                    fillMode: Image.PreserveAspectCrop
                                }
                            }

                            // Track Title & Artist
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 16
                                Layout.rightMargin: 16
                                spacing: 2

                                Text {
                                    text: bridge.currentTrackTitle
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#ffffff"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: bridge.currentArtist
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: "#3a82f7"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: bridge.currentAlbum + (bridge.currentYear.length > 0 ? " (" + bridge.currentYear + ")" : "")
                                    font.pixelSize: 11
                                    color: "#888899"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Dense Technical Specs Table
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 12
                                Layout.rightMargin: 12
                                Layout.preferredHeight: specGrid.implicitHeight + 16
                                color: "#18181e"
                                border.color: "#24242e"
                                border.width: 1
                                radius: 3

                                GridLayout {
                                    id: specGrid
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    columns: 2
                                    rowSpacing: 5
                                    columnSpacing: 10

                                    Text { text: "Container:"; font.pixelSize: 10; font.bold: true; color: "#777788" }
                                    Text { text: bridge.currentCodec.length > 0 ? bridge.currentCodec : "—"; font.pixelSize: 10; color: "#e0e0e0" }

                                    Text { text: "Bit Depth:"; font.pixelSize: 10; font.bold: true; color: "#777788" }
                                    Text { text: bridge.currentBitDepth > 0 ? bridge.currentBitDepth + "-bit" : "—"; font.pixelSize: 10; color: "#5c9eff" }

                                    Text { text: "Sample Rate:"; font.pixelSize: 10; font.bold: true; color: "#777788" }
                                    Text { text: bridge.currentSampleRate > 0 ? bridge.currentSampleRate + " Hz" : "—"; font.pixelSize: 10; color: "#5c9eff" }

                                    Text { text: "Bitrate:"; font.pixelSize: 10; font.bold: true; color: "#777788" }
                                    Text { text: bridge.currentBitrate > 0 ? bridge.currentBitrate + " kbps" : "—"; font.pixelSize: 10; color: "#e0e0e0" }

                                    Text { text: "Channels:"; font.pixelSize: 10; font.bold: true; color: "#777788" }
                                    Text { text: bridge.currentChannels === 2 ? "Stereo (2.0)" : (bridge.currentChannels === 1 ? "Mono" : (bridge.currentChannels > 2 ? bridge.currentChannels + " Ch" : "—")); font.pixelSize: 10; color: "#e0e0e0" }

                                    Text { text: "File Size:"; font.pixelSize: 10; font.bold: true; color: "#777788" }
                                    Text { text: bridge.currentFileSizeStr.length > 0 ? bridge.currentFileSizeStr : "—"; font.pixelSize: 10; color: "#e0e0e0" }

                                    Text { text: "Engine Mode:"; font.pixelSize: 10; font.bold: true; color: "#777788" }
                                    Text { text: "Direct PCM (Lossless)"; font.pixelSize: 10; font.bold: true; color: "#28c840" }
                                }
                            }

                            // Full File Path Box
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 14
                                Layout.rightMargin: 14
                                spacing: 3

                                Text {
                                    text: "FILE LOCATION"
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 1.0
                                    color: "#666677"
                                }

                                Text {
                                    text: bridge.currentFilePath.length > 0 ? bridge.currentFilePath : "No file loaded"
                                    font.pixelSize: 9
                                    color: "#888899"
                                    wrapMode: Text.WrapAnywhere
                                    Layout.fillWidth: true
                                }
                            }

                            Item { height: 10; width: 1 }
                        }
                    }

                    // TAB 1: PLAY QUEUE
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: rightPanelTab === 1

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                                ListView {
                                    id: queueListView
                                    anchors.fill: parent
                                    model: bridge.queueTrackModel
                                    clip: true

                                    delegate: Rectangle {
                                        width: queueListView.width
                                        height: 32
                                        color: (bridge.currentFilePath === model.filePath) ? "#1e2c44" : (qRowMouse.containsMouse ? "#1c1c22" : "transparent")
                                        border.color: (bridge.currentFilePath === model.filePath) ? "#2a4268" : "transparent"
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 8

                                            VectorIcon {
                                                visible: bridge.currentFilePath === model.filePath
                                                name: bridge.isPlaying ? "volume" : "play"
                                                width: 10
                                                height: 10
                                                color: "#3a82f7"
                                            }

                                            Text {
                                                text: (index + 1) + "."
                                                font.pixelSize: 10
                                                color: "#666677"
                                                visible: bridge.currentFilePath !== model.filePath
                                                Layout.preferredWidth: 16
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1

                                                Text {
                                                    text: model.title
                                                    font.pixelSize: 11
                                                    font.bold: bridge.currentFilePath === model.filePath
                                                    color: bridge.currentFilePath === model.filePath ? "#ffffff" : "#d0d0d8"
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    text: model.artist
                                                    font.pixelSize: 9
                                                    color: "#777788"
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            Text {
                                                text: model.durationFormatted
                                                font.pixelSize: 9
                                                color: "#888899"
                                            }
                                        }

                                        MouseArea {
                                            id: qRowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: bridge.playQueueTrack(index)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 1px divider
        Rectangle { Layout.fillWidth: true; height: 1; color: "#222228" }

        // =========================================================================
        // ROW 4: BOTTOM AUDIOPHILE TRANSPORT DECK
        // =========================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 74
            color: "#111113"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 16

                // Left: Now Playing Preview
                RowLayout {
                    Layout.preferredWidth: 310
                    spacing: 12

                    Rectangle {
                        width: 48
                        height: 48
                        color: "#08080a"
                        border.color: "#24242e"
                        border.width: 1
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: bridge.currentArtUrl
                            fillMode: Image.PreserveAspectCrop
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: bridge.currentTrackTitle
                            font.pixelSize: 12
                            font.bold: true
                            color: "#ffffff"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: bridge.currentArtist + (bridge.currentAlbum.length > 0 ? " • " + bridge.currentAlbum : "")
                            font.pixelSize: 10
                            color: "#9090a0"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            height: 16
                            width: deckSpecText.implicitWidth + 8
                            radius: 2
                            color: "#181822"
                            border.color: "#282834"

                            Text {
                                id: deckSpecText
                                anchors.centerIn: parent
                                text: bridge.currentAudioSpecs
                                font.pixelSize: 8
                                font.bold: true
                                color: "#8cbfff"
                            }
                        }
                    }
                }

                // Center: Transport Controls & Scrubber Timeline
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    // Control Buttons Row
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 16

                        // Shuffle Button
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 2
                            color: shufMouse.containsMouse ? "#24242c" : "transparent"
                            VectorIcon { anchors.centerIn: parent; name: "shuffle"; width: 13; height: 13; color: "#888899" }
                            MouseArea {
                                id: shufMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bridge.shuffleAll()
                            }
                        }

                        // Previous Button
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 2
                            color: prevMouse.containsMouse ? "#262632" : "transparent"
                            VectorIcon { anchors.centerIn: parent; name: "previous"; width: 14; height: 14; color: "#e0e0e0" }
                            MouseArea {
                                id: prevMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bridge.previousTrack()
                            }
                        }

                        // Stop Button
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 2
                            color: stopMouse.containsMouse ? "#262632" : "transparent"
                            VectorIcon { anchors.centerIn: parent; name: "stop"; width: 12; height: 12; color: "#c0c0cc" }
                            MouseArea {
                                id: stopMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bridge.stop()
                            }
                        }

                        // Play / Pause Primary Action Button (Clean crisp high-contrast button)
                        Rectangle {
                            width: 36
                            height: 36
                            radius: 18
                            color: playPauseMouse.containsMouse ? "#ffffff" : "#e6e6e6"

                            VectorIcon {
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: bridge.isPlaying ? 0 : 1
                                name: bridge.isPlaying ? "pause" : "play"
                                width: 16
                                height: 16
                                color: "#111114"
                            }

                            MouseArea {
                                id: playPauseMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bridge.togglePlayPause()
                            }
                        }

                        // Next Button
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 2
                            color: nextMouse.containsMouse ? "#262632" : "transparent"
                            VectorIcon { anchors.centerIn: parent; name: "next"; width: 14; height: 14; color: "#e0e0e0" }
                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bridge.nextTrack()
                            }
                        }

                        // Repeat Button
                        Rectangle {
                            width: 24
                            height: 24
                            radius: 2
                            color: repMouse.containsMouse ? "#24242c" : "transparent"
                            VectorIcon { anchors.centerIn: parent; name: "repeat"; width: 13; height: 13; color: "#888899" }
                            MouseArea {
                                id: repMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    // Scrubber Timeline Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: bridge.positionStr
                            font.pixelSize: 10
                            color: "#888899"
                            Layout.preferredWidth: 36
                            horizontalAlignment: Text.AlignRight
                        }

                        // Custom Clean Timeline Slider (Zero gradients!)
                        Slider {
                            id: timelineSlider
                            Layout.fillWidth: true
                            from: 0
                            to: Math.max(1, bridge.durationMs)
                            value: bridge.positionMs
                            onMoved: {
                                bridge.seek(value)
                            }

                            background: Rectangle {
                                x: timelineSlider.leftPadding
                                y: timelineSlider.topPadding + timelineSlider.availableHeight / 2 - 2
                                implicitWidth: 200
                                implicitHeight: 4
                                width: timelineSlider.availableWidth
                                height: 4
                                radius: 2
                                color: "#22222a"

                                Rectangle {
                                    width: timelineSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: "#3a82f7"
                                    radius: 2
                                }
                            }

                            handle: Rectangle {
                                x: timelineSlider.leftPadding + timelineSlider.visualPosition * (timelineSlider.availableWidth - width)
                                y: timelineSlider.topPadding + timelineSlider.availableHeight / 2 - height / 2
                                implicitWidth: 10
                                implicitHeight: 10
                                radius: 5
                                color: timelineSlider.pressed ? "#ffffff" : "#c8d8f8"
                            }
                        }

                        Text {
                            text: bridge.durationStr
                            font.pixelSize: 10
                            color: "#888899"
                            Layout.preferredWidth: 36
                        }
                    }
                }

                // Right: Volume & Tool Toggles
                RowLayout {
                    Layout.preferredWidth: 260
                    spacing: 10

                    VectorIcon {
                        name: bridge.isMuted ? "volume_mute" : "volume"
                        width: 14
                        height: 14
                        color: "#9999aa"
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bridge.toggleMute()
                        }
                    }

                    Slider {
                        id: volumeSlider
                        Layout.preferredWidth: 80
                        from: 0
                        to: 1
                        value: bridge.volume
                        onMoved: bridge.setVolume(value)

                        background: Rectangle {
                            x: volumeSlider.leftPadding
                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - 2
                            implicitWidth: 80
                            implicitHeight: 4
                            width: volumeSlider.availableWidth
                            height: 4
                            radius: 2
                            color: "#22222a"

                            Rectangle {
                                width: volumeSlider.visualPosition * parent.width
                                height: parent.height
                                color: "#a0a0b0"
                                radius: 2
                            }
                        }

                        handle: Rectangle {
                            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                            implicitWidth: 8
                            implicitHeight: 8
                            radius: 4
                            color: "#e0e0e0"
                        }
                    }

                    Text {
                        text: Math.round(bridge.volume * 100) + "%"
                        font.pixelSize: 9
                        color: "#777788"
                        Layout.preferredWidth: 26
                    }

                    Rectangle { width: 1; height: 16; color: "#25252b" }

                    // Fullscreen Toggle
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 2
                        color: fsMouse.containsMouse ? "#24242c" : "transparent"
                        VectorIcon { anchors.centerIn: parent; name: "fullscreen"; width: 12; height: 12; color: "#888899" }
                        MouseArea {
                            id: fsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.visibility === Window.FullScreen) {
                                    root.visibility = Window.Windowed;
                                } else {
                                    root.visibility = Window.FullScreen;
                                }
                            }
                        }
                    }
                }
            }
        }

        // =========================================================================
        // ROW 5: BOTTOM STATUS BAR (Classic MusicBee Detailed Information Strip)
        // =========================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            color: "#0d0d0f"
            border.color: "#1c1c22"
            border.width: 1
            visible: showStatusBar

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                Text {
                    text: bridge.totalTracks + " tracks | " +
                          bridge.totalAlbums + " albums | " +
                          bridge.totalLibrarySizeStr + " | Total Time: " +
                          bridge.totalDurationStr
                    font.pixelSize: 9
                    color: "#707080"
                }

                Item { Layout.fillWidth: true }

                // Indexing / scanning status
                RowLayout {
                    spacing: 6

                    Rectangle {
                        width: 5
                        height: 5
                        radius: 2.5
                        color: bridge.isScanning ? "#3a82f7" : "#555566"
                    }

                    Text {
                        text: bridge.scanStatusText
                        font.pixelSize: 9
                        color: bridge.isScanning ? "#5c9eff" : "#707080"
                    }
                }

                Rectangle { width: 1; height: 12; color: "#202028" }

                Text {
                    text: "Parakeet v0.1.0 • Direct PCM Output"
                    font.pixelSize: 9
                    color: "#555566"
                }
            }
        }
    }
}

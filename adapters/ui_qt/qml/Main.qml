import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "components"
import "dialogs"
import "views"

ApplicationWindow {
    id: root
    width: 1400
    height: 840
    minimumWidth: 1024
    minimumHeight: 640
    visible: true
    title: "Parakeet Music Player"
    color: Theme.background

    // Panel visibility and navigation state
    property bool showLeftPanel: true
    property bool showRightPanel: true
    property bool showColumnBrowser: true
    property bool showStatusBar: true
    property bool showEqualizer: false
    property bool isMiniPlayer: false
    property real normalWidth: 1400
    property int mainViewMode: 1 // 0: Album Grid, 1: Track Details Table, 2: Album & Tracks View, 3: Listening History
    property int previousViewMode: 0
    property int activeNavSection: 0 // 0: All Tracks, 1: Albums, 2: Artists, 3: Genres, 4: Now Playing
    property string activeLetterFilter: "All"
    property string selectedGenreFilter: "All"
    property string selectedArtistFilter: "All"
    property int rightPanelTab: 0 // 0: Properties, 1: Queue

    function switchToExpandedView(albumTitle, albumArtist) {
        if (albumTitle && albumTitle.length > 0) {
            bridge.openAlbumDetails(albumTitle, albumArtist ? albumArtist : "");
        } else if (bridge.selectedAlbumTitle.length === 0) {
            if (bridge.currentAlbum.length > 0) {
                bridge.openAlbumDetails(bridge.currentAlbum, bridge.currentArtist);
            } else if (bridge.albumModel.count > 0) {
                var firstAlb = bridge.albumModel.getAlbumAt(0);
                if (firstAlb && firstAlb.title) {
                    bridge.openAlbumDetails(firstAlb.title, firstAlb.artist);
                }
            }
        }
        if (mainViewMode !== 2) {
            previousViewMode = mainViewMode;
        }
        mainViewMode = 2;
        activeNavSection = 1;
    }

    function switchToNowPlaying() {
        rightPanelTab = 1;
        showRightPanel = true;
        activeNavSection = 4;
        if (bridge.currentAlbum.length > 0) {
            bridge.openAlbumDetails(bridge.currentAlbum, bridge.currentArtist);
            if (mainViewMode !== 2) {
                previousViewMode = mainViewMode;
            }
            mainViewMode = 2;
        }
    }

    function switchViewMode(mode) {
        if (mode === 2) {
            switchToExpandedView();
            return;
        }
        if (mainViewMode === 2) {
            previousViewMode = 2;
        }
        mainViewMode = mode;
        if (mode === 1) {
            activeNavSection = 0;
        } else if (mode === 0) {
            activeNavSection = 1;
        } else if (mode === 3) {
            bridge.refreshHistory();
        }
    }

    function toggleMiniPlayer() {
        if (!isMiniPlayer) {
            normalWidth = root.width;
            normalHeight = root.height;
            root.minimumWidth = 380;
            root.minimumHeight = 120;
            root.width = 440;
            root.height = 140;
            isMiniPlayer = true;
        } else {
            root.minimumWidth = 1024;
            root.minimumHeight = 640;
            root.width = Math.max(1024, normalWidth);
            root.height = Math.max(640, normalHeight);
            isMiniPlayer = false;
        }
    }

    function toggleFullscreen() {
        if (root.visibility === Window.FullScreen) {
            root.visibility = Window.Windowed;
        } else {
            root.visibility = Window.FullScreen;
        }
    }

    function zoomIn() {
        Theme.uiScale = Math.min(1.5, Math.round((Theme.uiScale + 0.1) * 10) / 10);
    }

    function zoomOut() {
        Theme.uiScale = Math.max(0.7, Math.round((Theme.uiScale - 0.1) * 10) / 10);
    }

    function zoomReset() {
        Theme.uiScale = 1.0;
    }

    function formatTimestamp(ms) {
        if (ms < 0) return "--:--";
        var totalSec = Math.floor(ms / 1000);
        var mins = Math.floor(totalSec / 60);
        var secs = totalSec % 60;
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    PreferencesDialog {
        id: preferencesDialog
    }

    TagEditorDialog {
        id: tagEditorDialog
    }

    OpenUrlDialog {
        id: openUrlDialog
    }

    ShortcutsDialog {
        id: shortcutsDialog
    }

    DiagnosticsDialog {
        id: diagnosticsDialog
    }

    AboutDialog {
        id: aboutDialog
    }

    SleepTimerDialog {
        id: sleepTimerDialog
    }

    NewPlaylistDialog {
        id: newPlaylistDialog
    }

    FileDialog {
        id: importPlaylistDialog
        title: "Import Playlist File"
        nameFilters: ["Playlist files (*.m3u *.m3u8 *.pls *.xspf)", "All files (*)"]
        onAccepted: bridge.importPlaylist(selectedFile.toString())
    }

    FileDialog {
        id: openAudioFileDialog
        title: "Open Audio File"
        nameFilters: ["Audio files (*.mp3 *.flac *.wav *.ogg *.opus *.m4a *.aac *.alac *.aiff *.ape *.wv *.dsf *.dff)", "All files (*)"]
        onAccepted: bridge.openAudioFile(selectedFile.toString())
    }

    FolderDialog {
        id: openMusicFolderDialog
        title: "Open Music Folder"
        onAccepted: bridge.openFolder(selectedFolder.toString(), false)
    }

    FileDialog {
        id: openCueSheetDialog
        title: "Open CUE Sheet"
        nameFilters: ["CUE Sheet files (*.cue)", "All files (*)"]
        onAccepted: bridge.openCueSheet(selectedFile.toString())
    }

    FileDialog {
        id: exportViewDialog
        title: "Export Active View / Playlist"
        fileMode: FileDialog.SaveFile
        nameFilters: ["M3U8 Playlist (*.m3u8)", "CSV Spreadsheet (*.csv)", "JSON Data (*.json)"]
        onAccepted: {
            var path = selectedFile.toString();
            var lower = path.toLowerCase();
            var fmt = "m3u8";
            if (lower.indexOf(".csv") !== -1) {
                fmt = "csv";
            } else if (lower.indexOf(".json") !== -1) {
                fmt = "json";
            }
            bridge.exportActiveView(path, fmt);
        }
    }

    ContextMenu {
        id: trackContextMenu
        menuType: "track"
        onViewTrackPropertiesRequested: {
            showRightPanel = true;
            rightPanelTab = 0;
        }
        onViewAlbumRequested: (album, artist) => {
            switchToExpandedView(album, artist);
        }
        onEditTagsRequested: (track) => {
            var sel = bridge.trackModel.getSelectedTracks();
            if (sel.length > 1) {
                tagEditorDialog.targetTracks = sel;
                tagEditorDialog.targetTrack = sel[0];
            } else {
                tagEditorDialog.targetTracks = [];
                tagEditorDialog.targetTrack = track;
            }
            tagEditorDialog.open();
        }
        onDeleteTracksRequested: (tracks) => {
            var ids = [];
            for (var i = 0; i < tracks.length; ++i) {
                if (tracks[i].id) ids.push(tracks[i].id);
            }
            if (ids.length > 0) {
                bridge.deleteSelectedTracks(ids);
            }
        }
    }

    ContextMenu {
        id: explorerContextMenu
        menuType: "explorer"
    }

    // Keyboard shortcuts - Playback Transport
    Shortcut { sequence: "Space"; onActivated: bridge.togglePlayPause() }
    Shortcut { sequence: "Shift+Space"; onActivated: bridge.toggleStopAfterCurrentTrack() }
    Shortcut { sequence: "Ctrl+Right"; onActivated: bridge.nextTrack() }
    Shortcut { sequence: "Ctrl+Left"; onActivated: bridge.previousTrack() }
    Shortcut { sequence: "Ctrl+Up"; onActivated: bridge.setVolume(bridge.volume + 0.05) }
    Shortcut { sequence: "Ctrl+Down"; onActivated: bridge.setVolume(bridge.volume - 0.05) }
    Shortcut { sequence: "Ctrl+M"; onActivated: bridge.toggleMute() }
    Shortcut { sequence: "Ctrl+S"; onActivated: bridge.cycleShuffleMode() }
    Shortcut { sequence: "Ctrl+R"; onActivated: bridge.cycleRepeatMode() }
    Shortcut { sequence: "Ctrl+."; onActivated: bridge.stop() }
    Shortcut { sequence: "Left"; onActivated: bridge.seek(bridge.positionMs - 5000) }
    Shortcut { sequence: "Right"; onActivated: bridge.seek(bridge.positionMs + 5000) }
    Shortcut { sequence: "Shift+Left"; onActivated: bridge.seek(bridge.positionMs - 30000) }
    Shortcut { sequence: "Shift+Right"; onActivated: bridge.seek(bridge.positionMs + 30000) }
    Shortcut { sequence: "Home"; onActivated: bridge.seek(0) }
    Shortcut { sequence: "End"; onActivated: bridge.seek(bridge.durationMs) }
    Shortcut { sequence: "["; onActivated: bridge.setLoopPointA() }
    Shortcut { sequence: "]"; onActivated: bridge.setLoopPointB() }
    Shortcut { sequence: "\\"; onActivated: bridge.clearLoop() }

    // Media Keys
    Shortcut { sequence: "MediaPlay"; onActivated: bridge.togglePlayPause() }
    Shortcut { sequence: "MediaPause"; onActivated: bridge.togglePlayPause() }
    Shortcut { sequence: "MediaTogglePlayPause"; onActivated: bridge.togglePlayPause() }
    Shortcut { sequence: "MediaStop"; onActivated: bridge.stop() }
    Shortcut { sequence: "MediaNext"; onActivated: bridge.nextTrack() }
    Shortcut { sequence: "MediaPrevious"; onActivated: bridge.previousTrack() }
    Shortcut { sequence: "AudioRaiseVolume"; onActivated: bridge.setVolume(bridge.volume + 0.05) }
    Shortcut { sequence: "AudioLowerVolume"; onActivated: bridge.setVolume(bridge.volume - 0.05) }
    Shortcut { sequence: "AudioMute"; onActivated: bridge.toggleMute() }

    // Keyboard shortcuts - File & Library Operations
    Shortcut { sequence: "Ctrl+O"; onActivated: openAudioFileDialog.open() }
    Shortcut { sequence: "Ctrl+Shift+O"; onActivated: openMusicFolderDialog.open() }
    Shortcut { sequence: "Ctrl+U"; onActivated: openUrlDialog.open() }
    Shortcut { sequence: "Ctrl+N"; onActivated: { newPlaylistDialog.isSmart = false; newPlaylistDialog.open(); } }
    Shortcut { sequence: "Ctrl+Shift+N"; onActivated: newPlaylistDialog.openSmart() }
    Shortcut { sequence: "F5"; onActivated: bridge.rescanAllMonitoredFolders() }
    Shortcut { sequence: "Ctrl+F5"; onActivated: bridge.incrementalQuickScan() }
    Shortcut { sequence: "Ctrl+E"; onActivated: exportViewDialog.open() }
    Shortcut { sequence: "Ctrl+,"; onActivated: preferencesDialog.open() }
    Shortcut { sequence: "Ctrl+W"; onActivated: root.hide() }
    Shortcut { sequence: "Ctrl+Q"; onActivated: Qt.quit() }

    // Keyboard shortcuts - Edit & Selection Operations
    Shortcut { sequence: "Ctrl+Z"; onActivated: bridge.undo() }
    Shortcut { sequence: "Ctrl+Y"; onActivated: bridge.redo() }
    Shortcut { sequence: "Ctrl+Shift+Z"; onActivated: bridge.redo() }
    Shortcut { sequence: "Ctrl+A"; onActivated: bridge.trackModel.selectAll() }
    Shortcut { sequence: "Ctrl+Shift+A"; onActivated: bridge.trackModel.invertSelection() }
    Shortcut { sequence: "Ctrl+F"; onActivated: { searchTextInput.forceActiveFocus(); searchTextInput.selectAll(); } }
    Shortcut { sequence: "Shift+Escape"; onActivated: { searchTextInput.text = ""; bridge.search(""); } }
    Shortcut {
        sequence: "Ctrl+T"
        onActivated: {
            var sel = bridge.trackModel.getSelectedTracks();
            if (sel.length > 0) {
                tagEditorDialog.targetTracks = sel.length > 1 ? sel : [];
                tagEditorDialog.targetTrack = sel[0];
                tagEditorDialog.open();
            }
        }
    }
    Shortcut {
        sequence: "Delete"
        onActivated: {
            var ids = bridge.trackModel.getSelectedTrackIds();
            if (ids.length > 0) {
                bridge.deleteSelectedTracks(ids);
            }
        }
    }
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (bridge.trackModel.selectedCount > 0) {
                bridge.trackModel.clearSelection();
            } else if (searchTextInput.text.length > 0) {
                searchTextInput.text = "";
                bridge.search("");
            }
        }
    }

    // Keyboard shortcuts - View & Layout Navigation
    Shortcut { sequence: "Ctrl+1"; onActivated: showLeftPanel = !showLeftPanel }
    Shortcut { sequence: "Ctrl+2"; onActivated: showColumnBrowser = !showColumnBrowser }
    Shortcut {
        sequence: "Ctrl+3"
        onActivated: {
            if (!showRightPanel || rightPanelTab !== 0) {
                showRightPanel = true;
                rightPanelTab = 0;
            } else {
                showRightPanel = false;
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+4"
        onActivated: {
            if (!showRightPanel || rightPanelTab !== 1) {
                showRightPanel = true;
                rightPanelTab = 1;
            } else {
                showRightPanel = false;
            }
        }
    }
    Shortcut { sequence: "Ctrl+5"; onActivated: showEqualizer = !showEqualizer }
    Shortcut { sequence: "Alt+1"; onActivated: switchViewMode(1) }
    Shortcut { sequence: "Alt+2"; onActivated: switchViewMode(0) }
    Shortcut { sequence: "Alt+3"; onActivated: switchViewMode(2) }
    Shortcut { sequence: "Alt+4"; onActivated: switchViewMode(3) }
    Shortcut { sequence: "Ctrl+Shift+M"; onActivated: toggleMiniPlayer() }
    Shortcut { sequence: "F10"; onActivated: toggleMiniPlayer() }
    Shortcut { sequence: "F11"; onActivated: toggleFullscreen() }
    Shortcut { sequence: "Ctrl+="; onActivated: zoomIn() }
    Shortcut { sequence: "Ctrl++"; onActivated: zoomIn() }
    Shortcut { sequence: "Ctrl+-"; onActivated: zoomOut() }
    Shortcut { sequence: "Ctrl+0"; onActivated: zoomReset() }
    Shortcut { sequence: "Ctrl+Shift+E"; onActivated: showEqualizer = !showEqualizer }
    Shortcut { sequence: "F1"; onActivated: Qt.openUrlExternally("https://github.com/ShamalLakshan/Parakeet") }
    Shortcut { sequence: "Ctrl+/"; onActivated: shortcutsDialog.open() }
    Shortcut { sequence: "Ctrl+?"; onActivated: shortcutsDialog.open() }

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
        visible: !isMiniPlayer

        // Menu bar and status
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            color: Theme.surface

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
                        color: Theme.accent
                    }
                    Text {
                        text: "PARAKEET"
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.5
                        color: Theme.textPrimary
                    }
                }

                Rectangle { width: 1; height: 14; color: Theme.panelBorder; Layout.leftMargin: 6; Layout.rightMargin: 6 }

                // Desktop Menu Items (File, Edit, View, Controls, Tools, Help)
                RowLayout {
                    spacing: 2

                    // File Menu Button
                    Rectangle {
                        width: fileMenuText.implicitWidth + 14
                        height: 22
                        radius: 3
                        color: fileMenuMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                        Text {
                            id: fileMenuText
                            anchors.centerIn: parent
                            text: "File"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.textSecondary
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
                                text: "Open Audio File... (Ctrl+O)"
                                onTriggered: openAudioFileDialog.open()
                            }
                            MenuItem {
                                text: "Open Folder... (Ctrl+Shift+O)"
                                onTriggered: openMusicFolderDialog.open()
                            }
                            MenuItem {
                                text: "Open URL / Network Stream... (Ctrl+U)"
                                onTriggered: openUrlDialog.open()
                            }
                            MenuItem {
                                text: "Open CUE Sheet..."
                                onTriggered: openCueSheetDialog.open()
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Add Folder to Library..."
                                onTriggered: folderDialog.open()
                            }
                            MenuItem {
                                text: "Export Active View / Playlist... (Ctrl+E)"
                                onTriggered: exportViewDialog.open()
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Preferences & Settings... (Ctrl+,)"
                                onTriggered: preferencesDialog.open()
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Minimize to System Tray (Ctrl+W)"
                                onTriggered: root.hide()
                            }
                            MenuItem {
                                text: "Exit (Ctrl+Q)"
                                onTriggered: Qt.quit()
                            }
                        }
                    }

                    // Edit Menu Button
                    Rectangle {
                        width: editMenuText.implicitWidth + 14
                        height: 22
                        radius: 3
                        color: editMenuMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                        Text {
                            id: editMenuText
                            anchors.centerIn: parent
                            text: "Edit"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.textSecondary
                        }
                        MouseArea {
                            id: editMenuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: editMenu.open()
                        }
                        Menu {
                            id: editMenu
                            y: parent.height
                            MenuItem {
                                text: bridge.undoActionName.length > 0 ? ("Undo " + bridge.undoActionName + " (Ctrl+Z)") : "Undo (Ctrl+Z)"
                                enabled: bridge.canUndo
                                onTriggered: bridge.undo()
                            }
                            MenuItem {
                                text: bridge.redoActionName.length > 0 ? ("Redo " + bridge.redoActionName + " (Ctrl+Y)") : "Redo (Ctrl+Y)"
                                enabled: bridge.canRedo
                                onTriggered: bridge.redo()
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Select All (Ctrl+A)"
                                onTriggered: bridge.trackModel.selectAll()
                            }
                            MenuItem {
                                text: "Invert Selection (Ctrl+Shift+A)"
                                onTriggered: bridge.trackModel.invertSelection()
                            }
                            MenuItem {
                                text: "Clear Selection (Esc)"
                                enabled: bridge.trackModel.selectedCount > 0
                                onTriggered: bridge.trackModel.clearSelection()
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Find / Instant Search (Ctrl+F)"
                                onTriggered: {
                                    searchTextInput.forceActiveFocus();
                                    searchTextInput.selectAll();
                                }
                            }
                            MenuItem {
                                text: "Clear Search Filter (Shift+Esc)"
                                onTriggered: {
                                    searchTextInput.text = "";
                                    bridge.search("");
                                }
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Edit Track Tags... (Ctrl+T)"
                                enabled: bridge.trackModel.selectedCount > 0
                                onTriggered: {
                                    var sel = bridge.trackModel.getSelectedTracks();
                                    if (sel.length > 0) {
                                        tagEditorDialog.targetTracks = sel.length > 1 ? sel : [];
                                        tagEditorDialog.targetTrack = sel[0];
                                        tagEditorDialog.open();
                                    }
                                }
                            }
                            MenuItem {
                                text: "Delete Selected Tracks (Delete)"
                                enabled: bridge.trackModel.selectedCount > 0
                                onTriggered: {
                                    var ids = bridge.trackModel.getSelectedTrackIds();
                                    if (ids.length > 0) {
                                        bridge.deleteSelectedTracks(ids);
                                    }
                                }
                            }
                        }
                    }

                    // View Menu Button
                    Rectangle {
                        width: viewMenuText.implicitWidth + 14
                        height: 22
                        radius: 3
                        color: viewMenuMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                        Text {
                            id: viewMenuText
                            anchors.centerIn: parent
                            text: "View"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.textSecondary
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
                                text: (showLeftPanel ? "Hide" : "Show") + " Left Navigator (Ctrl+1)"
                                onTriggered: showLeftPanel = !showLeftPanel
                            }
                            MenuItem {
                                text: (showColumnBrowser ? "Hide" : "Show") + " 3-Column Browser (Ctrl+2)"
                                onTriggered: showColumnBrowser = !showColumnBrowser
                            }
                            MenuItem {
                                text: (showRightPanel && rightPanelTab === 0 ? "Hide" : "Show") + " Audio Specs Inspector (Ctrl+3)"
                                onTriggered: {
                                    if (!showRightPanel || rightPanelTab !== 0) {
                                        showRightPanel = true;
                                        rightPanelTab = 0;
                                    } else {
                                        showRightPanel = false;
                                    }
                                }
                            }
                            MenuItem {
                                text: (showRightPanel && rightPanelTab === 1 ? "Hide" : "Show") + " Up Next Play Queue (Ctrl+4)"
                                onTriggered: {
                                    if (!showRightPanel || rightPanelTab !== 1) {
                                        showRightPanel = true;
                                        rightPanelTab = 1;
                                    } else {
                                        showRightPanel = false;
                                    }
                                }
                            }
                            MenuItem {
                                text: (showEqualizer ? "Hide" : "Show") + " Parametric Equalizer (Ctrl+5)"
                                onTriggered: showEqualizer = !showEqualizer
                            }
                            MenuItem {
                                text: (showStatusBar ? "Hide" : "Show") + " Bottom Status Bar"
                                checkable: true
                                checked: showStatusBar
                                onTriggered: showStatusBar = !showStatusBar
                            }
                            MenuSeparator {}
                            Menu {
                                title: "View Modes"
                                MenuItem {
                                    text: "Track Details Table (Alt+1)"
                                    checkable: true
                                    checked: mainViewMode === 1
                                    onTriggered: switchViewMode(1)
                                }
                                MenuItem {
                                    text: "Album Grid (Alt+2)"
                                    checkable: true
                                    checked: mainViewMode === 0
                                    onTriggered: switchViewMode(0)
                                }
                                MenuItem {
                                    text: "Album Details & Tracks (Alt+3)"
                                    checkable: true
                                    checked: mainViewMode === 2
                                    onTriggered: switchViewMode(2)
                                }
                                MenuItem {
                                    text: "Listening History (Alt+4)"
                                    checkable: true
                                    checked: mainViewMode === 3
                                    onTriggered: switchViewMode(3)
                                }
                            }
                            MenuItem {
                                text: (isMiniPlayer ? "Restore Full Player" : "Mini-Player Mode") + " (Ctrl+Shift+M / F10)"
                                onTriggered: toggleMiniPlayer()
                            }
                            MenuItem {
                                text: (root.visibility === Window.FullScreen ? "Exit Fullscreen" : "Fullscreen") + " (F11)"
                                onTriggered: toggleFullscreen()
                            }
                            MenuSeparator {}
                            Menu {
                                title: "Zoom UI"
                                MenuItem {
                                    text: "Zoom In (Ctrl++)"
                                    onTriggered: zoomIn()
                                }
                                MenuItem {
                                    text: "Zoom Out (Ctrl+-)"
                                    onTriggered: zoomOut()
                                }
                                MenuItem {
                                    text: "Reset Zoom (100%) (Ctrl+0)"
                                    onTriggered: zoomReset()
                                }
                                MenuSeparator {}
                                MenuItem {
                                    text: "75%"
                                    checkable: true
                                    checked: Math.abs(Theme.uiScale - 0.75) < 0.04
                                    onTriggered: Theme.uiScale = 0.75
                                }
                                MenuItem {
                                    text: "90%"
                                    checkable: true
                                    checked: Math.abs(Theme.uiScale - 0.9) < 0.04
                                    onTriggered: Theme.uiScale = 0.9
                                }
                                MenuItem {
                                    text: "100% (Standard)"
                                    checkable: true
                                    checked: Math.abs(Theme.uiScale - 1.0) < 0.04
                                    onTriggered: Theme.uiScale = 1.0
                                }
                                MenuItem {
                                    text: "110%"
                                    checkable: true
                                    checked: Math.abs(Theme.uiScale - 1.1) < 0.04
                                    onTriggered: Theme.uiScale = 1.1
                                }
                                MenuItem {
                                    text: "125%"
                                    checkable: true
                                    checked: Math.abs(Theme.uiScale - 1.25) < 0.04
                                    onTriggered: Theme.uiScale = 1.25
                                }
                                MenuItem {
                                    text: "150%"
                                    checkable: true
                                    checked: Math.abs(Theme.uiScale - 1.5) < 0.04
                                    onTriggered: Theme.uiScale = 1.5
                                }
                            }
                            Menu {
                                id: themesQuickMenu
                                title: "Themes Quick Switch"
                                Instantiator {
                                    model: Theme.availableThemes
                                    onObjectAdded: (index, object) => themesQuickMenu.insertItem(index, object)
                                    onObjectRemoved: (index, object) => themesQuickMenu.removeItem(object)
                                    delegate: MenuItem {
                                        text: (modelData.name || modelData.id) + (Theme.themeId === modelData.id ? "  ✓" : "")
                                        onTriggered: Theme.themeId = modelData.id
                                    }
                                }
                                MenuSeparator {}
                                MenuItem {
                                    text: "Manage Themes..."
                                    onTriggered: {
                                        preferencesDialog.activeCategory = 1;
                                        preferencesDialog.open();
                                    }
                                }
                            }
                        }
                    }

                    // Playback Menu Button
                    Rectangle {
                        width: playbackMenuText.implicitWidth + 14
                        height: 22
                        radius: 3
                        color: playbackMenuMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                        Text {
                            id: playbackMenuText
                            anchors.centerIn: parent
                            text: "Playback"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.textSecondary
                        }
                        MouseArea {
                            id: playbackMenuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: playbackMenu.open()
                        }
                        Menu {
                            id: playbackMenu
                            y: parent.height
                            MenuItem {
                                text: bridge.isPlaying ? "Pause (Space)" : "Play (Space)"
                                onTriggered: bridge.togglePlayPause()
                            }
                            MenuItem {
                                text: "Stop (Ctrl+.)"
                                onTriggered: bridge.stop()
                            }
                            MenuItem {
                                text: "Stop After Current Track (Shift+Space)"
                                checkable: true
                                checked: bridge.stopAfterCurrentTrack
                                onTriggered: bridge.toggleStopAfterCurrentTrack()
                            }
                            MenuItem {
                                text: "Next Track (Ctrl+Right)"
                                onTriggered: bridge.nextTrack()
                            }
                            MenuItem {
                                text: "Previous Track (Ctrl+Left)"
                                onTriggered: bridge.previousTrack()
                            }
                            MenuSeparator {}
                            Menu {
                                title: "Seeking"
                                MenuItem {
                                    text: "Short Seek Backward 5s (Left)"
                                    onTriggered: bridge.seek(bridge.positionMs - 5000)
                                }
                                MenuItem {
                                    text: "Short Seek Forward 5s (Right)"
                                    onTriggered: bridge.seek(bridge.positionMs + 5000)
                                }
                                MenuItem {
                                    text: "Long Seek Backward 30s (Shift+Left)"
                                    onTriggered: bridge.seek(bridge.positionMs - 30000)
                                }
                                MenuItem {
                                    text: "Long Seek Forward 30s (Shift+Right)"
                                    onTriggered: bridge.seek(bridge.positionMs + 30000)
                                }
                                MenuSeparator {}
                                MenuItem {
                                    text: "Seek to Track Beginning (Home)"
                                    onTriggered: bridge.seek(0)
                                }
                                MenuItem {
                                    text: "Seek to Track End (End)"
                                    onTriggered: bridge.seek(bridge.durationMs)
                                }
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Volume Up 5% (Ctrl+Up)"
                                onTriggered: bridge.setVolume(bridge.volume + 0.05)
                            }
                            MenuItem {
                                text: "Volume Down 5% (Ctrl+Down)"
                                onTriggered: bridge.setVolume(bridge.volume - 0.05)
                            }
                            MenuItem {
                                text: "Mute Toggle (Ctrl+M)"
                                checkable: true
                                checked: bridge.isMuted
                                onTriggered: bridge.toggleMute()
                            }
                            MenuSeparator {}
                            Menu {
                                title: "Playback Speed"
                                MenuItem {
                                    text: "0.5x"
                                    checkable: true
                                    checked: Math.abs(bridge.playbackRate - 0.5) < 0.05
                                    onTriggered: bridge.setPlaybackRate(0.5)
                                }
                                MenuItem {
                                    text: "0.75x"
                                    checkable: true
                                    checked: Math.abs(bridge.playbackRate - 0.75) < 0.05
                                    onTriggered: bridge.setPlaybackRate(0.75)
                                }
                                MenuItem {
                                    text: "1.0x (Normal)"
                                    checkable: true
                                    checked: Math.abs(bridge.playbackRate - 1.0) < 0.05
                                    onTriggered: bridge.setPlaybackRate(1.0)
                                }
                                MenuItem {
                                    text: "1.25x"
                                    checkable: true
                                    checked: Math.abs(bridge.playbackRate - 1.25) < 0.05
                                    onTriggered: bridge.setPlaybackRate(1.25)
                                }
                                MenuItem {
                                    text: "1.5x"
                                    checkable: true
                                    checked: Math.abs(bridge.playbackRate - 1.5) < 0.05
                                    onTriggered: bridge.setPlaybackRate(1.5)
                                }
                                MenuItem {
                                    text: "2.0x"
                                    checkable: true
                                    checked: Math.abs(bridge.playbackRate - 2.0) < 0.05
                                    onTriggered: bridge.setPlaybackRate(2.0)
                                }
                            }
                            Menu {
                                title: "A-B Looping"
                                MenuItem {
                                    text: "Set Loop Point A (" + (bridge.loopPointA >= 0 ? formatTimestamp(bridge.loopPointA) : "--:--") + ")  ([)"
                                    onTriggered: bridge.setLoopPointA()
                                }
                                MenuItem {
                                    text: "Set Loop Point B (" + (bridge.loopPointB >= 0 ? formatTimestamp(bridge.loopPointB) : "--:--") + ")  (])"
                                    onTriggered: bridge.setLoopPointB()
                                }
                                MenuItem {
                                    text: "Clear Loop (\\)"
                                    enabled: bridge.isLoopActive || bridge.loopPointA >= 0 || bridge.loopPointB >= 0
                                    onTriggered: bridge.clearLoop()
                                }
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Cycle Shuffle Mode (Ctrl+S)"
                                onTriggered: bridge.cycleShuffleMode()
                            }
                            MenuItem {
                                text: "Cycle Repeat Mode (Ctrl+R)"
                                onTriggered: bridge.cycleRepeatMode()
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

                    // Library Menu Button
                    Rectangle {
                        width: libraryMenuText.implicitWidth + 14
                        height: 22
                        radius: 3
                        color: libraryMenuMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                        Text {
                            id: libraryMenuText
                            anchors.centerIn: parent
                            text: "Library"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.textSecondary
                        }
                        MouseArea {
                            id: libraryMenuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: libraryMenu.open()
                        }
                        Menu {
                            id: libraryMenu
                            y: parent.height
                            MenuItem {
                                text: "Rescan All Monitored Folders (F5)"
                                onTriggered: bridge.rescanAllMonitoredFolders()
                            }
                            MenuItem {
                                text: "Quick Incremental Scan (Ctrl+F5)"
                                onTriggered: bridge.incrementalQuickScan()
                            }
                            MenuItem {
                                text: "Manage Monitored Folders..."
                                onTriggered: {
                                    preferencesDialog.activeCategory = 3;
                                    preferencesDialog.open();
                                }
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Create New Playlist... (Ctrl+N)"
                                onTriggered: {
                                    newPlaylistDialog.isSmart = false;
                                    newPlaylistDialog.open();
                                }
                            }
                            MenuItem {
                                text: "Create Smart Playlist... (Ctrl+Shift+N)"
                                onTriggered: newPlaylistDialog.openSmart()
                            }
                            MenuItem {
                                text: "Import Playlist..."
                                onTriggered: importPlaylistDialog.open()
                            }
                            MenuItem {
                                text: "Export Active View / Playlist... (Ctrl+E)"
                                onTriggered: exportViewDialog.open()
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Deduplicate Library Tracks"
                                onTriggered: bridge.deduplicateTracks()
                            }
                            MenuItem {
                                text: "Check for Dead / Broken Files"
                                onTriggered: bridge.purgeMissingTracks()
                            }
                            MenuItem {
                                text: "Clear Cover Art Cache"
                                onTriggered: bridge.clearCoverArtCache()
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Clear Entire Library..."
                                onTriggered: bridge.clearLibrary()
                            }
                        }
                    }

                    // Tools Menu Button
                    Rectangle {
                        width: toolsMenuText.implicitWidth + 14
                        height: 22
                        radius: 3
                        color: toolsMenuMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                        Text {
                            id: toolsMenuText
                            anchors.centerIn: parent
                            text: "Tools"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.textSecondary
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
                                text: "Metadata Tag Editor... (Ctrl+T)"
                                onTriggered: {
                                    var sel = bridge.trackModel.getSelectedTracks();
                                    if (sel.length > 0) {
                                        tagEditorDialog.targetTracks = sel.length > 1 ? sel : [];
                                        tagEditorDialog.targetTrack = sel[0];
                                    } else {
                                        tagEditorDialog.targetTracks = [];
                                        tagEditorDialog.targetTrack = null;
                                    }
                                    tagEditorDialog.open();
                                }
                            }
                            MenuItem {
                                text: (showEqualizer ? "Hide" : "Show") + " Parametric Equalizer & DSP (Ctrl+Shift+E)"
                                onTriggered: showEqualizer = !showEqualizer
                            }
                            MenuItem {
                                text: "Playback Sleep Timer..."
                                onTriggered: sleepTimerDialog.open()
                            }
                            MenuSeparator {}
                            Menu {
                                id: audioDeviceMenu
                                title: "Audio Output Device"
                                Instantiator {
                                    model: bridge.availableAudioDevices
                                    onObjectAdded: (index, object) => audioDeviceMenu.insertItem(index, object)
                                    onObjectRemoved: (index, object) => audioDeviceMenu.removeItem(object)
                                    delegate: MenuItem {
                                        text: modelData + (bridge.currentAudioDevice === modelData ? "  ✓" : "")
                                        checkable: true
                                        checked: bridge.currentAudioDevice === modelData
                                        onTriggered: bridge.setCurrentAudioDevice(modelData)
                                    }
                                }
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Preferences & Settings... (Ctrl+,)"
                                onTriggered: preferencesDialog.open()
                            }
                            MenuItem {
                                text: "Manage Plugins & Extensions..."
                                onTriggered: {
                                    preferencesDialog.activeCategory = 5;
                                    preferencesDialog.open();
                                }
                            }
                        }
                    }

                    // Help Menu Button
                    Rectangle {
                        width: helpMenuText.implicitWidth + 14
                        height: 22
                        radius: 3
                        color: helpMenuMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                        Text {
                            id: helpMenuText
                            anchors.centerIn: parent
                            text: "Help"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.textSecondary
                        }
                        MouseArea {
                            id: helpMenuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: helpMenu.open()
                        }
                        Menu {
                            id: helpMenu
                            y: parent.height
                            MenuItem {
                                text: "Documentation & User Guide (F1)"
                                onTriggered: Qt.openUrlExternally("https://github.com/ShamalLakshan/Parakeet")
                            }
                            MenuItem {
                                text: "Keyboard Shortcuts Cheat Sheet (Ctrl+/)"
                                onTriggered: shortcutsDialog.open()
                            }
                            MenuItem {
                                text: "Audio Pipeline Diagnostics..."
                                onTriggered: diagnosticsDialog.open()
                            }
                            MenuItem {
                                text: "Open Application Log File"
                                onTriggered: Qt.openUrlExternally("file://" + bridge.getLogFilePath())
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Report an Issue / GitHub..."
                                onTriggered: Qt.openUrlExternally("https://github.com/ShamalLakshan/Parakeet/issues")
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "About Parakeet"
                                onTriggered: aboutDialog.open()
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        // 1px divider
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

        // Toolbar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            color: Theme.surface

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
                            { name: "ALL TRACKS", icon: "table", mode: 1 },
                            { name: "ALBUMS", icon: "grid", mode: 0 },
                            { name: "EXPANDED", icon: "album_tracks", mode: 2 },
                            { name: "NOW PLAYING", icon: "queue", mode: -1 }
                        ]

                        delegate: Rectangle {
                            property bool isTabActive: {
                                if (modelData.mode === -1) {
                                    return activeNavSection === 4 && showRightPanel && rightPanelTab === 1;
                                }
                                return mainViewMode === modelData.mode;
                            }

                            Layout.preferredWidth: tabRowLayout.implicitWidth + 16
                            Layout.preferredHeight: 30
                            Layout.alignment: Qt.AlignVCenter
                            radius: 3
                            color: isTabActive ? Theme.selection : (tabMouse.containsMouse ? Theme.surfaceElevated : "transparent")
                            border.color: isTabActive ? Theme.panelBorder : "transparent"
                            border.width: 1
                            clip: true

                            RowLayout {
                                id: tabRowLayout
                                anchors.centerIn: parent
                                spacing: 6

                                VectorIcon {
                                    name: modelData.icon
                                    width: 12
                                    height: 12
                                    color: isTabActive ? Theme.accent : Theme.textMuted
                                }

                                Text {
                                    text: modelData.name
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.letterSpacing: 0.8
                                    color: isTabActive ? Theme.textPrimary : Theme.textSecondary
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.mode === 1) {
                                        switchViewMode(1);
                                    } else if (modelData.mode === 0) {
                                        switchViewMode(0);
                                    } else if (modelData.mode === 2) {
                                        switchToExpandedView();
                                    } else if (modelData.mode === -1) {
                                        switchToNowPlaying();
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 20; Layout.alignment: Qt.AlignVCenter; color: Theme.panelBorder }

                // Quick Playback Actions
                RowLayout {
                    spacing: 4

                    Rectangle {
                        Layout.preferredWidth: playAllText.implicitWidth + 18
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignVCenter
                        radius: 3
                        color: playAllMouse.containsMouse ? Theme.selection : Theme.surfaceElevated
                        border.color: Theme.panelBorder
                        clip: true

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            VectorIcon { name: "play"; width: 10; height: 10; color: Theme.textPrimary }
                            Text { id: playAllText; text: "Play All"; font.pixelSize: 11; font.bold: true; color: Theme.textPrimary }
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
                        Layout.preferredWidth: shuffleAllText.implicitWidth + 18
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignVCenter
                        radius: 3
                        color: shuffleAllMouse.containsMouse ? Theme.selection : Theme.surfaceElevated
                        border.color: Theme.panelBorder
                        clip: true

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            VectorIcon { name: "shuffle"; width: 11; height: 11; color: Theme.textSecondary }
                            Text { id: shuffleAllText; text: "Shuffle"; font.pixelSize: 11; color: Theme.textSecondary }
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

                // Search input
                Rectangle {
                    Layout.preferredWidth: 250
                    Layout.preferredHeight: 28
                    Layout.minimumWidth: 140
                    Layout.alignment: Qt.AlignVCenter
                    radius: 3
                    color: Theme.background
                    border.color: searchTextInput.activeFocus ? Theme.accent : Theme.panelBorder
                    border.width: 1
                    clip: true

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        VectorIcon {
                            name: "search"
                            width: 11
                            height: 11
                            color: Theme.textMuted
                        }

                        TextInput {
                            id: searchTextInput
                            Layout.fillWidth: true
                            color: Theme.textPrimary
                            font.pixelSize: 11
                            clip: true
                            onTextChanged: bridge.search(text)

                            Text {
                                text: "Search title, artist, album..."
                                color: Theme.textMuted
                                font.pixelSize: 11
                                visible: !searchTextInput.text && !searchTextInput.activeFocus
                            }
                        }

                        VectorIcon {
                            visible: searchTextInput.text.length > 0
                            name: "clear"
                            width: 10
                            height: 10
                            color: Theme.textMuted
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
                    Layout.preferredWidth: scanBtnLayout.implicitWidth + 18
                    Layout.preferredHeight: 28
                    Layout.alignment: Qt.AlignVCenter
                    radius: 3
                    color: scanMouse.containsMouse ? Theme.selection : Theme.surfaceElevated
                    border.color: Theme.panelBorder
                    clip: true

                    RowLayout {
                        id: scanBtnLayout
                        anchors.centerIn: parent
                        spacing: 6

                        VectorIcon {
                            name: "folder"
                            width: 12
                            height: 12
                            color: Theme.accent
                        }

                        Text {
                            text: "Scan Directory..."
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.accentHover
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
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 3
                        color: showLeftPanel ? Theme.selection : (pnlLeftMouse.containsMouse ? Theme.surfaceElevated : Theme.surface)
                        border.color: Theme.panelBorder
                        VectorIcon { anchors.centerIn: parent; name: "panel_left"; width: 13; height: 13; color: showLeftPanel ? Theme.textPrimary : Theme.textMuted }
                        MouseArea {
                            id: pnlLeftMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showLeftPanel = !showLeftPanel
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 3
                        color: showRightPanel ? Theme.selection : (pnlRightMouse.containsMouse ? Theme.surfaceElevated : Theme.surface)
                        border.color: Theme.panelBorder
                        VectorIcon { anchors.centerIn: parent; name: "panel_right"; width: 13; height: 13; color: showRightPanel ? Theme.textPrimary : Theme.textMuted }
                        MouseArea {
                            id: pnlRightMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: showRightPanel = !showRightPanel
                        }
                    }

                    // Settings Button (Ctrl+,)
                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 3
                        color: settingsBtnMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                        border.color: Theme.panelBorder
                        VectorIcon { anchors.centerIn: parent; name: "settings"; width: 13; height: 13; color: Theme.textSecondary }
                        MouseArea {
                            id: settingsBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: preferencesDialog.open()
                        }
                        ToolTip.visible: settingsBtnMouse.containsMouse
                        ToolTip.text: "Preferences & Settings (Ctrl+,)"
                    }
                }
            }
        }

        // 1px divider
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

        // Main workspace
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Left panel
            Rectangle {
                Layout.preferredWidth: 210
                Layout.fillHeight: true
                color: Theme.surface
                visible: showLeftPanel

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            explorerContextMenu.popup();
                        }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Explorer Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        color: Theme.surfaceElevated
                        border.color: Theme.panelBorder
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
                                color: Theme.textMuted
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: bridge.totalTracks + " items"
                                font.pixelSize: 10
                                color: Theme.textMuted
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
                                color: Theme.textMuted
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
                                    color: activeNavSection === modelData.nav ? Theme.selection : (navItemMouse.containsMouse ? Theme.surfaceElevated : "transparent")

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        VectorIcon {
                                            name: modelData.icon
                                            width: 11
                                            height: 11
                                            color: activeNavSection === modelData.nav ? Theme.accent : Theme.textMuted
                                        }

                                        Text {
                                            text: modelData.title
                                            font.pixelSize: 11
                                            color: activeNavSection === modelData.nav ? Theme.textPrimary : Theme.textSecondary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "" + modelData.count
                                            font.pixelSize: 10
                                            color: activeNavSection === modelData.nav ? Theme.textPrimary : Theme.textMuted
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
                                            if (modelData.nav === 2 || modelData.nav === 3) {
                                                showColumnBrowser = true;
                                            } else {
                                                bridge.resetFilters();
                                            }
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
                                color: Theme.textMuted
                                Layout.leftMargin: 8
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 26
                                color: activeNavSection === 4 ? Theme.selection : (npMouse.containsMouse ? Theme.surfaceElevated : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 10
                                    spacing: 8
                                    VectorIcon { name: "queue"; width: 11; height: 11; color: activeNavSection === 4 ? Theme.accent : Theme.textMuted }
                                    Text { text: "Now Playing Queue"; font.pixelSize: 11; color: activeNavSection === 4 ? Theme.textPrimary : Theme.textSecondary; Layout.fillWidth: true }
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
                                color: Theme.textMuted
                                Layout.leftMargin: 8
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 26
                                color: scanMouse2.containsMouse ? Theme.surfaceElevated : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 10
                                    spacing: 8
                                    VectorIcon { name: "folder"; width: 11; height: 11; color: Theme.accent }
                                    Text { text: "Add Music Folder..."; font.pixelSize: 11; color: Theme.accentHover; Layout.fillWidth: true }
                                }
                                MouseArea {
                                    id: scanMouse2
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: folderDialog.open()
                                }
                            }

                            Item { Layout.fillHeight: true }
                        }
                    }
                }
            }

            // 1px vertical divider
            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Theme.panelBorder
                visible: showLeftPanel
            }

            // Center panel
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.surface

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Sub-toolbar
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        color: Theme.surfaceElevated
                        border.color: Theme.panelBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            // View Mode Toggle Icons
                            RowLayout {
                                spacing: 2
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 24
                                    width: 26
                                    height: 24
                                    radius: 2
                                    color: mainViewMode === 1 ? Theme.selection : (vm1Mouse.containsMouse ? Theme.surfaceElevated : "transparent")
                                    border.color: mainViewMode === 1 ? Theme.accent : "transparent"
                                    VectorIcon { anchors.centerIn: parent; name: "table"; width: 12; height: 12; color: mainViewMode === 1 ? Theme.accent : Theme.textMuted }
                                    MouseArea {
                                        id: vm1Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: switchViewMode(1)
                                    }
                                    ToolTip.visible: vm1Mouse.containsMouse
                                    ToolTip.text: "Track Details Table (Alt+1)"
                                }

                                Rectangle {
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 24
                                    width: 26
                                    height: 24
                                    radius: 2
                                    color: mainViewMode === 0 ? Theme.selection : (vm0Mouse.containsMouse ? Theme.surfaceElevated : "transparent")
                                    border.color: mainViewMode === 0 ? Theme.accent : "transparent"
                                    VectorIcon { anchors.centerIn: parent; name: "grid"; width: 12; height: 12; color: mainViewMode === 0 ? Theme.accent : Theme.textMuted }
                                    MouseArea {
                                        id: vm0Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: switchViewMode(0)
                                    }
                                    ToolTip.visible: vm0Mouse.containsMouse
                                    ToolTip.text: "Album Grid View (Alt+2)"
                                }

                                Rectangle {
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 24
                                    width: 26
                                    height: 24
                                    radius: 2
                                    color: mainViewMode === 2 ? Theme.selection : (vm2Mouse.containsMouse ? Theme.surfaceElevated : "transparent")
                                    border.color: mainViewMode === 2 ? Theme.accent : "transparent"
                                    VectorIcon { anchors.centerIn: parent; name: "album_tracks"; width: 12; height: 12; color: mainViewMode === 2 ? Theme.accent : Theme.textMuted }
                                    MouseArea {
                                        id: vm2Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: switchViewMode(2)
                                    }
                                    ToolTip.visible: vm2Mouse.containsMouse
                                    ToolTip.text: "Album Details & Tracks (Alt+3)"
                                }
                            }

                            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 16; width: 1; height: 16; color: Theme.panelBorder }

                            // Toggle Column Browser Button
                            Rectangle {
                                Layout.preferredWidth: colBtnLayout.implicitWidth + 12
                                Layout.preferredHeight: 22
                                Layout.alignment: Qt.AlignVCenter
                                width: Layout.preferredWidth
                                height: 22
                                radius: 2
                                color: showColumnBrowser ? Theme.selection : (cbMouse.containsMouse ? Theme.surfaceElevated : "transparent")
                                border.color: showColumnBrowser ? Theme.accent : Theme.panelBorder

                                RowLayout {
                                    id: colBtnLayout
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "Columns"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: showColumnBrowser ? Theme.accentHover : Theme.textMuted
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

                            // Alphabet jump ribbon
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
                                            Layout.preferredWidth: alphaText.implicitWidth + 8
                                            Layout.preferredHeight: 20
                                            width: Layout.preferredWidth
                                            height: 20
                                            radius: 2
                                            color: activeLetterFilter === modelData ? Theme.accent : (alphaMouse.containsMouse ? Theme.surfaceElevated : "transparent")

                                            Text {
                                                id: alphaText
                                                anchors.centerIn: parent
                                                text: modelData
                                                font.pixelSize: 10
                                                font.bold: activeLetterFilter === modelData
                                                color: activeLetterFilter === modelData ? Theme.textPrimary : Theme.textMuted
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
                                text: {
                                    if (mainViewMode === 0) {
                                        return bridge.albumModel.count + " albums";
                                    } else if (mainViewMode === 2) {
                                        return (bridge.selectedAlbumTrackCount > 0 ? (bridge.selectedAlbumTrackCount + " tracks • " + bridge.selectedAlbumDuration) : "Album Details");
                                    } else if (mainViewMode === 3) {
                                        return bridge.historyTrackModel.count + " played";
                                    }
                                    return bridge.trackModel.count + " tracks";
                                }
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }
                    }

                    // Column browser
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: showColumnBrowser ? 120 : 0
                        visible: showColumnBrowser
                        color: Theme.background
                        clip: true

                        RowLayout {
                            anchors.fill: parent
                            spacing: 1

                            // Column 1: Genre Filter
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: Theme.surface

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 0

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 20
                                        color: Theme.surfaceElevated
                                        Text { anchors.centerIn: parent; text: "GENRE"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted }
                                    }

                                    ListView {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        model: ["All (" + bridge.totalTracks + ")"].concat(bridge.genresList)

                                        delegate: Rectangle {
                                            width: parent.width
                                            height: 20
                                            color: (selectedGenreFilter === modelData || (modelData.indexOf("All") === 0 && selectedGenreFilter === "All")) ? Theme.selection : (gMouse.containsMouse ? Theme.surfaceElevated : "transparent")

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.leftMargin: 8
                                                text: modelData
                                                font.pixelSize: 10
                                                color: (selectedGenreFilter === modelData || (modelData.indexOf("All") === 0 && selectedGenreFilter === "All")) ? Theme.accent : Theme.textSecondary
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
                                color: Theme.surface

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 0

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 20
                                        color: Theme.surfaceElevated
                                        Text { anchors.centerIn: parent; text: "ARTIST"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted }
                                    }

                                    ListView {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        model: ["All (" + bridge.artistsList.length + ")"].concat(bridge.artistsList)

                                        delegate: Rectangle {
                                            width: parent.width
                                            height: 20
                                            color: (selectedArtistFilter === modelData || (modelData.indexOf("All") === 0 && selectedArtistFilter === "All")) ? Theme.selection : (aMouse.containsMouse ? Theme.surfaceElevated : "transparent")

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.left: parent.left
                                                anchors.leftMargin: 8
                                                text: modelData
                                                font.pixelSize: 10
                                                color: (selectedArtistFilter === modelData || (modelData.indexOf("All") === 0 && selectedArtistFilter === "All")) ? Theme.accent : Theme.textSecondary
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
                                color: Theme.surface

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 0

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 20
                                        color: Theme.surfaceElevated
                                        Text { anchors.centerIn: parent; text: "ALBUM"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted }
                                    }

                                    ListView {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        model: bridge.albumModel

                                        delegate: Rectangle {
                                            width: parent.width
                                            height: 20
                                            color: albColMouse.containsMouse ? Theme.surfaceElevated : "transparent"

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 8
                                                anchors.rightMargin: 8
                                                spacing: 4

                                                Text {
                                                    text: model.title
                                                    font.pixelSize: 10
                                                    color: Theme.textSecondary
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }

                                                Text {
                                                    text: model.trackCount
                                                    font.pixelSize: 9
                                                    color: Theme.textMuted
                                                }

                                                VectorIcon {
                                                    visible: albColMouse.containsMouse
                                                    name: "album_tracks"
                                                    width: 10
                                                    height: 10
                                                    color: Theme.accent
                                                }
                                            }

                                            MouseArea {
                                                id: albColMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    bridge.search(model.title);
                                                }
                                                onDoubleClicked: {
                                                    switchToExpandedView(model.title, model.artist);
                                                }
                                                ToolTip.visible: albColMouse.containsMouse
                                                ToolTip.text: "Click to filter table • Double-click to expand album"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 1px divider
                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder; visible: showColumnBrowser }

                    // Track table view
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
                                color: Theme.surfaceElevated
                                border.color: Theme.panelBorder
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Item { Layout.preferredWidth: 28; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "#"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
                                    Item { Layout.preferredWidth: 16; Layout.fillHeight: true; clip: true }
                                    Item { Layout.fillWidth: true; Layout.preferredWidth: 200; Layout.minimumWidth: 100; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "TITLE"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
                                    Item { Layout.preferredWidth: 130; Layout.minimumWidth: 70; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "ARTIST"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
                                    Item { Layout.preferredWidth: 130; Layout.minimumWidth: 70; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "ALBUM"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
                                    Item { Layout.preferredWidth: 90; Layout.minimumWidth: 50; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "GENRE"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
                                    Item { Layout.preferredWidth: 42; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "YEAR"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
                                    Item { Layout.preferredWidth: 72; Layout.minimumWidth: 46; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "FORMAT"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
                                    Item { Layout.preferredWidth: 62; Layout.minimumWidth: 40; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "BITRATE"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
                                    Item { Layout.preferredWidth: 42; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "TIME"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
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
                                        color: model.isSelected ? Theme.selection : ((bridge.currentFilePath === model.filePath) ? Theme.surfaceElevated : (tableRowMouse.containsMouse ? Theme.surfaceElevated : (index % 2 === 0 ? Theme.surface : Theme.background)))

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
                                                    color: (bridge.currentFilePath === model.filePath) ? Theme.accent : Theme.textMuted
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
                                                    color: Theme.accent
                                                }
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                                Layout.preferredWidth: 200
                                                Layout.minimumWidth: 100
                                                Layout.fillHeight: true
                                                clip: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    text: model.title
                                                    font.pixelSize: 11
                                                    font.bold: (bridge.currentFilePath === model.filePath)
                                                    color: (bridge.currentFilePath === model.filePath) ? Theme.textPrimary : Theme.textSecondary
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 130
                                                Layout.minimumWidth: 70
                                                Layout.fillHeight: true
                                                clip: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    text: model.artist
                                                    font.pixelSize: 11
                                                    color: (bridge.currentFilePath === model.filePath) ? Theme.textSecondary : Theme.textMuted
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 130
                                                Layout.minimumWidth: 70
                                                Layout.fillHeight: true
                                                clip: true
                                                Text {
                                                    id: albRowText
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    text: model.album
                                                    font.pixelSize: 11
                                                    font.underline: albTextMouse.containsMouse
                                                    color: albTextMouse.containsMouse ? Theme.accentHover : Theme.textMuted
                                                    elide: Text.ElideRight
                                                }
                                                MouseArea {
                                                    id: albTextMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        switchToExpandedView(model.album, model.artist);
                                                    }
                                                    ToolTip.visible: albTextMouse.containsMouse
                                                    ToolTip.text: "Expand " + model.album
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 90
                                                Layout.minimumWidth: 50
                                                Layout.fillHeight: true
                                                clip: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    text: model.genre
                                                    font.pixelSize: 10
                                                    color: Theme.textMuted
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 42
                                                Layout.fillHeight: true
                                                clip: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: model.year > 0 ? model.year : ""
                                                    font.pixelSize: 10
                                                    color: Theme.textMuted
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 72
                                                Layout.minimumWidth: 46
                                                Layout.fillHeight: true
                                                clip: true

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: model.codec + (model.bitDepth > 16 ? " " + model.bitDepth + "b" : "")
                                                    font.pixelSize: 10
                                                    font.weight: Font.Medium
                                                    color: Theme.textSecondary
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 62
                                                Layout.minimumWidth: 40
                                                Layout.fillHeight: true
                                                clip: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: model.bitrate > 0 ? model.bitrate + " kbps" : ""
                                                    font.pixelSize: 10
                                                    color: Theme.textMuted
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 42
                                                Layout.fillHeight: true
                                                clip: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: model.durationFormatted
                                                    font.pixelSize: 10
                                                    color: Theme.textMuted
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: tableRowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            onDoubleClicked: {
                                                if (bridge.doubleClickAction === "Play Next") {
                                                    bridge.playNext(model.id);
                                                } else if (bridge.doubleClickAction === "Queue Last") {
                                                    bridge.queueLast(model.id);
                                                } else {
                                                    bridge.playTrackAtIndex(index);
                                                }
                                            }
                                            onClicked: (mouse) => {
                                                if (mouse.button === Qt.RightButton) {
                                                    if (!model.isSelected) {
                                                        bridge.trackModel.clearSelection();
                                                        bridge.trackModel.setRowSelected(index, true);
                                                    }
                                                    trackContextMenu.targetTrack = { id: model.id, title: model.title, artist: model.artist, filePath: model.filePath, album: model.album, genre: model.genre, year: model.year, trackNumber: model.trackNumber };
                                                    trackContextMenu.targetFilePath = model.filePath;
                                                    trackContextMenu.targetTitle = model.title;
                                                    trackContextMenu.targetArtist = model.artist;
                                                    trackContextMenu.popup();
                                                } else {
                                                    if (mouse.modifiers & Qt.ControlModifier) {
                                                        bridge.trackModel.toggleSelection(index);
                                                    } else if (mouse.modifiers & Qt.ShiftModifier) {
                                                        bridge.trackModel.selectRange(trackTableListView.currentIndex >= 0 ? trackTableListView.currentIndex : 0, index);
                                                    } else {
                                                        bridge.trackModel.clearSelection();
                                                        bridge.trackModel.setRowSelected(index, true);
                                                        trackTableListView.currentIndex = index;
                                                    }
                                                    bridge.openAlbumDetails(model.album, model.artist);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Album grid view
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
                                color: albCardMouse.containsMouse ? Theme.surfaceElevated : Theme.surface
                                border.color: albCardMouse.containsMouse ? Theme.accent : Theme.panelBorder
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: width
                                        color: Theme.background
                                        border.color: Theme.panelBorder
                                        clip: true

                                        Image {
                                            anchors.fill: parent
                                            source: "image://albumart/" + (model.artHash ? model.artHash : "default")
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                        }



                                        // Hover Play Button
                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.right: parent.right
                                            anchors.margins: 6
                                            width: 28
                                            height: 28
                                            radius: 14
                                            color: Theme.accent
                                            visible: albCardMouse.containsMouse

                                            VectorIcon {
                                                anchors.centerIn: parent
                                                name: "play"
                                                width: 12
                                                height: 12
                                                color: Theme.textPrimary
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
                                        color: Theme.textPrimary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: model.artist + (model.year > 0 ? " • " + model.year : "")
                                        font.pixelSize: 10
                                        color: Theme.textMuted
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: model.trackCount + " tracks • " + model.primaryCodec
                                        font.pixelSize: 9
                                        color: Theme.accent
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    id: albCardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            trackContextMenu.targetTitle = model.title;
                                            trackContextMenu.targetArtist = model.artist;
                                            trackContextMenu.targetFilePath = "";
                                            trackContextMenu.popup();
                                        } else {
                                            switchToExpandedView(model.title, model.artist);
                                        }
                                    }
                                    onDoubleClicked: {
                                        bridge.playAlbumNow(model.title, model.artist);
                                    }
                                }
                            }
                        }
                    }

                    // Album details view
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: mainViewMode === 2

                        // Empty State if no album is selected
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surface
                            visible: bridge.selectedAlbumTitle.length === 0

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 14

                                VectorIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    name: "album_tracks"
                                    width: 44
                                    height: 44
                                    color: Theme.textMuted
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "No Album Selected"
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: Theme.textPrimary
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Choose an album from the Album Grid or Track List to view its artwork and complete tracklist."
                                    font.pixelSize: 11
                                    color: Theme.textMuted
                                }

                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 10

                                    Rectangle {
                                        width: emptyBrowseText.implicitWidth + 24
                                        height: 30
                                        radius: 3
                                        color: emptyBrowseMouse.containsMouse ? Theme.accentHover : Theme.accent

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            VectorIcon { name: "grid"; width: 12; height: 12; color: Theme.textPrimary }
                                            Text { id: emptyBrowseText; text: "Browse Album Grid"; font.pixelSize: 11; font.bold: true; color: Theme.textPrimary }
                                        }

                                        MouseArea {
                                            id: emptyBrowseMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: switchViewMode(0)
                                        }
                                    }

                                    Rectangle {
                                        visible: bridge.currentAlbum.length > 0
                                        width: emptyNowPlayingText.implicitWidth + 24
                                        height: 30
                                        radius: 3
                                        color: emptyNpMouse.containsMouse ? Theme.selection : Theme.surfaceElevated
                                        border.color: Theme.panelBorder

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            VectorIcon { name: "play"; width: 10; height: 10; color: Theme.accent }
                                            Text { id: emptyNowPlayingText; text: "View Playing Album"; font.pixelSize: 11; color: Theme.textPrimary }
                                        }

                                        MouseArea {
                                            id: emptyNpMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (bridge.currentAlbum.length > 0) {
                                                    switchToExpandedView(bridge.currentAlbum, bridge.currentArtist);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Loaded Album Details
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0
                            visible: bridge.selectedAlbumTitle.length > 0

                            // Album header
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 148
                                color: Theme.surface
                                border.color: Theme.panelBorder
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    // Breadcrumb navigation row
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Rectangle {
                                            width: backBreadcrumbText.implicitWidth + 16
                                            height: 22
                                            radius: 2
                                            color: backBreadcrumbMouse.containsMouse ? Theme.selection : Theme.surfaceElevated
                                            border.color: Theme.panelBorder

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 4
                                                VectorIcon { name: "previous"; width: 9; height: 9; color: Theme.accent }
                                                Text {
                                                    id: backBreadcrumbText
                                                    text: previousViewMode === 1 ? "Track List" : "Albums"
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: Theme.textSecondary
                                                }
                                            }

                                            MouseArea {
                                                id: backBreadcrumbMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: switchViewMode(previousViewMode)
                                            }
                                        }

                                        Text {
                                            text: "›"
                                            font.pixelSize: 11
                                            color: Theme.textMuted
                                        }

                                        Text {
                                            text: bridge.selectedAlbumTitle
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: Theme.accent
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    // Main album info row
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 14

                                        Rectangle {
                                            width: 96
                                            height: 96
                                            color: Theme.background
                                            border.color: Theme.panelBorder
                                            clip: true

                                            Image {
                                                anchors.fill: parent
                                                source: "image://albumart/" + (bridge.selectedAlbumArtHash ? bridge.selectedAlbumArtHash : "default")
                                                fillMode: Image.PreserveAspectCrop
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 3

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                Text {
                                                    text: bridge.selectedAlbumTitle
                                                    font.pixelSize: 16
                                                    font.bold: true
                                                    color: Theme.textPrimary
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }


                                            }

                                            Text {
                                                text: bridge.selectedAlbumArtist + (bridge.selectedAlbumYear ? " (" + bridge.selectedAlbumYear + ")" : "")
                                                font.pixelSize: 12
                                                color: Theme.accent
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: (bridge.selectedAlbumGenre ? bridge.selectedAlbumGenre + " • " : "") +
                                                      bridge.selectedAlbumTrackCount + " Tracks • " +
                                                      bridge.selectedAlbumDuration
                                                font.pixelSize: 10
                                                color: Theme.textMuted
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Item { height: 2; width: 1 }

                                            // Action Buttons Row
                                            RowLayout {
                                                spacing: 8

                                                Rectangle {
                                                    width: albPlayBtnText.implicitWidth + 20
                                                    height: 24
                                                    radius: 2
                                                    color: albPlayMouse.containsMouse ? Theme.accentHover : Theme.accent

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 6
                                                        VectorIcon { name: "play"; width: 10; height: 10; color: Theme.textPrimary }
                                                        Text { id: albPlayBtnText; text: "Play Album"; font.pixelSize: 10; font.bold: true; color: Theme.textPrimary }
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
                                                    width: albQueueBtnText.implicitWidth + 18
                                                    height: 24
                                                    radius: 2
                                                    color: albQueueMouse.containsMouse ? Theme.selection : Theme.surfaceElevated
                                                    border.color: Theme.panelBorder

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 5
                                                        VectorIcon { name: "queue"; width: 10; height: 10; color: Theme.textSecondary }
                                                        Text { id: albQueueBtnText; text: "Queue Album"; font.pixelSize: 10; color: Theme.textSecondary }
                                                    }

                                                    MouseArea {
                                                        id: albQueueMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: bridge.queueAlbumLast(bridge.selectedAlbumTitle, bridge.selectedAlbumArtist)
                                                    }
                                                }

                                                Rectangle {
                                                    width: viewInTableText.implicitWidth + 18
                                                    height: 24
                                                    radius: 2
                                                    color: viewInTableMouse.containsMouse ? Theme.selection : Theme.surfaceElevated
                                                    border.color: Theme.panelBorder

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 5
                                                        VectorIcon { name: "table"; width: 10; height: 10; color: Theme.textSecondary }
                                                        Text { id: viewInTableText; text: "View in Track List"; font.pixelSize: 10; color: Theme.textSecondary }
                                                    }

                                                    MouseArea {
                                                        id: viewInTableMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: {
                                                            bridge.search(bridge.selectedAlbumTitle);
                                                            previousViewMode = 2;
                                                            switchViewMode(1);
                                                        }
                                                    }
                                                    ToolTip.visible: viewInTableMouse.containsMouse
                                                    ToolTip.text: "Filter and view these tracks in the main list table"
                                                }

                                                Rectangle {
                                                    width: backToGridText.implicitWidth + 16
                                                    height: 24
                                                    radius: 2
                                                    color: backGridMouse.containsMouse ? Theme.selection : Theme.surfaceElevated
                                                    border.color: Theme.panelBorder

                                                    RowLayout {
                                                        anchors.centerIn: parent
                                                        spacing: 5
                                                        VectorIcon { name: "grid"; width: 10; height: 10; color: Theme.textSecondary }
                                                        Text { id: backToGridText; text: "All Albums"; font.pixelSize: 10; color: Theme.textSecondary }
                                                    }

                                                    MouseArea {
                                                        id: backGridMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: switchViewMode(0)
                                                    }
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
                                        color: (bridge.currentFilePath === model.filePath) ? Theme.selection : (dtRowMouse.containsMouse ? Theme.surfaceElevated : (index % 2 === 0 ? Theme.surface : Theme.background))

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 10

                                            Text {
                                                text: model.trackNumber > 0 ? model.trackNumber : (index + 1)
                                                font.pixelSize: 10
                                                color: (bridge.currentFilePath === model.filePath) ? Theme.accent : Theme.textMuted
                                                Layout.preferredWidth: 28
                                            }

                                            VectorIcon {
                                                visible: bridge.currentFilePath === model.filePath
                                                name: bridge.isPlaying ? "volume" : "play"
                                                width: 10
                                                height: 10
                                                color: Theme.accent
                                                Layout.preferredWidth: 14
                                            }

                                            Text {
                                                text: model.title
                                                font.pixelSize: 11
                                                font.bold: (bridge.currentFilePath === model.filePath)
                                                color: (bridge.currentFilePath === model.filePath) ? Theme.textPrimary : Theme.textSecondary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: model.artist
                                                font.pixelSize: 10
                                                color: Theme.textMuted
                                                Layout.preferredWidth: 140
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: model.codec + " " + model.sampleRate / 1000 + "kHz"
                                                font.pixelSize: 9
                                                color: Theme.accent
                                                Layout.preferredWidth: 90
                                            }

                                            Text {
                                                text: model.durationFormatted
                                                font.pixelSize: 10
                                                color: Theme.textMuted
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

                    // Listening History View
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: mainViewMode === 3

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            // History Header
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                color: Theme.surface
                                border.color: Theme.panelBorder
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 12

                                    VectorIcon {
                                        name: "queue"
                                        width: 16
                                        height: 16
                                        color: Theme.accent
                                    }

                                    ColumnLayout {
                                        spacing: 2
                                        Text {
                                            text: "Listening History"
                                            font.pixelSize: Theme.fontSizeLarge
                                            font.bold: true
                                            color: Theme.textPrimary
                                        }
                                        Text {
                                            text: bridge.historyTrackModel.count + " tracks played in recent sessions"
                                            font.pixelSize: 10
                                            color: Theme.textMuted
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Clear History Button
                                    Rectangle {
                                        width: clearHistoryText.implicitWidth + 24
                                        height: 28
                                        radius: Theme.cornerRadiusSmall
                                        color: clearHistoryMouse.containsMouse ? Theme.selection : Theme.surfaceElevated
                                        border.color: Theme.panelBorder

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            VectorIcon {
                                                name: "clear"
                                                width: 10
                                                height: 10
                                                color: Theme.textSecondary
                                            }
                                            Text {
                                                id: clearHistoryText
                                                text: "Clear History"
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: Theme.textSecondary
                                            }
                                        }

                                        MouseArea {
                                            id: clearHistoryMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                bridge.clearPlaybackHistory();
                                            }
                                        }
                                    }
                                }
                            }

                            // Table Header Row
                            Rectangle {
                                Layout.fillWidth: true
                                height: 26
                                color: Theme.surfaceElevated
                                border.color: Theme.panelBorder
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Item { Layout.preferredWidth: 28; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "#"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
                                    Item { Layout.fillWidth: true; Layout.preferredWidth: 200; Layout.minimumWidth: 100; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "TITLE"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
                                    Item { Layout.preferredWidth: 140; Layout.minimumWidth: 80; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "ARTIST"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
                                    Item { Layout.preferredWidth: 140; Layout.minimumWidth: 80; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "ALBUM"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
                                    Item { Layout.preferredWidth: 70; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "FORMAT"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
                                    Item { Layout.preferredWidth: 45; Layout.fillHeight: true; clip: true; Text { anchors.verticalCenter: parent.verticalCenter; text: "TIME"; font.pixelSize: 9; font.bold: true; color: Theme.textMuted } }
                                }
                            }

                            // History List
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                                ListView {
                                    id: historyListView
                                    anchors.fill: parent
                                    model: bridge.historyTrackModel
                                    clip: true

                                    delegate: Rectangle {
                                        width: historyListView.width
                                        height: 26
                                        color: histRowMouse.containsMouse ? Theme.surfaceElevated : (index % 2 === 0 ? Theme.surface : Theme.background)

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
                                                    text: index + 1
                                                    font.pixelSize: 10
                                                    color: Theme.textMuted
                                                }
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                                Layout.preferredWidth: 200
                                                Layout.minimumWidth: 100
                                                Layout.fillHeight: true
                                                clip: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    text: model.title
                                                    font.pixelSize: 11
                                                    color: Theme.textPrimary
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 140
                                                Layout.minimumWidth: 80
                                                Layout.fillHeight: true
                                                clip: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    text: model.artist
                                                    font.pixelSize: 11
                                                    color: Theme.textSecondary
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 140
                                                Layout.minimumWidth: 80
                                                Layout.fillHeight: true
                                                clip: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.right: parent.right
                                                    text: model.album
                                                    font.pixelSize: 11
                                                    color: Theme.textMuted
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 70
                                                Layout.fillHeight: true
                                                clip: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: model.codec
                                                    font.pixelSize: 10
                                                    color: Theme.accent
                                                }
                                            }

                                            Item {
                                                Layout.preferredWidth: 45
                                                Layout.fillHeight: true
                                                clip: true
                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: model.durationFormatted
                                                    font.pixelSize: 10
                                                    color: Theme.textMuted
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: histRowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onDoubleClicked: {
                                                bridge.openAudioFile(model.filePath);
                                            }
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
                color: Theme.panelBorder
                visible: showRightPanel
            }

            // Right panel
            Rectangle {
                Layout.preferredWidth: 270
                Layout.fillHeight: true
                color: Theme.surface
                visible: showRightPanel

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Tabs
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        color: Theme.surfaceElevated
                        border.color: Theme.panelBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: rightPanelTab === 0 ? Theme.selection : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "PROPERTIES"
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.letterSpacing: 1.0
                                    color: rightPanelTab === 0 ? Theme.textPrimary : Theme.textMuted
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rightPanelTab = 0
                                }
                            }

                            Rectangle { width: 1; height: 16; color: Theme.panelBorder }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: rightPanelTab === 1 ? Theme.selection : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "PLAY QUEUE"
                                    font.pixelSize: 10
                                    font.bold: true
                                    font.letterSpacing: 1.0
                                    color: rightPanelTab === 1 ? Theme.textPrimary : Theme.textMuted
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rightPanelTab = 1
                                }
                            }
                        }
                    }

                    // Track properties
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: rightPanelTab === 0
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded

                        ColumnLayout {
                            width: 270
                            spacing: 10

                            // Album art
                            Item { height: 4; width: 1 }
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 236
                                Layout.preferredHeight: 236
                                color: Theme.background
                                border.color: Theme.panelBorder
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
                                    color: Theme.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: bridge.currentArtist
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: Theme.accent
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: bridge.currentAlbum + (bridge.currentYear.length > 0 ? " (" + bridge.currentYear + ")" : "")
                                    font.pixelSize: 11
                                    color: Theme.textMuted
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
                                color: Theme.surfaceElevated
                                border.color: Theme.panelBorder
                                border.width: 1
                                radius: 3

                                GridLayout {
                                    id: specGrid
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    columns: 2
                                    rowSpacing: 5
                                    columnSpacing: 10

                                    Text { text: "Container:"; font.pixelSize: 10; font.bold: true; color: Theme.textMuted }
                                    Text { text: bridge.currentCodec.length > 0 ? bridge.currentCodec : "—"; font.pixelSize: 10; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }

                                    Text { text: "Bit Depth:"; font.pixelSize: 10; font.bold: true; color: Theme.textMuted }
                                    Text { text: bridge.currentBitDepth > 0 ? bridge.currentBitDepth + "-bit" : "—"; font.pixelSize: 10; color: Theme.accent; elide: Text.ElideRight; Layout.fillWidth: true }

                                    Text { text: "Sample Rate:"; font.pixelSize: 10; font.bold: true; color: Theme.textMuted }
                                    Text { text: bridge.currentSampleRate > 0 ? bridge.currentSampleRate + " Hz" : "—"; font.pixelSize: 10; color: Theme.accent; elide: Text.ElideRight; Layout.fillWidth: true }

                                    Text { text: "Bitrate:"; font.pixelSize: 10; font.bold: true; color: Theme.textMuted }
                                    Text { text: bridge.currentBitrate > 0 ? bridge.currentBitrate + " kbps" : "—"; font.pixelSize: 10; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }

                                    Text { text: "Channels:"; font.pixelSize: 10; font.bold: true; color: Theme.textMuted }
                                    Text { text: bridge.currentChannels === 2 ? "Stereo (2.0)" : (bridge.currentChannels === 1 ? "Mono" : (bridge.currentChannels > 2 ? bridge.currentChannels + " Ch" : "—")); font.pixelSize: 10; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }

                                    Text { text: "File Size:"; font.pixelSize: 10; font.bold: true; color: Theme.textMuted }
                                    Text { text: bridge.currentFileSizeStr.length > 0 ? bridge.currentFileSizeStr : "—"; font.pixelSize: 10; color: Theme.textPrimary; elide: Text.ElideRight; Layout.fillWidth: true }


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
                                    color: Theme.textMuted
                                }

                                Text {
                                    text: bridge.currentFilePath.length > 0 ? bridge.currentFilePath : "No file loaded"
                                    font.pixelSize: 9
                                    color: Theme.textMuted
                                    wrapMode: Text.WrapAnywhere
                                    Layout.fillWidth: true
                                }
                            }

                            Item { height: 10; width: 1 }
                        }
                    }

                    // Play queue tab
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: rightPanelTab === 1

                        QueueView {
                            anchors.fill: parent
                        }
                    }
                }
            }
        }

        // 1px divider
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

        // Transport controls
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 74
            color: Theme.surface

            Item {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                // Center: Transport Controls & Scrubber Timeline (Strictly centered on parent window)
                ColumnLayout {
                    id: centerTransportControls
                    z: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(560, Math.max(340, parent.width * 0.42))
                    spacing: 2

                    // Control Buttons Container (Play/Pause strictly centered at 50% width)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36

                        // Play / Pause Primary Action Button (Strictly centered on column and window)
                        Rectangle {
                            id: playPauseBtn
                            anchors.centerIn: parent
                            width: 36
                            height: 36
                            radius: 18
                            color: playPauseMouse.containsMouse ? Theme.accentHover : Theme.accent

                            VectorIcon {
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: bridge.isPlaying ? 0 : 1
                                name: bridge.isPlaying ? "pause" : "play"
                                width: 16
                                height: 16
                                color: Theme.textPrimary
                            }

                            MouseArea {
                                id: playPauseMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bridge.togglePlayPause()
                            }
                        }

                        // Left buttons: Shuffle, Stop, Previous (Adjacent to Play)
                        RowLayout {
                            anchors.right: playPauseBtn.left
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            // Shuffle Button (Cycle: Off -> Tracks -> Albums)
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 2
                                color: bridge.shuffleMode !== 0 ? Theme.selection : (shufMouse.containsMouse ? Theme.surfaceElevated : "transparent")
                                border.color: bridge.shuffleMode !== 0 ? Theme.accent : "transparent"
                                border.width: 1

                                VectorIcon {
                                    anchors.centerIn: parent
                                    name: "shuffle"
                                    width: 13
                                    height: 13
                                    color: bridge.shuffleMode === 1 ? Theme.accent : (bridge.shuffleMode === 2 ? Theme.accentHover : Theme.textMuted)
                                }
                                MouseArea {
                                    id: shufMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: bridge.cycleShuffleMode()
                                }
                                ToolTip.visible: shufMouse.containsMouse
                                ToolTip.text: bridge.shuffleMode === 0 ? "Shuffle: Off" : (bridge.shuffleMode === 1 ? "Shuffle: Tracks" : "Shuffle: Albums")
                            }

                            // Stop Button
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 2
                                color: stopMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                                VectorIcon { anchors.centerIn: parent; name: "stop"; width: 12; height: 12; color: Theme.textSecondary }
                                MouseArea {
                                    id: stopMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: bridge.stop()
                                }
                                ToolTip.visible: stopMouse.containsMouse
                                ToolTip.text: "Stop (X)"
                            }

                            // Previous Button
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 2
                                color: prevMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                                VectorIcon { anchors.centerIn: parent; name: "previous"; width: 14; height: 14; color: Theme.textPrimary }
                                MouseArea {
                                    id: prevMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: bridge.previousTrack()
                                }
                                ToolTip.visible: prevMouse.containsMouse
                                ToolTip.text: "Previous (Z)"
                            }
                        }

                        // Right buttons: Next (Adjacent to Play), Repeat
                        RowLayout {
                            anchors.left: playPauseBtn.right
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            // Next Button
                            Rectangle {
                                width: 28
                                height: 28
                                radius: 2
                                color: nextMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                                VectorIcon { anchors.centerIn: parent; name: "next"; width: 14; height: 14; color: Theme.textPrimary }
                                MouseArea {
                                    id: nextMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: bridge.nextTrack()
                                }
                                ToolTip.visible: nextMouse.containsMouse
                                ToolTip.text: "Next (B)"
                            }

                            // Repeat Button (Cycle: Off -> All -> One)
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 2
                                color: bridge.repeatMode !== 0 ? Theme.selection : (repMouse.containsMouse ? Theme.surfaceElevated : "transparent")
                                border.color: bridge.repeatMode !== 0 ? Theme.accent : "transparent"
                                border.width: 1

                                VectorIcon {
                                    anchors.centerIn: parent
                                    name: bridge.repeatMode === 2 ? "repeat_one" : "repeat"
                                    width: 13
                                    height: 13
                                    color: bridge.repeatMode !== 0 ? Theme.accent : Theme.textMuted
                                }
                                MouseArea {
                                    id: repMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: bridge.cycleRepeatMode()
                                }
                                ToolTip.visible: repMouse.containsMouse
                                ToolTip.text: bridge.repeatMode === 0 ? "Repeat: Off" : (bridge.repeatMode === 1 ? "Repeat: All" : "Repeat: One")
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
                            color: Theme.textMuted
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
                                color: Theme.surfaceElevated

                                Rectangle {
                                    width: timelineSlider.visualPosition * parent.width
                                    height: parent.height
                                    color: Theme.accent
                                    radius: 2
                                }
                            }

                            handle: Rectangle {
                                x: timelineSlider.leftPadding + timelineSlider.visualPosition * (timelineSlider.availableWidth - width)
                                y: timelineSlider.topPadding + timelineSlider.availableHeight / 2 - height / 2
                                implicitWidth: 10
                                implicitHeight: 10
                                radius: 5
                                color: timelineSlider.pressed ? Theme.textPrimary : Theme.accentHover
                            }
                        }

                        Text {
                            text: bridge.durationStr
                            font.pixelSize: 10
                            color: Theme.textMuted
                            Layout.preferredWidth: 36
                        }
                    }
                }

                // Left: Track preview
                RowLayout {
                    id: leftTrackPreview
                    anchors.left: parent.left
                    anchors.right: centerTransportControls.left
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    clip: true

                    Rectangle {
                        width: 48
                        height: 48
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        color: Theme.background
                        border.color: Theme.panelBorder
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
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: bridge.currentArtist + (bridge.currentAlbum.length > 0 ? " • " + bridge.currentAlbum : "")
                            font.pixelSize: 10
                            color: Theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: bridge.currentAudioSpecs
                            visible: text.length > 0
                            font.pixelSize: 9
                            color: Theme.textMuted
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                // Right: Volume & Tool Toggles
                RowLayout {
                    id: rightControls
                    anchors.right: parent.right
                    anchors.left: centerTransportControls.right
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    clip: true

                    Item { Layout.fillWidth: true }

                    VectorIcon {
                        name: bridge.isMuted ? "volume_mute" : "volume"
                        width: 14
                        height: 14
                        color: Theme.textSecondary
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
                            color: Theme.surfaceElevated

                            Rectangle {
                                width: volumeSlider.visualPosition * parent.width
                                height: parent.height
                                color: Theme.accent
                                radius: 2
                            }
                        }

                        handle: Rectangle {
                            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                            y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                            implicitWidth: 8
                            implicitHeight: 8
                            radius: 4
                            color: Theme.textPrimary
                        }
                    }

                    Text {
                        text: Math.round(bridge.volume * 100) + "%"
                        font.pixelSize: 9
                        color: Theme.textMuted
                        Layout.preferredWidth: 26
                    }

                    Rectangle { width: 1; height: 16; color: Theme.panelBorder }

                    // Fullscreen Toggle
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 2
                        color: fsMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                        VectorIcon { anchors.centerIn: parent; name: "fullscreen"; width: 12; height: 12; color: Theme.textSecondary }
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

        // Status bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            color: Theme.surface
            border.color: Theme.panelBorder
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
                    color: Theme.textMuted
                    elide: Text.ElideRight
                    Layout.maximumWidth: parent.width * 0.6
                }

                Item { Layout.fillWidth: true }

                // Indexing / scanning status
                RowLayout {
                    spacing: 6
                    visible: bridge.isScanning || bridge.scanStatusText.length > 0

                    Rectangle {
                        width: 5
                        height: 5
                        radius: 2.5
                        color: bridge.isScanning ? Theme.accent : Theme.textMuted
                    }

                    Text {
                        text: bridge.scanStatusText
                        font.pixelSize: 9
                        color: bridge.isScanning ? Theme.accentHover : Theme.textMuted
                    }
                }

                Rectangle {
                    width: 1
                    height: 12
                    color: Theme.panelBorder
                    visible: bridge.isScanning || bridge.scanStatusText.length > 0
                }

                Text {
                    text: "Parakeet v0.1.0"
                    font.pixelSize: 9
                    color: Theme.textMuted
                }
            }
        }
    }

    // Mini-player mode layout
    Rectangle {
        id: miniPlayerContainer
        anchors.fill: parent
        visible: isMiniPlayer
        color: Theme.background
        clip: true

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 12

            // Mini Album Art
            Rectangle {
                Layout.preferredWidth: 84
                Layout.preferredHeight: 84
                Layout.alignment: Qt.AlignVCenter
                color: Theme.surface
                border.color: Theme.panelBorder
                radius: Theme.cornerRadiusSmall
                clip: true

                Image {
                    anchors.fill: parent
                    source: bridge.currentArtUrl
                    fillMode: Image.PreserveAspectCrop
                }
            }

            // Info and Controls
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                // Top: Track Info & Restore Window Button
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: bridge.currentTrackTitle
                            font.pixelSize: Theme.fontSizeBase
                            font.bold: true
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: bridge.currentArtist + (bridge.currentAlbum.length > 0 ? " — " + bridge.currentAlbum : "")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.textSecondary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: bridge.currentCodec
                        visible: text.length > 0
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: Theme.textMuted
                    }

                    // Restore Normal Window Button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: Theme.cornerRadiusSmall
                        color: restoreMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                        border.color: restoreMouse.containsMouse ? Theme.panelBorder : "transparent"

                        VectorIcon {
                            anchors.centerIn: parent
                            name: "external"
                            width: 11
                            height: 11
                            color: restoreMouse.containsMouse ? Theme.accent : Theme.textMuted
                        }

                        MouseArea {
                            id: restoreMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: toggleMiniPlayer()
                        }
                        ToolTip.visible: restoreMouse.containsMouse
                        ToolTip.text: "Restore Full Player (Ctrl+Shift+M)"
                        ToolTip.delay: 400
                    }
                }

                // Seekbar Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: bridge.positionStr
                        font.pixelSize: 9
                        color: Theme.textMuted
                    }

                    Slider {
                        id: miniSeekSlider
                        Layout.fillWidth: true
                        from: 0
                        to: Math.max(1, bridge.durationMs)
                        value: bridge.positionMs
                        onMoved: bridge.seek(value)
                    }

                    Text {
                        text: bridge.durationStr
                        font.pixelSize: 9
                        color: Theme.textMuted
                    }
                }

                // Transport Deck Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Previous Track Button
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 13
                        color: miniPrevMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                        VectorIcon { anchors.centerIn: parent; name: "previous"; width: 11; height: 11; color: Theme.textPrimary }
                        MouseArea {
                            id: miniPrevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bridge.previousTrack()
                        }
                    }

                    // Play / Pause Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        color: miniPlayMouse.containsMouse ? Theme.accentHover : Theme.accent
                        VectorIcon {
                            anchors.centerIn: parent
                            name: bridge.isPlaying ? "pause" : "play"
                            width: 12
                            height: 12
                            color: Theme.textPrimary
                        }
                        MouseArea {
                            id: miniPlayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bridge.togglePlayPause()
                        }
                    }

                    // Next Track Button
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 13
                        color: miniNextMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                        VectorIcon { anchors.centerIn: parent; name: "next"; width: 11; height: 11; color: Theme.textPrimary }
                        MouseArea {
                            id: miniNextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bridge.nextTrack()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Volume Icon & Slider
                    VectorIcon {
                        name: bridge.isMuted ? "volume_mute" : "volume"
                        width: 12
                        height: 12
                        color: Theme.textSecondary
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bridge.toggleMute()
                        }
                    }

                    Slider {
                        id: miniVolSlider
                        Layout.preferredWidth: 70
                        from: 0.0
                        to: 1.0
                        value: bridge.volume
                        onMoved: bridge.setVolume(value)
                    }
                }
            }
        }
    }

    // Equalizer Overlay
    EqualizerOverlay {
        id: equalizerOverlay
        anchors.centerIn: parent
        visible: showEqualizer && !isMiniPlayer
        z: 100
        onClosed: showEqualizer = false
    }
}

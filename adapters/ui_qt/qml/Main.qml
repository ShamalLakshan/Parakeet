import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.platform as Platform
import "components"
import "dialogs"
import "views"
import "menubar"
import "toolbar"
import "navigation"
import "inspector"
import "player"
import "statusbar"

ApplicationWindow {
    id: root
    width: 1400
    height: 840
    minimumWidth: 1024
    minimumHeight: 640
    visible: true
    title: "Parakeet Music Player"
    color: Theme.background
    flags: Qt.Window | (stayOnTop ? Qt.WindowStaysOnTopHint : 0)

    // Panel visibility and navigation state
    property bool stayOnTop: false
    property bool showLeftPanel: true
    property bool showRightPanel: true
    property bool showColumnBrowser: false
    property bool showStatusBar: true
    property bool showEqualizer: false
    property bool isMiniPlayer: false
    property real normalWidth: 1400
    property real normalHeight: 840
    property int mainViewMode: 1 // 0: Album Grid, 1: Track Details Table, 2: Album & Tracks View, 3: Listening History, 4: Now Playing View
    property int previousViewMode: 0
    property int activeNavSection: 0 // 0: All Tracks, 1: Albums, 2: Artists, 3: Genres, 4: Now Playing
    property string activeLetterFilter: "All"
    property string selectedGenreFilter: "All"
    property string selectedArtistFilter: "All"
    property int rightPanelTab: 0 // 0: Properties, 1: Queue
    property string activePlaylistName: ""

    // Focus isolation state
    readonly property bool isAnyDialogOpen: preferencesDialog.visible || tagEditorDialog.visible || openUrlDialog.visible || shortcutsDialog.visible || diagnosticsDialog.visible || aboutDialog.visible || sleepTimerDialog.visible || newPlaylistDialog.visible || renamePlaylistDialog.visible || deleteConfirmDialog.visible
    readonly property bool isInputActive: topToolbar.isSearchActiveFocus || isAnyDialogOpen

    function playSelectedNow() {
        var selIds = bridge.trackModel.getSelectedTrackIds();
        if (selIds.length > 0) {
            bridge.playSelectionNow(selIds);
        } else if (trackTableView.currentIndex >= 0) {
            bridge.playTrackAtIndex(trackTableView.currentIndex);
        }
    }

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
        if (mainViewMode !== 4) {
            previousViewMode = mainViewMode;
        }
        mainViewMode = 4;
        activeNavSection = 4;
    }

    function switchViewMode(mode) {
        if (mode === 2) {
            switchToExpandedView();
            return;
        }
        if (mode === 4) {
            switchToNowPlaying();
            return;
        }
        if (mainViewMode === 2 || mainViewMode === 4) {
            previousViewMode = mainViewMode;
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

    FileDialog {
        id: exportArtworkDialog
        title: "Export Album Artwork"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Image files (*.jpg *.png)", "All files (*)"]
        property string albumTitle: ""
        property string albumArtist: ""
        onAccepted: {
            bridge.exportAlbumArtwork(albumTitle, albumArtist, selectedFile.toString());
        }
    }

    FileDialog {
        id: exportPlaylistDialog
        title: "Export Playlist"
        fileMode: FileDialog.SaveFile
        nameFilters: ["M3U8 Playlist (*.m3u8)", "M3U Playlist (*.m3u)", "All files (*)"]
        property string playlistName: ""
        onAccepted: {
            bridge.exportPlaylistFile(playlistName, selectedFile.toString());
        }
    }

    RenamePlaylistDialog {
        id: renamePlaylistDialog
        onPlaylistRenamed: (oldName, newName) => {
            if (activePlaylistName === oldName) {
                activePlaylistName = newName;
            }
        }
    }

    DeleteConfirmDialog {
        id: deleteConfirmDialog
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
        onEditTagsRequested: (tracks) => {
            if (tracks && tracks.length > 1) {
                tagEditorDialog.targetTracks = tracks;
                tagEditorDialog.targetTrack = tracks[0];
            } else if (tracks && tracks.length === 1) {
                tagEditorDialog.targetTracks = [];
                tagEditorDialog.targetTrack = tracks[0];
            } else if (trackContextMenu.targetTrack) {
                tagEditorDialog.targetTracks = [];
                tagEditorDialog.targetTrack = trackContextMenu.targetTrack;
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
        onDeleteFilesFromDiskRequested: (tracks) => {
            deleteConfirmDialog.tracksToDelete = tracks;
            deleteConfirmDialog.open();
        }
        onNewPlaylistRequested: {
            newPlaylistDialog.isSmart = false;
            newPlaylistDialog.open();
        }
        onPlaylistTracksChanged: {
            if (activeNavSection === 5 && activePlaylistName.length > 0) {
                bridge.openPlaylist(activePlaylistName);
            }
        }
    }

    ContextMenu {
        id: explorerContextMenu
        menuType: "explorer"
    }

    ContextMenu {
        id: columnHeaderContextMenu
        menuType: "header"
    }

    ContextMenu {
        id: viewportContextMenu
        menuType: "viewport"
        onOpenAudioFilesRequested: openAudioFileDialog.open()
        onOpenAudioFolderRequested: openMusicFolderDialog.open()
    }

    ContextMenu {
        id: albumContextMenu
        menuType: "album"
        onEditTagsRequested: (tracks) => {
            if (tracks && tracks.length > 0) {
                tagEditorDialog.targetTracks = tracks;
                tagEditorDialog.targetTrack = tracks[0];
                tagEditorDialog.open();
            }
        }
        onExportArtworkRequested: (album, artist) => {
            exportArtworkDialog.albumTitle = album;
            exportArtworkDialog.albumArtist = artist;
            exportArtworkDialog.open();
        }
        onNewPlaylistRequested: {
            newPlaylistDialog.isSmart = false;
            newPlaylistDialog.isEdit = false;
            newPlaylistDialog.open();
        }
    }

    ContextMenu {
        id: folderContextMenu
        menuType: "folder"
    }

    ContextMenu {
        id: playlistContextMenu
        menuType: "playlist"
        onRenamePlaylistRequested: (plName) => {
            renamePlaylistDialog.oldName = plName;
            renamePlaylistDialog.open();
        }
        onExportPlaylistRequested: (plName) => {
            exportPlaylistDialog.playlistName = plName;
            exportPlaylistDialog.open();
        }
        onEditSmartPlaylistRequested: (plName) => {
            newPlaylistDialog.openSmartEdit(plName, bridge.getSmartPlaylistRules(plName));
        }
        onDeletePlaylistRequested: (plName) => {
            bridge.deletePlaylist(plName);
            if (activePlaylistName === plName) {
                activePlaylistName = "";
            }
        }
    }

    ContextMenu {
        id: seekBarContextMenu
        menuType: "seekbar"
    }

    ContextMenu {
        id: volumeContextMenu
        menuType: "volume"
    }

    ContextMenu {
        id: codecContextMenu
        menuType: "codec"
        onShowAudioDiagnosticsRequested: diagnosticsDialog.open()
        onShowAudioSettingsRequested: {
            preferencesDialog.openTab(1);
            preferencesDialog.open();
        }
    }

    ContextMenu {
        id: miniPlayerContextMenu
        menuType: "miniplayer"
        stayOnTop: root.stayOnTop
        currentOpacity: root.opacity
        onStayOnTopChanged: {
            root.stayOnTop = miniPlayerContextMenu.stayOnTop;
        }
        onToggleMiniPlayerRequested: toggleMiniPlayer()
        onSetOpacityRequested: (op) => {
            root.opacity = op;
        }
        onCloseMiniPlayerRequested: toggleMiniPlayer()
    }

    ContextMenu {
        id: trayContextMenu
        menuType: "tray"
        onToggleWindowRequested: {
            if (root.visible) {
                root.hide();
            } else {
                root.show();
                root.raise();
                root.requestActivate();
            }
        }
        onShowPreferencesRequested: {
            root.show();
            root.raise();
            root.requestActivate();
            preferencesDialog.open();
        }
    }

    Platform.SystemTrayIcon {
        id: systemTrayIcon
        visible: true
        tooltip: "Parakeet Music Player"
        menu: Platform.Menu {
            Platform.MenuItem {
                text: bridge.isPlaying ? (bridge.currentTrackTitle + " - " + bridge.currentArtist) : "Parakeet (Stopped)"
                enabled: false
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: bridge.isPlaying ? "Pause" : "Play"
                onTriggered: bridge.togglePlayPause()
            }
            Platform.MenuItem {
                text: "Stop"
                onTriggered: bridge.stop()
            }
            Platform.MenuItem {
                text: "Next Track"
                onTriggered: bridge.nextTrack()
            }
            Platform.MenuItem {
                text: "Previous Track"
                onTriggered: bridge.previousTrack()
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: bridge.isMuted ? "Unmute" : "Mute"
                onTriggered: bridge.toggleMute()
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: root.visible ? "Hide Window" : "Show Window"
                onTriggered: {
                    if (root.visible) {
                        root.hide();
                    } else {
                        root.show();
                        root.raise();
                        root.requestActivate();
                    }
                }
            }
            Platform.MenuItem {
                text: "Preferences..."
                onTriggered: {
                    root.show();
                    root.raise();
                    root.requestActivate();
                    preferencesDialog.open();
                }
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: "Quit Parakeet"
                onTriggered: Qt.quit()
            }
        }
        onActivated: (reason) => {
            if (reason === Platform.SystemTrayIcon.Trigger || reason === Platform.SystemTrayIcon.DoubleClick) {
                if (root.visible) {
                    root.hide();
                } else {
                    root.show();
                    root.raise();
                    root.requestActivate();
                }
            }
        }
    }

    // Keyboard shortcuts - Playback Transport
    Shortcut { sequence: "Space"; enabled: !isInputActive; onActivated: bridge.togglePlayPause() }
    Shortcut { sequence: "Shift+Space"; enabled: !isInputActive; onActivated: bridge.toggleStopAfterCurrentTrack() }
    Shortcut { sequence: "Ctrl+Right"; onActivated: bridge.nextTrack() }
    Shortcut { sequence: "Ctrl+Left"; onActivated: bridge.previousTrack() }
    Shortcut { sequence: "Ctrl+Up"; onActivated: bridge.setVolume(bridge.volume + 0.05) }
    Shortcut { sequence: "Ctrl+Down"; onActivated: bridge.setVolume(bridge.volume - 0.05) }
    Shortcut { sequence: "Ctrl+M"; onActivated: bridge.toggleMute() }
    Shortcut { sequence: "Ctrl+S"; onActivated: bridge.cycleShuffleMode() }
    Shortcut { sequence: "Ctrl+R"; onActivated: bridge.cycleRepeatMode() }
    Shortcut { sequence: "Ctrl+."; onActivated: bridge.stop() }
    Shortcut { sequence: "Left"; enabled: !isInputActive; onActivated: bridge.seek(bridge.positionMs - 5000) }
    Shortcut { sequence: "Right"; enabled: !isInputActive; onActivated: bridge.seek(bridge.positionMs + 5000) }
    Shortcut { sequence: "Shift+Left"; enabled: !isInputActive; onActivated: bridge.seek(bridge.positionMs - 30000) }
    Shortcut { sequence: "Shift+Right"; enabled: !isInputActive; onActivated: bridge.seek(bridge.positionMs + 30000) }
    Shortcut { sequence: "Home"; enabled: !isInputActive; onActivated: bridge.seek(0) }
    Shortcut { sequence: "End"; enabled: !isInputActive; onActivated: bridge.seek(bridge.durationMs) }
    Shortcut { sequence: "["; enabled: !isInputActive; onActivated: bridge.setLoopPointA() }
    Shortcut { sequence: "]"; enabled: !isInputActive; onActivated: bridge.setLoopPointB() }
    Shortcut { sequence: "\\"; enabled: !isInputActive; onActivated: bridge.clearLoop() }

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
    Shortcut { sequence: "Ctrl+Z"; enabled: !isInputActive; onActivated: bridge.undo() }
    Shortcut { sequence: "Ctrl+Y"; enabled: !isInputActive; onActivated: bridge.redo() }
    Shortcut { sequence: "Ctrl+Shift+Z"; enabled: !isInputActive; onActivated: bridge.redo() }
    Shortcut { sequence: "Ctrl+A"; enabled: !isInputActive; onActivated: bridge.trackModel.selectAll() }
    Shortcut { sequence: "Ctrl+Shift+A"; enabled: !isInputActive; onActivated: bridge.trackModel.invertSelection() }
    Shortcut { sequence: "Ctrl+F"; onActivated: topToolbar.focusSearch() }
    Shortcut { sequence: "Shift+Escape"; onActivated: topToolbar.clearSearch() }
    Shortcut {
        sequence: "Ctrl+T"
        enabled: !isInputActive
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
        sequence: "Return"
        enabled: !isInputActive
        onActivated: playSelectedNow()
    }
    Shortcut {
        sequence: "Enter"
        enabled: !isInputActive
        onActivated: playSelectedNow()
    }
    Shortcut {
        sequence: "Delete"
        enabled: !isInputActive
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
            } else if (topToolbar.searchText.length > 0) {
                topToolbar.clearSearch();
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
    Shortcut { sequence: "Alt+4"; onActivated: switchViewMode(4) }
    Shortcut { sequence: "Alt+5"; onActivated: switchViewMode(3) }
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

                // Desktop Menu Bar Component
                AppMenuBar {
                    showLeftPanel: root.showLeftPanel
                    showColumnBrowser: root.showColumnBrowser
                    showRightPanel: root.showRightPanel
                    rightPanelTab: root.rightPanelTab
                    showEqualizer: root.showEqualizer
                    showStatusBar: root.showStatusBar
                    mainViewMode: root.mainViewMode
                    isMiniPlayer: root.isMiniPlayer
                    isFullscreen: root.visibility === Window.FullScreen

                    onShowLeftPanelChanged: root.showLeftPanel = showLeftPanel
                    onShowColumnBrowserChanged: root.showColumnBrowser = showColumnBrowser
                    onShowRightPanelChanged: root.showRightPanel = showRightPanel
                    onRightPanelTabChanged: root.rightPanelTab = rightPanelTab
                    onShowEqualizerChanged: root.showEqualizer = showEqualizer
                    onShowStatusBarChanged: root.showStatusBar = showStatusBar

                    onRequestOpenAudioFile: openAudioFileDialog.open()
                    onRequestOpenFolder: openMusicFolderDialog.open()
                    onRequestOpenUrl: openUrlDialog.open()
                    onRequestOpenCueSheet: openCueSheetDialog.open()
                    onRequestAddFolderToLibrary: folderDialog.open()
                    onRequestExportView: exportViewDialog.open()
                    onRequestPreferences: (cat) => {
                        preferencesDialog.activeCategory = cat;
                        preferencesDialog.open();
                    }
                    onRequestEditTags: {
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
                    onRequestNewPlaylist: (isSmart) => {
                        if (isSmart) {
                            newPlaylistDialog.openSmart();
                        } else {
                            newPlaylistDialog.isSmart = false;
                            newPlaylistDialog.open();
                        }
                    }
                    onRequestImportPlaylist: importPlaylistDialog.open()
                    onRequestSleepTimer: sleepTimerDialog.open()
                    onRequestShortcuts: shortcutsDialog.open()
                    onRequestDiagnostics: diagnosticsDialog.open()
                    onRequestAbout: aboutDialog.open()
                    onRequestFocusSearch: topToolbar.focusSearch()
                    onRequestClearSearch: topToolbar.clearSearch()
                    onRequestToggleFullscreen: root.toggleFullscreen()
                    onRequestToggleMiniPlayer: root.toggleMiniPlayer()
                    onRequestHideWindow: root.hide()
                    onRequestSwitchViewMode: (mode) => root.switchViewMode(mode)
                }

                Item { Layout.fillWidth: true }
            }
        }

        // 1px divider
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

        // Toolbar
        TopToolbar {
            id: topToolbar
            mainViewMode: root.mainViewMode
            showLeftPanel: root.showLeftPanel
            showRightPanel: root.showRightPanel
            onRequestSwitchViewMode: (mode) => root.switchViewMode(mode)
            onRequestSwitchToExpandedView: root.switchToExpandedView()
            onRequestSwitchToNowPlaying: root.switchToNowPlaying()
            onRequestOpenFolderDialog: folderDialog.open()
            onRequestPreferences: preferencesDialog.open()
            onToggleLeftPanel: root.showLeftPanel = !root.showLeftPanel
            onToggleRightPanel: root.showRightPanel = !root.showRightPanel
        }

        // 1px divider
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

        // Main workspace
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Left panel
            LeftSidebar {
                activeNavSection: root.activeNavSection
                activePlaylistName: root.activePlaylistName
                mainViewMode: root.mainViewMode
                visible: root.showLeftPanel
                onNavSectionSelected: (nav, mode) => {
                    root.activeNavSection = nav;
                    root.mainViewMode = mode;
                    root.activePlaylistName = "";
                }
                onPlaylistSelected: (name) => {
                    root.activeNavSection = 5;
                    root.activePlaylistName = name;
                    root.mainViewMode = 1;
                }
                onRequestSwitchToNowPlaying: {
                    root.activePlaylistName = "";
                    root.switchToNowPlaying();
                }
                onRequestShowColumnBrowser: (show) => root.showColumnBrowser = show
                onRequestAddMusicFolder: folderDialog.open()
                onRequestFolderContextMenu: (path) => {
                    folderContextMenu.targetFolderPath = path;
                    folderContextMenu.popup();
                }
                onRequestPlaylistContextMenu: (name, isSmart) => {
                    playlistContextMenu.targetPlaylistName = name;
                    playlistContextMenu.targetPlaylistIsSmart = isSmart;
                    playlistContextMenu.popup();
                }
                onRequestExplorerContextMenu: explorerContextMenu.popup()
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
                    ViewSubToolbar {
                        mainViewMode: root.mainViewMode
                        showColumnBrowser: root.showColumnBrowser
                        activeLetterFilter: root.activeLetterFilter
                        onRequestSwitchViewMode: (mode) => root.switchViewMode(mode)
                        onToggleColumnBrowser: root.showColumnBrowser = !root.showColumnBrowser
                        onLetterFilterSelected: (letter) => {
                            root.activeLetterFilter = letter;
                            bridge.filterByLetter(letter);
                        }
                    }

                    // Category filter browser (Genre, Artist, Album)
                    ColumnBrowserView {
                        showBrowser: root.showColumnBrowser
                        selectedGenreFilter: root.selectedGenreFilter
                        selectedArtistFilter: root.selectedArtistFilter
                        onGenreFilterChanged: (genre) => root.selectedGenreFilter = genre
                        onArtistFilterChanged: (artist) => root.selectedArtistFilter = artist
                        onRequestAlbumContextMenu: (title, artist) => {
                            albumContextMenu.targetAlbumTitle = title;
                            albumContextMenu.targetAlbumArtist = artist;
                            albumContextMenu.popup();
                        }
                        onRequestSwitchToExpandedView: (title, artist) => {
                            root.switchToExpandedView(title, artist);
                        }
                    }

                    // Track table view
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: mainViewMode === 1

                        TrackTableView {
                            id: trackTableView
                            anchors.fill: parent
                            isPlaylistView: activeNavSection === 5
                            activePlaylistName: root.activePlaylistName
                            onRequestColumnHeaderContextMenu: (colKey, colTitle) => {
                                columnHeaderContextMenu.targetColumnKey = colKey;
                                columnHeaderContextMenu.targetColumnTitle = colTitle;
                                columnHeaderContextMenu.popup();
                            }
                            onRequestViewportContextMenu: {
                                viewportContextMenu.popup();
                            }
                            onRequestTrackContextMenu: (targetTracks, targetTrack, targetFilePath, targetTitle, targetArtist, isPlView, plName) => {
                                trackContextMenu.targetTracks = targetTracks;
                                trackContextMenu.targetTrack = targetTrack;
                                trackContextMenu.targetFilePath = targetFilePath;
                                trackContextMenu.targetTitle = targetTitle;
                                trackContextMenu.targetArtist = targetArtist;
                                trackContextMenu.isPlaylistView = isPlView;
                                trackContextMenu.currentPlaylistName = plName;
                                trackContextMenu.popup();
                            }
                            onRequestExpandAlbum: (album, artist) => {
                                root.switchToExpandedView(album, artist);
                            }
                        }

                    }

                    // Album grid view
                    AlbumGridView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: mainViewMode === 0
                        onAlbumSelected: (title, artist) => root.switchToExpandedView(title, artist)
                        onRequestAlbumContextMenu: (title, artist) => {
                            albumContextMenu.targetAlbumTitle = title;
                            albumContextMenu.targetAlbumArtist = artist;
                            albumContextMenu.popup();
                        }
                    }

                    // Album details view
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: mainViewMode === 2

                        AlbumDetailView {
                            anchors.fill: parent
                            previousViewMode: root.previousViewMode
                            onRequestSwitchViewMode: (mode) => root.switchViewMode(mode)
                            onRequestSwitchToExpandedView: (title, artist) => root.switchToExpandedView(title, artist)
                            onRequestAlbumContextMenu: (title, artist) => {
                                albumContextMenu.targetAlbumTitle = title;
                                albumContextMenu.targetAlbumArtist = artist;
                                albumContextMenu.popup();
                            }
                            onRequestTrackContextMenu: (trk) => {
                                trackContextMenu.targetTracks = [trk];
                                trackContextMenu.targetTrack = trk;
                                trackContextMenu.targetFilePath = trk.filePath;
                                trackContextMenu.targetTitle = trk.title;
                                trackContextMenu.targetArtist = trk.artist;
                                trackContextMenu.isPlaylistView = false;
                                trackContextMenu.currentPlaylistName = "";
                                trackContextMenu.popup();
                            }
                        }
                    }

                    // Listening History View
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: mainViewMode === 3

                        HistoryView {
                            anchors.fill: parent
                        }
                    }

                    // Now Playing View
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: mainViewMode === 4

                        NowPlayingView {
                            anchors.fill: parent
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
            RightInspectorPanel {
                currentTab: root.rightPanelTab
                visible: root.showRightPanel
                onTabChanged: (tab) => root.rightPanelTab = tab
            }
        }

        // 1px divider
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.panelBorder }

        // Transport controls
        PlayerDeck {
            onRequestSwitchToNowPlaying: root.switchToNowPlaying()
            onRequestToggleFullscreen: root.toggleFullscreen()
            onRequestSeekBarContextMenu: seekBarContextMenu.popup()
            onRequestCodecContextMenu: codecContextMenu.popup()
            onRequestVolumeContextMenu: volumeContextMenu.popup()
        }

        // Status bar
        StatusBar {
            visible: showStatusBar
        }
    }

    // Mini-player mode layout
    MiniPlayer {
        id: miniPlayerContainer
        anchors.fill: parent
        visible: isMiniPlayer
        onRequestRestore: root.toggleMiniPlayer()
        onRequestContextMenu: {
            miniPlayerContextMenu.stayOnTop = root.stayOnTop;
            miniPlayerContextMenu.currentOpacity = root.opacity;
            miniPlayerContextMenu.popup();
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

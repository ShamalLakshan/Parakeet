import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Qt.labs.platform as Platform
import "components"
import "dialogs"
import "views"
import "menubar"
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

    function playSelectedNow() {
        var selIds = bridge.trackModel.getSelectedTrackIds();
        if (selIds.length > 0) {
            bridge.playSelectionNow(selIds);
        } else if (trackTableListView.currentIndex >= 0) {
            bridge.playTrackAtIndex(trackTableListView.currentIndex);
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

    Dialog {
        id: renamePlaylistDialog
        title: "Rename Playlist"
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 380
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        property string oldName: ""

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.panelBorder
            border.width: 1
            radius: Theme.cornerRadiusMedium
        }

        contentItem: ColumnLayout {
            spacing: 12
            anchors.fill: parent
            anchors.margins: 16

            Text {
                text: "Rename Playlist"
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                color: Theme.textPrimary
            }

            TextField {
                id: renameInput
                Layout.fillWidth: true
                placeholderText: "New playlist name"
                color: Theme.textPrimary
                background: Rectangle {
                    color: Theme.surfaceElevated
                    border.color: renameInput.activeFocus ? Theme.accent : Theme.panelBorder
                    radius: Theme.cornerRadiusSmall
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8

                Button {
                    text: "Cancel"
                    onClicked: renamePlaylistDialog.close()
                }

                Button {
                    text: "Rename"
                    enabled: renameInput.text.trim().length > 0 && renameInput.text.trim() !== renamePlaylistDialog.oldName
                    onClicked: {
                        bridge.renamePlaylist(renamePlaylistDialog.oldName, renameInput.text.trim());
                        if (activePlaylistName === renamePlaylistDialog.oldName) {
                            activePlaylistName = renameInput.text.trim();
                        }
                        renamePlaylistDialog.close();
                    }
                }
            }
        }

        onAboutToShow: {
            renameInput.text = oldName;
            renameInput.forceActiveFocus();
        }
    }

    Dialog {
        id: deleteConfirmDialog
        title: "Delete File from Disk"
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 440
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        property var tracksToDelete: []

        background: Rectangle {
            color: Theme.surface
            border.color: Theme.error
            border.width: 1
            radius: Theme.cornerRadiusMedium
        }

        contentItem: ColumnLayout {
            spacing: 14
            anchors.fill: parent
            anchors.margins: 18

            RowLayout {
                spacing: 12
                Layout.fillWidth: true
                VectorIcon {
                    name: "trash"
                    width: 24
                    height: 24
                    color: Theme.error
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        text: deleteConfirmDialog.tracksToDelete.length > 1
                            ? ("Delete " + deleteConfirmDialog.tracksToDelete.length + " Files from Disk?")
                            : "Delete Audio File from Disk?"
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.textPrimary
                    }
                    Text {
                        text: "This will permanently delete the selected audio file(s) from your storage device and library database. This action CANNOT be undone."
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textMuted
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(120, Math.max(36, deleteConfirmDialog.tracksToDelete.length * 24 + 8))
                color: Theme.surfaceElevated
                border.color: Theme.panelBorder
                border.width: 1
                radius: Theme.cornerRadiusSmall
                clip: true

                ListView {
                    anchors.fill: parent
                    anchors.margins: 6
                    model: deleteConfirmDialog.tracksToDelete
                    ScrollBar.vertical: ScrollBar {}
                    delegate: Text {
                        width: parent.width
                        text: (modelData.artist ? (modelData.artist + " - ") : "") + (modelData.title || modelData.filePath || "")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textSecondary
                        elide: Text.ElideMiddle
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }

                Button {
                    text: "Cancel"
                    onClicked: deleteConfirmDialog.close()
                }

                Button {
                    contentItem: Text {
                        text: "Delete Permanently"
                        color: "#FFFFFF"
                        font.bold: true
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: Theme.error
                        radius: Theme.cornerRadiusSmall
                    }
                    onClicked: {
                        var ids = [];
                        for (var i = 0; i < deleteConfirmDialog.tracksToDelete.length; ++i) {
                            if (deleteConfirmDialog.tracksToDelete[i].id) {
                                ids.push(deleteConfirmDialog.tracksToDelete[i].id);
                            }
                        }
                        deleteConfirmDialog.close();
                        if (ids.length > 0) {
                            bridge.deleteFilesFromDisk(ids);
                        }
                    }
                }
            }
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
        sequence: "Return"
        enabled: !searchTextInput.activeFocus && !tagEditorDialog.visible && !newPlaylistDialog.visible && !preferencesDialog.visible && !diagnosticsDialog.visible && !shortcutsDialog.visible && !aboutDialog.visible && !sleepTimerDialog.visible && !openUrlDialog.visible && !deleteConfirmDialog.visible
        onActivated: playSelectedNow()
    }
    Shortcut {
        sequence: "Enter"
        enabled: !searchTextInput.activeFocus && !tagEditorDialog.visible && !newPlaylistDialog.visible && !preferencesDialog.visible && !diagnosticsDialog.visible && !shortcutsDialog.visible && !aboutDialog.visible && !sleepTimerDialog.visible && !openUrlDialog.visible && !deleteConfirmDialog.visible
        onActivated: playSelectedNow()
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
                    onRequestFocusSearch: {
                        searchTextInput.forceActiveFocus();
                        searchTextInput.selectAll();
                    }
                    onRequestClearSearch: {
                        searchTextInput.text = "";
                        bridge.search("");
                    }
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
                            { name: "NOW PLAYING", icon: "disc", mode: 4 }
                        ]

                        delegate: Rectangle {
                            property bool isTabActive: mainViewMode === modelData.mode

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
                                    } else if (modelData.mode === 4) {
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
                                            activePlaylistName = "";
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
                                color: (activeNavSection === 4 && mainViewMode === 4) ? Theme.selection : (npMouse.containsMouse ? Theme.surfaceElevated : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 10
                                    spacing: 8
                                    VectorIcon { name: "disc"; width: 11; height: 11; color: (activeNavSection === 4 && mainViewMode === 4) ? Theme.accent : Theme.textMuted }
                                    Text { text: "Now Playing"; font.pixelSize: 11; color: (activeNavSection === 4 && mainViewMode === 4) ? Theme.textPrimary : Theme.textSecondary; Layout.fillWidth: true }
                                }
                                MouseArea {
                                    id: npMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        activePlaylistName = "";
                                        switchToNowPlaying();
                                    }
                                }
                            }

                            Repeater {
                                model: bridge.availablePlaylists
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 26
                                    color: (activeNavSection === 5 && activePlaylistName === modelData) ? Theme.selection : (plItemMouse.containsMouse ? Theme.surfaceElevated : "transparent")

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 10
                                        spacing: 8
                                        VectorIcon {
                                            name: bridge.isSmartPlaylist(modelData) ? "settings" : "playlist"
                                            width: 11
                                            height: 11
                                            color: (activeNavSection === 5 && activePlaylistName === modelData) ? Theme.accent : Theme.textMuted
                                        }
                                        Text {
                                            text: modelData
                                            font.pixelSize: 11
                                            color: (activeNavSection === 5 && activePlaylistName === modelData) ? Theme.textPrimary : Theme.textSecondary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }
                                    MouseArea {
                                        id: plItemMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.RightButton) {
                                                playlistContextMenu.targetPlaylistName = modelData;
                                                playlistContextMenu.targetPlaylistIsSmart = bridge.isSmartPlaylist(modelData);
                                                playlistContextMenu.popup();
                                            } else {
                                                activeNavSection = 5;
                                                activePlaylistName = modelData;
                                                mainViewMode = 1;
                                                bridge.openPlaylist(modelData);
                                            }
                                        }
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

                            Repeater {
                                model: bridge.monitoredFolders
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 26
                                    color: folderItemMouse.containsMouse ? Theme.surfaceElevated : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        VectorIcon {
                                            name: "folder"
                                            width: 11
                                            height: 11
                                            color: Theme.textMuted
                                        }

                                        Text {
                                            text: {
                                                var parts = modelData.split("/");
                                                return (parts.length > 0 && parts[parts.length - 1].length > 0) ? parts[parts.length - 1] : modelData;
                                            }
                                            font.pixelSize: 11
                                            color: Theme.textSecondary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    MouseArea {
                                        id: folderItemMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.RightButton) {
                                                folderContextMenu.targetFolderPath = modelData;
                                                folderContextMenu.popup();
                                            } else {
                                                bridge.openFolder(modelData, false);
                                            }
                                        }
                                        ToolTip.visible: folderItemMouse.containsMouse
                                        ToolTip.text: modelData + "\nRight-click for options (Rescan, Reveal, Remove)"
                                    }
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

                                Rectangle {
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 24
                                    width: 26
                                    height: 24
                                    radius: 2
                                    color: mainViewMode === 4 ? Theme.selection : (vm4Mouse.containsMouse ? Theme.surfaceElevated : "transparent")
                                    border.color: mainViewMode === 4 ? Theme.accent : "transparent"
                                    VectorIcon { anchors.centerIn: parent; name: "disc"; width: 12; height: 12; color: mainViewMode === 4 ? Theme.accent : Theme.textMuted }
                                    MouseArea {
                                        id: vm4Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: switchViewMode(4)
                                    }
                                    ToolTip.visible: vm4Mouse.containsMouse
                                    ToolTip.text: "Now Playing View (Alt+4)"
                                }
                            }

                            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 16; width: 1; height: 16; color: Theme.panelBorder }

                            // Toggle Category Filters Button
                            Rectangle {
                                Layout.preferredWidth: colBtnLayout.implicitWidth + 14
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

                                    VectorIcon {
                                        name: "filter"
                                        width: 10
                                        height: 10
                                        color: showColumnBrowser ? Theme.accent : Theme.textMuted
                                    }

                                    Text {
                                        text: "Filters"
                                        font.pixelSize: 10
                                        font.bold: showColumnBrowser
                                        color: showColumnBrowser ? Theme.accentHover : Theme.textSecondary
                                    }

                                    Text {
                                        text: showColumnBrowser ? "▲" : "▼"
                                        font.pixelSize: 8
                                        color: showColumnBrowser ? Theme.accent : Theme.textMuted
                                    }
                                }

                                MouseArea {
                                    id: cbMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: showColumnBrowser = !showColumnBrowser
                                }

                                ToolTip.visible: cbMouse.containsMouse
                                ToolTip.text: (showColumnBrowser ? "Collapse" : "Expand") + " Category Filters (Genre, Artist, Album) (Ctrl+2)"
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

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        seekBarContextMenu.popup();
                                    }
                                }
                            }
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

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        seekBarContextMenu.popup();
                                    }
                                }
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
                            text: bridge.showRemainingTime ? ("-" + bridge.formatDuration(Math.max(0, bridge.durationMs - bridge.positionMs))) : bridge.durationStr
                            font.pixelSize: 10
                            color: Theme.textMuted
                            Layout.preferredWidth: 36

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        seekBarContextMenu.popup();
                                    } else {
                                        bridge.showRemainingTime = !bridge.showRemainingTime;
                                    }
                                }
                                ToolTip.visible: containsMouse
                                ToolTip.text: "Click to toggle remaining time • Right-click for options"
                            }
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

                        MouseArea {
                            id: deckArtMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: switchToNowPlaying()
                        }
                        ToolTip.visible: deckArtMouse.containsMouse
                        ToolTip.text: "Open Now Playing View"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: deckTrackCol.implicitHeight

                            ColumnLayout {
                                id: deckTrackCol
                                anchors.fill: parent
                                spacing: 2

                                Text {
                                    text: bridge.currentTrackTitle
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: deckTrackMouse.containsMouse ? Theme.accent : Theme.textPrimary
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
                            }

                            MouseArea {
                                id: deckTrackMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: switchToNowPlaying()
                            }
                            ToolTip.visible: deckTrackMouse.containsMouse
                            ToolTip.text: "Open Now Playing View"
                        }

                        RowLayout {
                            spacing: 6
                            Layout.fillWidth: true

                            Rectangle {
                                visible: bridge.currentCodec.length > 0
                                width: codecBadgeText.implicitWidth + 8
                                height: 16
                                radius: 2
                                color: codecMouse.containsMouse ? Theme.surfaceElevated : Theme.selection
                                border.color: Theme.panelBorder
                                border.width: 1

                                Text {
                                    id: codecBadgeText
                                    anchors.centerIn: parent
                                    text: bridge.currentCodec.toUpperCase()
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: Theme.accent
                                }

                                MouseArea {
                                    id: codecMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        codecContextMenu.popup();
                                    }
                                    ToolTip.visible: codecMouse.containsMouse
                                    ToolTip.text: "Right-click or click for Audio Diagnostics & Settings"
                                }
                            }

                            Text {
                                text: bridge.currentAudioSpecs
                                visible: text.length > 0
                                font.pixelSize: 9
                                color: Theme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            codecContextMenu.popup();
                                        }
                                    }
                                }
                            }
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
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    volumeContextMenu.popup();
                                } else {
                                    bridge.toggleMute();
                                }
                            }
                        }
                    }

                    Slider {
                        id: volumeSlider
                        enabled: !bridge.volumeLocked
                        Layout.preferredWidth: 80
                        from: 0
                        to: 1
                        value: bridge.volume
                        onMoved: bridge.setVolume(value)

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    volumeContextMenu.popup();
                                }
                            }
                        }

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
                        text: bridge.volumeLocked ? "🔒 " + Math.round(bridge.volume * 100) + "%" : (Math.round(bridge.volume * 100) + "%")
                        font.pixelSize: 9
                        color: bridge.volumeLocked ? Theme.accent : Theme.textMuted
                        Layout.preferredWidth: 32

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.RightButton
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.RightButton) {
                                    volumeContextMenu.popup();
                                }
                            }
                            ToolTip.visible: containsMouse
                            ToolTip.text: bridge.volumeLocked ? "Volume is locked (Right-click to unlock)" : "Right-click for volume options"
                        }
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

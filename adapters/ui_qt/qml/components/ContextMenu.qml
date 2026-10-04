import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Menu {
    id: root

    property string menuType: "track" // "track", "header", "explorer"
    property var targetTrack: null
    property var targetTracks: []
    property string targetFilePath: ""
    property string targetTitle: ""
    property string targetArtist: ""
    property bool isPlaylistView: false
    property string currentPlaylistName: ""

    readonly property int selectedCount: targetTracks && targetTracks.length > 0 ? targetTracks.length : (targetTrack ? 1 : 0)
    readonly property bool isMultiSelect: selectedCount > 1

    function getEffectiveTracks() {
        if (targetTracks && targetTracks.length > 0) {
            return targetTracks;
        }
        if (targetTrack) {
            return [targetTrack];
        }
        return [];
    }

    function getEffectiveTrackIds() {
        var tracks = getEffectiveTracks();
        var ids = [];
        for (var i = 0; i < tracks.length; ++i) {
            if (tracks[i].id) {
                ids.push(tracks[i].id);
            }
        }
        return ids;
    }

    signal viewTrackPropertiesRequested()
    signal viewAlbumRequested(string album, string artist)
    signal editTagsRequested(var tracks)
    signal deleteTracksRequested(var tracks)
    signal deleteFilesFromDiskRequested(var tracks)
    signal newPlaylistRequested()
    signal playlistTracksChanged()

    background: Rectangle {
        implicitWidth: 230
        color: Theme.surfaceElevated
        border.color: Theme.panelBorder
        border.width: 1
        radius: Theme.cornerRadiusSmall
    }

    delegate: MenuItem {
        id: rootMenuItem
        implicitHeight: visible ? 26 : 0
        implicitWidth: 230

        contentItem: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 12
            spacing: 8

            Text {
                text: rootMenuItem.text
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                color: rootMenuItem.enabled ? (rootMenuItem.highlighted ? Theme.textPrimary : Theme.textSecondary) : Theme.textMuted
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: rootMenuItem.subMenu !== null && rootMenuItem.subMenu !== undefined
                text: "›"
                font.pixelSize: 13
                font.bold: true
                color: rootMenuItem.highlighted ? Theme.accent : Theme.textMuted
            }
        }

        background: Rectangle {
            implicitWidth: 230
            implicitHeight: 26
            color: rootMenuItem.highlighted ? Theme.selection : "transparent"
            radius: Theme.cornerRadiusSmall
        }
    }

    component ContextMenuItem: MenuItem {
        id: cItem
        implicitHeight: visible ? 26 : 0
        implicitWidth: 230

        contentItem: RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 12
            spacing: 8

            Text {
                text: cItem.text
                font.pixelSize: Theme.fontSizeSmall
                font.family: Theme.fontFamily
                color: cItem.enabled ? (cItem.highlighted ? Theme.textPrimary : Theme.textSecondary) : Theme.textMuted
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                visible: cItem.subMenu !== null && cItem.subMenu !== undefined
                text: "›"
                font.pixelSize: 13
                font.bold: true
                color: cItem.highlighted ? Theme.accent : Theme.textMuted
            }
        }

        background: Rectangle {
            implicitWidth: 230
            implicitHeight: 26
            color: cItem.highlighted ? Theme.selection : "transparent"
            radius: Theme.cornerRadiusSmall
        }
    }

    component ContextMenuSeparator: MenuSeparator {
        id: cSep
        implicitHeight: visible ? 5 : 0
        contentItem: Rectangle {
            implicitWidth: 210
            implicitHeight: 1
            color: Theme.panelBorder
            visible: cSep.visible
        }
    }

    component ContextSubMenu: Menu {
        id: subMenuRoot
        implicitWidth: 230

        delegate: MenuItem {
            id: sItem
            implicitHeight: visible ? 26 : 0
            implicitWidth: 230

            contentItem: RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: sItem.text
                    font.pixelSize: Theme.fontSizeSmall
                    font.family: Theme.fontFamily
                    color: sItem.enabled ? (sItem.highlighted ? Theme.textPrimary : Theme.textSecondary) : Theme.textMuted
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    visible: sItem.subMenu !== null && sItem.subMenu !== undefined
                    text: "›"
                    font.pixelSize: 13
                    font.bold: true
                    color: sItem.highlighted ? Theme.accent : Theme.textMuted
                }
            }

            background: Rectangle {
                implicitWidth: 230
                implicitHeight: 26
                color: sItem.highlighted ? Theme.selection : "transparent"
                radius: Theme.cornerRadiusSmall
            }
        }

        background: Rectangle {
            implicitWidth: 230
            color: Theme.surfaceElevated
            border.color: Theme.panelBorder
            border.width: 1
            radius: Theme.cornerRadiusSmall
        }
    }

    // 1. Play Now (Enter)
    ContextMenuItem {
        text: root.isMultiSelect ? ("Play Now (" + root.selectedCount + " Tracks) (Enter)") : "Play Now (Enter)"
        visible: root.menuType === "track"
        onTriggered: {
            var ids = root.getEffectiveTrackIds();
            if (ids.length > 0) {
                bridge.playSelectionNow(ids);
            }
        }
    }

    // 2. Play Next
    ContextMenuItem {
        text: root.isMultiSelect ? ("Play Next (" + root.selectedCount + " Tracks)") : "Play Next"
        visible: root.menuType === "track"
        onTriggered: {
            var ids = root.getEffectiveTrackIds();
            if (ids.length > 0) {
                bridge.playTracksNext(ids);
            }
        }
    }

    // 3. Add to Queue / Queue Last
    ContextMenuItem {
        text: root.isMultiSelect ? ("Add to Queue (" + root.selectedCount + " Tracks)") : "Add to Queue / Queue Last"
        visible: root.menuType === "track"
        onTriggered: {
            var ids = root.getEffectiveTrackIds();
            if (ids.length > 0) {
                bridge.queueTracksLast(ids);
            }
        }
    }

    // 4. Play Next in Album Shuffle
    ContextMenuItem {
        text: "Play Next in Album Shuffle"
        visible: root.menuType === "track"
        onTriggered: {
            var ids = root.getEffectiveTrackIds();
            if (ids.length > 0) {
                bridge.playNextInAlbumShuffle(ids);
            }
        }
    }

    ContextMenuSeparator {
        visible: root.menuType === "track"
    }

    // 5. Add to Playlist >
    ContextSubMenu {
        id: addToPlaylistMenu
        title: "Add to Playlist"
        visible: root.menuType === "track"

        ContextMenuItem {
            text: "New Playlist..."
            onTriggered: {
                root.newPlaylistRequested();
            }
        }

        ContextMenuSeparator {
            visible: bridge.availablePlaylists.length > 0
        }

        Instantiator {
            model: bridge.availablePlaylists
            onObjectAdded: (index, object) => addToPlaylistMenu.insertItem(index + 2, object)
            onObjectRemoved: (index, object) => addToPlaylistMenu.removeItem(object)
            delegate: ContextMenuItem {
                text: modelData
                onTriggered: {
                    var tracks = root.getEffectiveTracks();
                    bridge.addTracksToPlaylist(modelData, tracks);
                }
            }
        }
    }

    // 6. Show in File Manager / Open Containing Folder
    ContextMenuItem {
        text: "Show in File Manager"
        visible: root.menuType === "track"
        onTriggered: {
            var path = root.targetFilePath;
            if (!path && root.targetTracks && root.targetTracks.length > 0) {
                path = root.targetTracks[0].filePath || "";
            }
            if (path && path.length > 0) {
                bridge.showInFileManager(path);
            }
        }
    }

    // 7. View Technical Specs in Inspector
    ContextMenuItem {
        text: "View Technical Specs in Inspector"
        visible: root.menuType === "track"
        onTriggered: {
            root.viewTrackPropertiesRequested();
        }
    }

    // Go to Album (single selection only)
    ContextMenuItem {
        text: "Go to Album"
        visible: root.menuType === "track" && !root.isMultiSelect && root.targetTrack && root.targetTrack.album && root.targetTrack.album.length > 0
        onTriggered: {
            root.viewAlbumRequested(root.targetTrack.album, root.targetTrack.artist);
        }
    }

    ContextMenuSeparator {
        visible: root.menuType === "track"
    }

    // 8. Copy Information >
    ContextSubMenu {
        title: "Copy Information"
        visible: root.menuType === "track"

        ContextMenuItem {
            text: root.isMultiSelect ? "Copy Title & Artist (All)" : "Copy Title & Artist"
            onTriggered: {
                var tracks = root.getEffectiveTracks();
                var lines = [];
                for (var i = 0; i < tracks.length; ++i) {
                    var t = tracks[i];
                    lines.push((t.artist || "Unknown Artist") + " - " + (t.title || "Unknown Title"));
                }
                bridge.copyToClipboard(lines.join("\n"));
            }
        }

        ContextMenuItem {
            text: "Copy Full Metadata Summary"
            onTriggered: {
                var tracks = root.getEffectiveTracks();
                var summaries = [];
                for (var i = 0; i < tracks.length; ++i) {
                    var t = tracks[i];
                    var s = "Title: " + (t.title || "") + "\n" +
                            "Artist: " + (t.artist || "") + "\n" +
                            "Album: " + (t.album || "") + "\n" +
                            "Genre: " + (t.genre || "") + "\n" +
                            "Year: " + (t.year || "") + "\n" +
                            "Track: " + (t.trackNumber || "") + "\n" +
                            "Duration: " + (t.durationFormatted || "") + "\n" +
                            "Format: " + (t.codec || "") + (t.bitDepth ? (" • " + t.bitDepth + "-bit") : "") + (t.sampleRate ? (" / " + (t.sampleRate / 1000) + "kHz") : "") + "\n" +
                            "Bitrate: " + (t.bitrate ? (t.bitrate + " kbps") : "") + "\n" +
                            "File Path: " + (t.filePath || "");
                    summaries.push(s);
                }
                bridge.copyToClipboard(summaries.join("\n\n---\n\n"));
            }
        }

        ContextMenuItem {
            text: root.isMultiSelect ? "Copy Audio File Paths" : "Copy Audio File Path"
            onTriggered: {
                var tracks = root.getEffectiveTracks();
                var paths = [];
                for (var i = 0; i < tracks.length; ++i) {
                    if (tracks[i].filePath) paths.push(tracks[i].filePath);
                }
                bridge.copyToClipboard(paths.join("\n"));
            }
        }
    }

    // 9. Rating >
    ContextSubMenu {
        title: "Rating"
        visible: root.menuType === "track"

        property bool isFav: root.targetTrack && root.targetTrack.id ? bridge.isTrackFavorite(root.targetTrack.id) : false
        property int curRating: root.targetTrack && root.targetTrack.id ? bridge.getTrackRating(root.targetTrack.id) : 0

        ContextMenuItem {
            text: parent.isFav ? "❤️  Favorite (Remove)" : "🤍  Favorite (Add)"
            onTriggered: {
                var ids = root.getEffectiveTrackIds();
                bridge.toggleTracksFavorite(ids);
            }
        }

        ContextMenuSeparator {}

        ContextMenuItem {
            text: "☆☆☆☆☆  No Rating" + (parent.curRating === 0 ? "  ✓" : "")
            onTriggered: {
                var ids = root.getEffectiveTrackIds();
                bridge.setTracksRating(ids, 0);
            }
        }

        ContextMenuItem {
            text: "★☆☆☆☆  1 Star" + (parent.curRating === 1 ? "  ✓" : "")
            onTriggered: {
                var ids = root.getEffectiveTrackIds();
                bridge.setTracksRating(ids, 1);
            }
        }

        ContextMenuItem {
            text: "★★☆☆☆  2 Stars" + (parent.curRating === 2 ? "  ✓" : "")
            onTriggered: {
                var ids = root.getEffectiveTrackIds();
                bridge.setTracksRating(ids, 2);
            }
        }

        ContextMenuItem {
            text: "★★★☆☆  3 Stars" + (parent.curRating === 3 ? "  ✓" : "")
            onTriggered: {
                var ids = root.getEffectiveTrackIds();
                bridge.setTracksRating(ids, 3);
            }
        }

        ContextMenuItem {
            text: "★★★★☆  4 Stars" + (parent.curRating === 4 ? "  ✓" : "")
            onTriggered: {
                var ids = root.getEffectiveTrackIds();
                bridge.setTracksRating(ids, 4);
            }
        }

        ContextMenuItem {
            text: "★★★★★  5 Stars" + (parent.curRating === 5 ? "  ✓" : "")
            onTriggered: {
                var ids = root.getEffectiveTrackIds();
                bridge.setTracksRating(ids, 5);
            }
        }
    }

    // 10. Edit Tags & Properties... (Ctrl+T)
    ContextMenuItem {
        text: root.isMultiSelect ? ("Edit Tags & Properties... (" + root.selectedCount + " Tracks) (Ctrl+T)") : "Edit Tags & Properties... (Ctrl+T)"
        visible: root.menuType === "track"
        onTriggered: root.editTagsRequested(root.getEffectiveTracks())
    }

    ContextMenuSeparator {
        visible: root.menuType === "track"
    }

    // 11. Remove from Playlist (Only visible when viewing a playlist)
    ContextMenuItem {
        text: root.isMultiSelect ? ("Remove " + root.selectedCount + " Tracks from Playlist") : "Remove from Playlist"
        visible: root.menuType === "track" && root.isPlaylistView
        onTriggered: {
            var tracks = root.getEffectiveTracks();
            bridge.removeTracksFromPlaylist(root.currentPlaylistName, tracks);
            root.playlistTracksChanged();
        }
    }

    // 12. Remove from Library / Prune Record
    ContextMenuItem {
        text: root.isMultiSelect ? ("Remove " + root.selectedCount + " Tracks from Library") : "Remove from Library / Prune Record"
        visible: root.menuType === "track"
        onTriggered: root.deleteTracksRequested(root.getEffectiveTracks())
    }

    // 13. Delete File from Disk...
    ContextMenuItem {
        text: root.isMultiSelect ? ("Delete " + root.selectedCount + " Files from Disk...") : "Delete File from Disk..."
        visible: root.menuType === "track"
        onTriggered: root.deleteFilesFromDiskRequested(root.getEffectiveTracks())
    }

    // Explorer actions
    ContextMenuSeparator {
        visible: root.menuType === "explorer"
    }

    ContextMenuItem {
        text: "Rescan Library Folders"
        visible: root.menuType === "explorer"
        onTriggered: bridge.rescanAllMonitoredFolders()
    }

    ContextMenuItem {
        text: "Remove Missing Files"
        visible: root.menuType === "explorer"
        onTriggered: bridge.purgeMissingTracks()
    }

    ContextMenuItem {
        text: "Clear Library Database"
        visible: root.menuType === "explorer"
        onTriggered: bridge.clearLibrary()
    }
}

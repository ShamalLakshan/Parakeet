import QtQuick
import QtQuick.Controls

Menu {
    id: root

    property string menuType: "track" // "track", "header", "explorer"
    property var targetTrack: null
    property string targetFilePath: ""
    property string targetTitle: ""
    property string targetArtist: ""

    signal viewTrackPropertiesRequested()
    signal viewAlbumRequested(string album, string artist)
    signal editTagsRequested(var track)
    signal deleteTracksRequested(var tracks)

    background: Rectangle {
        implicitWidth: 200
        color: Theme.surfaceElevated
        border.color: Theme.panelBorder
        border.width: 1
        radius: Theme.cornerRadiusSmall
    }

    component ContextMenuItem: MenuItem {
        id: cItem
        implicitHeight: visible ? 26 : 0
        implicitWidth: 200

        contentItem: Text {
            leftPadding: 16
            rightPadding: 16
            text: cItem.text
            font.pixelSize: Theme.fontSizeSmall
            font.family: Theme.fontFamily
            color: cItem.enabled ? (cItem.highlighted ? Theme.textPrimary : Theme.textSecondary) : Theme.textMuted
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            implicitWidth: 200
            implicitHeight: 26
            color: cItem.highlighted ? Theme.selection : "transparent"
            radius: Theme.cornerRadiusSmall
        }
    }

    component ContextMenuSeparator: MenuSeparator {
        id: cSep
        implicitHeight: visible ? 5 : 0
        contentItem: Rectangle {
            implicitWidth: 180
            implicitHeight: 1
            color: Theme.panelBorder
            visible: cSep.visible
        }
    }

    // Track actions
    ContextMenuItem {
        text: "Play Now"
        visible: root.menuType === "track"
        onTriggered: {
            if (root.targetTrack && root.targetTrack.id) {
                bridge.playNow(root.targetTrack.id);
            }
        }
    }

    ContextMenuItem {
        text: "Play Next"
        visible: root.menuType === "track"
        onTriggered: {
            if (root.targetTrack && root.targetTrack.id) {
                bridge.playNext(root.targetTrack.id);
            }
        }
    }

    ContextMenuItem {
        text: "Add to Queue"
        visible: root.menuType === "track"
        onTriggered: {
            if (root.targetTrack && root.targetTrack.id) {
                bridge.queueLast(root.targetTrack.id);
            }
        }
    }

    ContextMenuItem {
        text: "Go to Album"
        visible: root.menuType === "track" && root.targetTrack && root.targetTrack.album && root.targetTrack.album.length > 0
        onTriggered: {
            root.viewAlbumRequested(root.targetTrack.album, root.targetTrack.artist);
        }
    }

    ContextMenuSeparator {
        visible: root.menuType === "track"
    }

    ContextMenuItem {
        text: "Show in File Manager"
        visible: root.menuType === "track"
        onTriggered: {
            if (root.targetFilePath.length > 0) {
                bridge.showInFileManager(root.targetFilePath);
            }
        }
    }

    ContextMenuItem {
        text: "Track Properties"
        visible: root.menuType === "track"
        onTriggered: {
            root.viewTrackPropertiesRequested();
        }
    }

    ContextMenuItem {
        text: "Copy File Path"
        visible: root.menuType === "track"
        onTriggered: {
            if (root.targetFilePath.length > 0) {
                bridge.copyToClipboard(root.targetFilePath);
            }
        }
    }

    ContextMenuItem {
        text: "Copy Track Info"
        visible: root.menuType === "track"
        onTriggered: {
            var info = root.targetArtist + " - " + root.targetTitle;
            bridge.copyToClipboard(info);
        }
    }

    ContextMenuItem {
        text: "Edit Tags..."
        visible: root.menuType === "track"
        onTriggered: root.editTagsRequested(root.targetTrack)
    }

    ContextMenuItem {
        text: "Remove from Library"
        visible: root.menuType === "track"
        onTriggered: root.deleteTracksRequested(root.targetTrack ? [root.targetTrack] : [])
    }

    ContextMenuSeparator {
        visible: root.menuType === "track"
    }

    ContextMenuItem {
        text: "Remove Missing Files"
        visible: root.menuType === "track" || root.menuType === "explorer"
        onTriggered: bridge.purgeMissingTracks()
    }

    // Explorer actions
    ContextMenuItem {
        text: "Rescan Library Folders"
        visible: root.menuType === "explorer"
        onTriggered: bridge.rescanAllMonitoredFolders()
    }

    ContextMenuItem {
        text: "Clear Library Database"
        visible: root.menuType === "explorer"
        onTriggered: bridge.clearLibrary()
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Item {
    id: root

    property bool isPlaylistView: false
    property string activePlaylistName: ""
    property alias currentIndex: trackTableListView.currentIndex

    signal requestColumnHeaderContextMenu(string colKey, string colTitle)
    signal requestViewportContextMenu()
    signal requestTrackContextMenu(var targetTracks, var targetTrack, string targetFilePath, string targetTitle, string targetArtist, bool isPlaylistView, string currentPlaylistName)
    signal requestExpandAlbum(string album, string artist)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        component TableHeaderCell: Item {
            id: cellRoot
            property string colKey: ""
            property string colTitle: ""
            property string headerText: ""
            property bool isFillWidth: false

            visible: bridge.isColumnVisible(colKey)
            Layout.preferredWidth: bridge.getColumnWidth(colKey)
            Layout.minimumWidth: isFillWidth ? 100 : 30
            Layout.fillWidth: isFillWidth
            Layout.fillHeight: true
            clip: true

            Rectangle {
                anchors.fill: parent
                color: hCellMouse.containsMouse ? Theme.surfaceHighlight : "transparent"
                radius: 2
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                spacing: 4

                Text {
                    text: cellRoot.headerText
                    font.pixelSize: 9
                    font.bold: true
                    color: (bridge.trackModel.sortColumn === cellRoot.colKey) ? Theme.accent : Theme.textMuted
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillWidth: true
                }

                Text {
                    visible: bridge.trackModel.sortColumn === cellRoot.colKey
                    text: bridge.trackModel.sortAscending ? "▲" : "▼"
                    font.pixelSize: 8
                    color: Theme.accent
                    verticalAlignment: Text.AlignVCenter
                }
            }

            MouseArea {
                id: hCellMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        root.requestColumnHeaderContextMenu(cellRoot.colKey, cellRoot.colTitle);
                    } else {
                        bridge.trackModel.toggleSort(cellRoot.colKey);
                    }
                }
                onDoubleClicked: bridge.autoSizeColumn(cellRoot.colKey)
            }
        }

        // Table Header Row
        Rectangle {
            Layout.fillWidth: true
            height: 26
            color: Theme.surfaceElevated
            border.color: Theme.panelBorder
            border.width: 1

            MouseArea {
                anchors.fill: parent
                z: -1
                acceptedButtons: Qt.RightButton
                onClicked: {
                    root.requestColumnHeaderContextMenu("", "");
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                TableHeaderCell { colKey: "trackNumber"; colTitle: "Track #"; headerText: "#" }
                Item { Layout.preferredWidth: 16; Layout.fillHeight: true }
                TableHeaderCell { colKey: "title"; colTitle: "Title"; headerText: "TITLE"; isFillWidth: true }
                TableHeaderCell { colKey: "artist"; colTitle: "Artist"; headerText: "ARTIST" }
                TableHeaderCell { colKey: "album"; colTitle: "Album"; headerText: "ALBUM" }
                TableHeaderCell { colKey: "albumArtist"; colTitle: "Album Artist"; headerText: "ALBUM ARTIST" }
                TableHeaderCell { colKey: "genre"; colTitle: "Genre"; headerText: "GENRE" }
                TableHeaderCell { colKey: "year"; colTitle: "Year"; headerText: "YEAR" }
                TableHeaderCell { colKey: "codec"; colTitle: "Format / Codec"; headerText: "FORMAT" }
                TableHeaderCell { colKey: "bitrate"; colTitle: "Bitrate"; headerText: "BITRATE" }
                TableHeaderCell { colKey: "sampleRate"; colTitle: "Sample Rate"; headerText: "SAMPLE RATE" }
                TableHeaderCell { colKey: "bitDepth"; colTitle: "Bit Depth"; headerText: "BIT DEPTH" }
                TableHeaderCell { colKey: "playCount"; colTitle: "Play Count"; headerText: "PLAYS" }
                TableHeaderCell { colKey: "rating"; colTitle: "Rating"; headerText: "RATING" }
                TableHeaderCell { colKey: "dateAdded"; colTitle: "Date Added"; headerText: "DATE ADDED" }
                TableHeaderCell { colKey: "filePath"; colTitle: "File Path"; headerText: "FILE PATH" }
                TableHeaderCell { colKey: "fileSize"; colTitle: "File Size"; headerText: "SIZE" }
                TableHeaderCell { colKey: "duration"; colTitle: "Duration"; headerText: "TIME" }
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

                MouseArea {
                    id: emptyViewportMouse
                    anchors.fill: parent
                    z: -1
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            root.requestViewportContextMenu();
                        } else {
                            bridge.trackModel.clearSelection();
                        }
                    }
                }

                delegate: Rectangle {
                    width: trackTableListView.width
                    height: 25
                    color: model.isSelected ? Theme.selection : ((bridge.currentFilePath === model.filePath) ? Theme.surfaceElevated : (tableRowMouse.containsMouse ? Theme.surfaceElevated : (index % 2 === 0 ? Theme.surface : Theme.background)))

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        // 1. Track Number
                        Item {
                            visible: bridge.isColumnVisible("trackNumber")
                            Layout.preferredWidth: bridge.getColumnWidth("trackNumber")
                            Layout.fillHeight: true
                            clip: true
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.trackNumber > 0 ? model.trackNumber : (index + 1)
                                font.pixelSize: 10
                                color: (bridge.currentFilePath === model.filePath) ? Theme.accent : Theme.textMuted
                            }
                        }

                        // 2. Play/Volume Status Icon
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

                        // 3. Title
                        Item {
                            visible: bridge.isColumnVisible("title")
                            Layout.fillWidth: true
                            Layout.preferredWidth: bridge.getColumnWidth("title")
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

                        // 4. Artist
                        Item {
                            visible: bridge.isColumnVisible("artist")
                            Layout.preferredWidth: bridge.getColumnWidth("artist")
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

                        // 5. Album
                        Item {
                            visible: bridge.isColumnVisible("album")
                            Layout.preferredWidth: bridge.getColumnWidth("album")
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
                                    root.requestExpandAlbum(model.album, model.artist);
                                }
                                ToolTip.visible: albTextMouse.containsMouse
                                ToolTip.text: "Expand " + model.album
                            }
                        }

                        // 6. Album Artist
                        Item {
                            visible: bridge.isColumnVisible("albumArtist")
                            Layout.preferredWidth: bridge.getColumnWidth("albumArtist")
                            Layout.minimumWidth: 70
                            Layout.fillHeight: true
                            clip: true
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                text: model.albumArtist || model.artist
                                font.pixelSize: 11
                                color: Theme.textMuted
                                elide: Text.ElideRight
                            }
                        }

                        // 7. Genre
                        Item {
                            visible: bridge.isColumnVisible("genre")
                            Layout.preferredWidth: bridge.getColumnWidth("genre")
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

                        // 8. Year
                        Item {
                            visible: bridge.isColumnVisible("year")
                            Layout.preferredWidth: bridge.getColumnWidth("year")
                            Layout.minimumWidth: 36
                            Layout.fillHeight: true
                            clip: true
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.year > 0 ? model.year : ""
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }

                        // 9. Format / Codec
                        Item {
                            visible: bridge.isColumnVisible("codec")
                            Layout.preferredWidth: bridge.getColumnWidth("codec")
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

                        // 10. Bitrate
                        Item {
                            visible: bridge.isColumnVisible("bitrate")
                            Layout.preferredWidth: bridge.getColumnWidth("bitrate")
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

                        // 11. Sample Rate
                        Item {
                            visible: bridge.isColumnVisible("sampleRate")
                            Layout.preferredWidth: bridge.getColumnWidth("sampleRate")
                            Layout.minimumWidth: 50
                            Layout.fillHeight: true
                            clip: true
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.sampleRate > 0 ? ((model.sampleRate / 1000) + " kHz") : ""
                                font.pixelSize: 10
                                color: Theme.textMuted
                                elide: Text.ElideRight
                            }
                        }

                        // 12. Bit Depth
                        Item {
                            visible: bridge.isColumnVisible("bitDepth")
                            Layout.preferredWidth: bridge.getColumnWidth("bitDepth")
                            Layout.minimumWidth: 40
                            Layout.fillHeight: true
                            clip: true
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.bitDepth > 0 ? (model.bitDepth + "-bit") : ""
                                font.pixelSize: 10
                                color: Theme.textMuted
                                elide: Text.ElideRight
                            }
                        }

                        // 13. Play Count
                        Item {
                            visible: bridge.isColumnVisible("playCount")
                            Layout.preferredWidth: bridge.getColumnWidth("playCount")
                            Layout.minimumWidth: 36
                            Layout.fillHeight: true
                            clip: true
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.playCount > 0 ? model.playCount : ""
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }

                        // 14. Rating
                        Item {
                            visible: bridge.isColumnVisible("rating")
                            Layout.preferredWidth: bridge.getColumnWidth("rating")
                            Layout.minimumWidth: 50
                            Layout.fillHeight: true
                            clip: true
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.rating > 0 ? ("★".repeat(model.rating) + "☆".repeat(5 - model.rating)) : ""
                                font.pixelSize: 10
                                color: Theme.accent
                            }
                        }

                        // 15. Date Added
                        Item {
                            visible: bridge.isColumnVisible("dateAdded")
                            Layout.preferredWidth: bridge.getColumnWidth("dateAdded")
                            Layout.minimumWidth: 60
                            Layout.fillHeight: true
                            clip: true
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.dateAddedFormatted || ""
                                font.pixelSize: 10
                                color: Theme.textMuted
                                elide: Text.ElideRight
                            }
                        }

                        // 16. File Path
                        Item {
                            visible: bridge.isColumnVisible("filePath")
                            Layout.preferredWidth: bridge.getColumnWidth("filePath")
                            Layout.minimumWidth: 80
                            Layout.fillHeight: true
                            clip: true
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                text: model.filePath || ""
                                font.pixelSize: 10
                                color: Theme.textMuted
                                elide: Text.ElideMiddle
                            }
                        }

                        // 17. File Size
                        Item {
                            visible: bridge.isColumnVisible("fileSize")
                            Layout.preferredWidth: bridge.getColumnWidth("fileSize")
                            Layout.minimumWidth: 40
                            Layout.fillHeight: true
                            clip: true
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.fileSizeFormatted || ""
                                font.pixelSize: 10
                                color: Theme.textMuted
                                elide: Text.ElideRight
                            }
                        }

                        // 18. Duration
                        Item {
                            visible: bridge.isColumnVisible("duration")
                            Layout.preferredWidth: bridge.getColumnWidth("duration")
                            Layout.minimumWidth: 36
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
                                var sel = bridge.trackModel.getSelectedTracks();
                                var trk = { id: model.id, title: model.title, artist: model.artist, filePath: model.filePath, album: model.album, genre: model.genre, year: model.year, trackNumber: model.trackNumber };
                                root.requestTrackContextMenu(sel, trk, model.filePath, model.title, model.artist, root.isPlaylistView, root.activePlaylistName);
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

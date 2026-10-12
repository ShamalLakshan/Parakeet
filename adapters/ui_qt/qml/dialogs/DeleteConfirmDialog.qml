import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Dialog {
    id: root
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
                    text: root.tracksToDelete.length > 1
                        ? ("Delete " + root.tracksToDelete.length + " Files from Disk?")
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
            Layout.preferredHeight: Math.min(120, Math.max(36, root.tracksToDelete.length * 24 + 8))
            color: Theme.surfaceElevated
            border.color: Theme.panelBorder
            border.width: 1
            radius: Theme.cornerRadiusSmall
            clip: true

            ListView {
                anchors.fill: parent
                anchors.margins: 6
                model: root.tracksToDelete
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
                onClicked: root.close()
            }

            Button {
                contentItem: Text {
                    text: "Delete Permanently"
                    color: Theme.textPrimary
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
                    for (var i = 0; i < root.tracksToDelete.length; ++i) {
                        if (root.tracksToDelete[i].id) {
                            ids.push(root.tracksToDelete[i].id);
                        }
                    }
                    root.close();
                    if (ids.length > 0) {
                        bridge.deleteFilesFromDisk(ids);
                    }
                }
            }
        }
    }
}

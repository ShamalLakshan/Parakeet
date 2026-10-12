import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Dialog {
    id: root
    title: "Rename Playlist"
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    width: 380
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property string oldName: ""

    signal playlistRenamed(string oldName, string newName)

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
                onClicked: root.close()
            }

            Button {
                text: "Rename"
                enabled: renameInput.text.trim().length > 0 && renameInput.text.trim() !== root.oldName
                onClicked: {
                    var newName = renameInput.text.trim();
                    bridge.renamePlaylist(root.oldName, newName);
                    root.playlistRenamed(root.oldName, newName);
                    root.close();
                }
            }
        }
    }

    onAboutToShow: {
        renameInput.text = oldName;
        renameInput.forceActiveFocus();
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."
import "../components"

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            color: Theme.surface
            border.color: Theme.panelBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.panelPadding
                anchors.rightMargin: Theme.panelPadding
                spacing: Theme.spacingMedium

                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "UPCOMING QUEUE"
                        font.pixelSize: Theme.fontSizeSmall - 1
                        font.bold: true
                        font.letterSpacing: 1.0
                        color: Theme.textMuted
                    }
                    Text {
                        text: bridge.queueRemainingCount + " tracks • " + bridge.queueRemainingDurationStr
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        color: Theme.accent
                    }
                }

                Item { Layout.fillWidth: true }

                // Shuffle button
                Rectangle {
                    width: 24
                    height: 24
                    radius: Theme.cornerRadiusSmall
                    color: shufBtnMouse.containsMouse ? Theme.selection : "transparent"
                    border.color: Theme.panelBorder
                    VectorIcon {
                        anchors.centerIn: parent
                        name: "shuffle"
                        width: 11
                        height: 11
                        color: Theme.textSecondary
                    }
                    MouseArea {
                        id: shufBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bridge.shuffleRemainingQueue()
                    }
                    ToolTip.visible: shufBtnMouse.containsMouse
                    ToolTip.text: "Shuffle Remaining Tracks"
                }

                // Clear button
                Rectangle {
                    width: 24
                    height: 24
                    radius: Theme.cornerRadiusSmall
                    color: clearBtnMouse.containsMouse ? Theme.selection : "transparent"
                    border.color: Theme.panelBorder
                    VectorIcon {
                        anchors.centerIn: parent
                        name: "trash"
                        width: 11
                        height: 11
                        color: Theme.textSecondary
                    }
                    MouseArea {
                        id: clearBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bridge.clearQueue()
                    }
                    ToolTip.visible: clearBtnMouse.containsMouse
                    ToolTip.text: "Clear Upcoming Queue"
                }
            }
        }

        // Empty state
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            visible: bridge.queueRemainingCount === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.spacingMedium

                VectorIcon {
                    Layout.alignment: Qt.AlignHCenter
                    name: "queue"
                    width: 32
                    height: 32
                    color: Theme.textMuted
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Queue is empty"
                    font.pixelSize: Theme.fontSizeBase
                    font.bold: true
                    color: Theme.textMuted
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Play a track or right-click to add songs"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.textMuted
                }
            }
        }

        // Queue list
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: bridge.queueRemainingCount > 0
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            ListView {
                id: queueListView
                anchors.fill: parent
                model: bridge.queueTrackModel
                clip: true

                delegate: Rectangle {
                    id: queueItemDelegate
                    width: queueListView.width
                    height: 36
                    color: qRowMouse.containsMouse ? Theme.surfaceElevated : "transparent"
                    border.color: qRowMouse.containsMouse ? Theme.panelBorder : "transparent"
                    border.width: 1

                    property bool isUpNextItem: index < bridge.upNextCount

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        // Track number
                        Rectangle {
                            Layout.preferredWidth: queueItemDelegate.isUpNextItem ? 20 : 16
                            Layout.preferredHeight: 16
                            radius: 2
                            color: queueItemDelegate.isUpNextItem ? Theme.selection : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: queueItemDelegate.isUpNextItem ? "★" : (index + 1)
                                font.pixelSize: Theme.fontSizeSmall - 1
                                font.bold: queueItemDelegate.isUpNextItem
                                color: queueItemDelegate.isUpNextItem ? Theme.accent : Theme.textMuted
                            }
                        }

                        // Track info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: model.title
                                font.pixelSize: Theme.fontSizeSmall + 1
                                font.bold: true
                                color: Theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                spacing: 4
                                Layout.fillWidth: true
                                clip: true

                                Text {
                                    text: model.artist
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    color: Theme.textMuted
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: model.codec
                                    font.pixelSize: Theme.fontSizeSmall - 2
                                    font.weight: Font.Medium
                                    color: Theme.textMuted
                                }
                            }
                        }

                        // Duration
                        Text {
                            text: model.durationFormatted
                            font.pixelSize: Theme.fontSizeSmall - 1
                            color: Theme.textMuted
                        }

                        // Reorder buttons (Move Up / Down)
                        RowLayout {
                            spacing: 1
                            visible: qRowMouse.containsMouse

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 2
                                color: upMouse.containsMouse ? Theme.accent : "transparent"
                                visible: index > 0
                                VectorIcon { anchors.centerIn: parent; name: "arrow_up"; width: 8; height: 8; color: Theme.textPrimary }
                                MouseArea {
                                    id: upMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: bridge.moveQueueItem(index, index - 1)
                                }
                            }

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 2
                                color: dnMouse.containsMouse ? Theme.accent : "transparent"
                                visible: index < bridge.queueRemainingCount - 1
                                VectorIcon { anchors.centerIn: parent; name: "arrow_down"; width: 8; height: 8; color: Theme.textPrimary }
                                MouseArea {
                                    id: dnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: bridge.moveQueueItem(index, index + 1)
                                }
                            }

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 2
                                color: rmMouse.containsMouse ? Theme.error : "transparent"
                                VectorIcon { anchors.centerIn: parent; name: "close"; width: 8; height: 8; color: Theme.textPrimary }
                                MouseArea {
                                    id: rmMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: bridge.removeFromQueue(index)
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: qRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onDoubleClicked: bridge.playQueueTrack(index)
                    }
                }
            }
        }
    }
}

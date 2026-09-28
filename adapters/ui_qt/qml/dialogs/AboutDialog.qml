import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Dialog {
    id: root
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    width: 480
    height: 400
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    background: Rectangle {
        color: Theme.surface
        border.color: Theme.panelBorder
        border.width: 1
        radius: Theme.cornerRadiusMedium
    }

    contentItem: ColumnLayout {
        spacing: 0
        clip: true

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: Theme.surfaceElevated
            border.color: Theme.panelBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.panelPadding
                anchors.rightMargin: Theme.panelPadding
                spacing: Theme.spacingMedium

                VectorIcon {
                    name: "music"
                    width: 14
                    height: 14
                    color: Theme.accent
                }

                Text {
                    text: "About Parakeet"
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                    color: Theme.textPrimary
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: 24
                    height: 24
                    radius: Theme.cornerRadiusSmall
                    color: closeMouse.containsMouse ? Theme.selection : "transparent"

                    VectorIcon {
                        anchors.centerIn: parent
                        name: "clear"
                        width: 10
                        height: 10
                        color: closeMouse.containsMouse ? Theme.textPrimary : Theme.textMuted
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }
        }

        // Body Content
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: Theme.panelPadding
            spacing: Theme.spacingMedium

            // App branding block
            RowLayout {
                spacing: Theme.spacingLarge
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    width: 64
                    height: 64
                    radius: Theme.cornerRadiusMedium
                    color: Theme.surfaceElevated
                    border.color: Theme.panelBorder
                    border.width: 1

                    VectorIcon {
                        anchors.centerIn: parent
                        name: "music"
                        width: 32
                        height: 32
                        color: Theme.accent
                    }
                }

                ColumnLayout {
                    spacing: 2

                    Text {
                        text: "PARAKEET"
                        font.pixelSize: 18
                        font.bold: true
                        font.letterSpacing: 2.0
                        color: Theme.textPrimary
                    }

                    Text {
                        text: "Version 1.0.0-alpha"
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        color: Theme.accentHover
                    }

                    Text {
                        text: "Lightweight High-Fidelity Music Player"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textMuted
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.panelBorder
            }

            // Specs table
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.spacingSmall

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Architecture:"; font.pixelSize: Theme.fontSizeSmall; color: Theme.textSecondary; Layout.preferredWidth: 120 }
                    Text { text: "Hexagonal Ports & Adapters (C++20 / Qt 6)"; font.pixelSize: Theme.fontSizeSmall; font.bold: true; color: Theme.textPrimary; Layout.fillWidth: true; elide: Text.ElideRight }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Audio Engine:"; font.pixelSize: Theme.fontSizeSmall; color: Theme.textSecondary; Layout.preferredWidth: 120 }
                    Text { text: "Bit-Perfect Low-Latency Pipeline"; font.pixelSize: Theme.fontSizeSmall; font.bold: true; color: Theme.textPrimary; Layout.fillWidth: true; elide: Text.ElideRight }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "License:"; font.pixelSize: Theme.fontSizeSmall; color: Theme.textSecondary; Layout.preferredWidth: 120 }
                    Text { text: "MIT License (Open Source)"; font.pixelSize: Theme.fontSizeSmall; font.bold: true; color: Theme.textPrimary; Layout.fillWidth: true; elide: Text.ElideRight }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Repository:"; font.pixelSize: Theme.fontSizeSmall; color: Theme.textSecondary; Layout.preferredWidth: 120 }
                    Text {
                        text: "github.com/ShamalLakshan/Parakeet"
                        font.pixelSize: Theme.fontSizeSmall
                        font.underline: repoMouse.containsMouse
                        color: Theme.accent
                        Layout.fillWidth: true
                        elide: Text.ElideRight

                        MouseArea {
                            id: repoMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally("https://github.com/ShamalLakshan/Parakeet")
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }

        // Footer
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: Theme.surfaceElevated
            border.color: Theme.panelBorder
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.panelPadding
                anchors.rightMargin: Theme.panelPadding

                Item { Layout.fillWidth: true }

                Button {
                    text: "Close"
                    implicitHeight: 28
                    implicitWidth: 80
                    onClicked: root.close()
                    contentItem: Text {
                        text: parent.text
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.fontFamily
                        color: Theme.textPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered ? Theme.surfaceElevated : Theme.background
                        border.color: Theme.panelBorder
                        border.width: 1
                        radius: Theme.cornerRadiusSmall
                    }
                }
            }
        }
    }
}

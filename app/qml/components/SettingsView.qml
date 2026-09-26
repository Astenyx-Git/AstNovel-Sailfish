import QtQuick 2.15
import Sailfish.Silica 1.0

Page {
    id: settingsPage

    // Background color
    background: Rectangle {
        color: Theme.themeBackground
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Settings")
            }

            SectionHeader {
                text: qsTr("Appearance")
            }

            // Dark mode
            Switch {
                id: darkModeSwitch
                width: parent.width
                text: qsTr("Dark Mode")
                checked: Theme.isDarkMode
                onClicked: Theme.toggleDarkMode()
            }

            SectionHeader {
                text: qsTr("About")
            }

            Label {
                width: parent.width
                color: Theme.themeTextSecondary
                font.pixelSize: Theme.typography.captionSize
                text: qsTr("NovelSpace")
            }
            Label {
                width: parent.width
                color: Theme.themeTextSecondary
                font.pixelSize: Theme.typography.captionSize
                text: qsTr("Version 1.0.0")
            }
        }
    }
}

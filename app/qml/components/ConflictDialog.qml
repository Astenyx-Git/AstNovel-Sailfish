import QtQuick 2.15
import Sailfish.Silica 1.0

Dialog {
    id: conflictDialog

    property string title: qsTr("Conflict")
    property string message: ""

    // Background with blur
    background: Rectangle {
        color: Theme.themeSurface
        radius: Theme.cornerRadiusCard
    }

    Column {
        width: parent.width
        spacing: Theme.paddingMedium

        Label {
            width: parent.width
            color: Theme.themePrimary
            font.pixelSize: Theme.typography.title3Size
            font.bold: true
            text: conflictDialog.title
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            width: parent.width
            color: Theme.themeTextPrimary
            font.pixelSize: Theme.typography.bodySize
            text: conflictDialog.message
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Button {
        text: qsTr("OK")
        color: Theme.themePrimary
        onClicked: accept()
    }
}

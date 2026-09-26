import QtQuick 2.15
import Sailfish.Silica 1.0

Dialog {
    id: modalDialog

    property string title: ""
    property string content: ""
    property string confirmText: qsTr("OK")
    property string cancelText: qsTr("Cancel")

    // Background with blur effect
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
            text: modalDialog.title
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            width: parent.width
            color: Theme.themeTextPrimary
            font.pixelSize: Theme.typography.bodySize
            text: modalDialog.content
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Button {
        text: modalDialog.cancelText
        color: Theme.themeTextSecondary
        onClicked: modalDialog.reject()
    }

    Button {
        text: modalDialog.confirmText
        color: Theme.themePrimary
        onClicked: modalDialog.accept()
    }
}

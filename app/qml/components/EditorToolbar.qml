import QtQuick 2.15
import Sailfish.Silica 1.0

Item {
    id: editorToolbar

    width: parent.width
    height: 120

    Button {
        id: backBtn
        width: Theme.itemSizeSmall
        height: Theme.itemSizeSmall
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: Theme.paddingSmall
        }
        icon.source: "image://theme/icon-m-back"
        onClicked: onBack()
    }

    Button {
        id: saveBtn
        width: Theme.itemSizeSmall
        height: Theme.itemSizeSmall
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            rightMargin: Theme.paddingSmall
        }
        icon.source: "image://theme/icon-m-copy"
        onClicked: onSave()
    }

    Button {
        id: deleteBtn
        width: Theme.itemSizeSmall
        height: Theme.itemSizeSmall
        anchors {
            right: saveBtn.left
            top: parent.top
            bottom: parent.bottom
            rightMargin: Theme.paddingSmall
        }
        icon.source: "image://theme/icon-m-delete"
        color: Theme.themeDanger
        onClicked: onDelete()
    }

    Button {
        id: newChapterBtn
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        text: qsTr("New Chapter")
        color: Theme.themePrimary
        onClicked: onCreateChapter()
    }

    signal onBack()
    signal onSave()
    signal onDelete()
    signal onCreateChapter()
}

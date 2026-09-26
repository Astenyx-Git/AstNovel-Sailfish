import QtQuick 2.15
import Sailfish.Silica 1.0
import harbour.astn 1.0

Page {
    id: characterDetailPage

    property string bookId: ""
    property string characterId: ""

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Character Details")
            }

            CharacterCard {
                width: parent.width
                characterId: characterId
                name: characterManager.getCharacter(bookId, characterId).name
                description: characterManager.getCharacter(bookId, characterId).description
                createdAt: characterManager.getCharacter(bookId, characterId).createdAt
            }

            Button {
                width: parent.width
                text: qsTr("Edit Character")
                onClicked: pageStack.push(Qt.resolvedUrl("components/EditCharacterDialog.qml"), {
                                               "bookId": bookId,
                                               "characterId": characterId
                                           })
            }

            Button {
                width: parent.width
                text: qsTr("Delete Character")
                color: Theme.errorColor
                onClicked: {
                    confirmDeleteCharacter();
                }
            }
        }
    }

    // Delete confirmation dialog
    Dialog {
        id: deleteDialog
        title: qsTr("Delete Character")
        Button {
            text: qsTr("Cancel")
            onClicked: deleteDialog.reject()
        }
        Button {
            text: qsTr("Delete")
            color: Theme.errorColor
            onClicked: {
                characterManager.deleteCharacter(bookId, characterId);
                pageStack.pop();
                deleteDialog.accept();
            }
        }
    }

    function confirmDeleteCharacter() {
        deleteDialog.open();
    }
}

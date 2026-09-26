import QtQuick 2.15
import Sailfish.Silica 1.0
import harbour.astn 1.0

Page {
    id: characterListPage

    property string bookId: ""

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
                title: qsTr("Characters")
            }

            Repeater {
                model: characterManager.getCharacters(bookId)

                CharacterCard {
                    characterId: modelData.id
                    name: modelData.name
                    description: modelData.description
                    createdAt: modelData.createdAt

                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("components/CharacterDetailView.qml"), {
                                            "bookId": bookId,
                                            "characterId": characterId
                                        })
                    }
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Add Character")
                color: Theme.themePrimary
                onClicked: pageStack.push(Qt.resolvedUrl("components/EditCharacterDialog.qml"), {
                                               "bookId": bookId
                                           })
            }
        }
    }

    // Handle back button
    onBackPressed: {
        pageStack.pop();
    }
}

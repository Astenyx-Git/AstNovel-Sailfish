import QtQuick 2.15
import Sailfish.Silica 1.0
import harbour.astn 1.0

Dialog {
    id: editCharacterDialog

    property string bookId: ""
    property string characterId: ""
    property string name: ""
    property string description: ""

    // Background with blur
    background: Rectangle {
        color: Theme.themeSurface
        radius: Theme.cornerRadiusCard
    }

    Column {
        width: parent.width
        spacing: Theme.paddingMedium

        TextField {
            id: nameField
            width: parent.width
            label: qsTr("Name")
            placeholderText: qsTr("Enter character name")
            text: name
            EnterKey.enabled: true
            EnterKey.iconSource: "image://theme/icon-m-enter"
            EnterKey.onClicked: {
                focus = false;
                onAccepted();
            }
        }

        TextArea {
            id: descriptionField
            width: parent.width
            label: qsTr("Description")
            placeholderText: qsTr("Enter character description")
            text: description
            height: 200
        }
    }

    Button {
        text: qsTr("Save Character")
        color: Theme.themePrimary
        onClicked: {
            var newCharacterId = "";
            if (characterId !== "") {
                // Update existing character
                characterManager.updateCharacter(bookId, characterId, nameField.text, descriptionField.text);
            } else {
                // Create new character
                characterManager.createCharacter(bookId, nameField.text, descriptionField.text, newCharacterId);
            }
            accept();
        }
    }
}

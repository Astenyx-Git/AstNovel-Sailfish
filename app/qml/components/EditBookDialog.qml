import QtQuick 2.15
import Sailfish.Silica 1.0
import harbour.astn 1.0

Dialog {
    id: editBookDialog

    property string bookId: ""
    property string title: ""
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
            id: titleField
            width: parent.width
            label: qsTr("Title")
            placeholderText: qsTr("Enter book title")
            text: title
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
            placeholderText: qsTr("Enter book description")
            text: description
            height: 200
        }
    }

    Button {
        text: qsTr("Create Book")
        color: Theme.themePrimary
        onClicked: {
            var newBookId = "";
            if (bookId !== "") {
                // Update existing book
                bookManager.updateBook(bookId, titleField.text, descriptionField.text);
            } else {
                // Create new book
                bookManager.createBook(titleField.text, descriptionField.text, newBookId);
            }
            accept();
        }
    }
}

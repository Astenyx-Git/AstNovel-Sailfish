import QtQuick 2.15
import Sailfish.Silica 1.0
import harbour.astn 1.0

Dialog {
    id: editWorldSettingDialog

    property string bookId: ""
    property string category: ""
    property string entryId: ""
    property string title: ""
    property string content: ""

    // Background with blur
    background: Rectangle {
        color: Theme.themeSurface
        radius: Theme.cornerRadiusCard
    }

    Column {
        width: parent.width
        spacing: Theme.paddingMedium

        ComboBox {
            id: categoryField
            width: parent.width
            label: qsTr("Category")
            currentIndex: -1

            model: ["characters", "locations", "items", "other"]
            delegate: MenuItem {
                text: modelData
            }
        }

        TextField {
            id: titleField
            width: parent.width
            label: qsTr("Title")
            placeholderText: qsTr("Enter title (optional)")
            text: title
        }

        TextArea {
            id: contentField
            width: parent.width
            label: qsTr("Content")
            placeholderText: qsTr("Enter content...")
            text: content
            height: 200
        }
    }

    onOpened: {
        if (category !== "") {
            categoryField.currentIndex = categoryField.find(category);
        }
    }

    Button {
        text: qsTr("Save Entry")
        color: Theme.themePrimary
        onClicked: {
            var newEntryId = "";
            if (entryId !== "") {
                // Update existing entry
                worldSettingManager.updateEntry(bookId, categoryField.currentText, entryId, titleField.text, contentField.text);
            } else {
                // Create new entry
                worldSettingManager.createEntry(bookId, categoryField.currentText, titleField.text, contentField.text, newEntryId);
            }
            accept();
        }
    }
}

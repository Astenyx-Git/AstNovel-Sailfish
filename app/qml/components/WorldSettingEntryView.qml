import QtQuick 2.15
import Sailfish.Silica 1.0
import harbour.astn 1.0

Page {
    id: worldSettingEntryPage

    property string bookId: ""
    property string category: ""
    property string entryId: ""

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("World Setting Entry")
            }

            Label {
                width: parent.width
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Category")
            }
            Label {
                width: parent.width
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                text: category
            }

            TextArea {
                id: entryContent
                width: parent.width
                height: parent.height - column.height - Theme.paddingLarge
                font.pixelSize: 17
                wrapMode: TextArea.Wrap
                placeholderText: qsTr("Enter content...")
                text: getEntryContent()
            }

            ButtonRow {
                width: parent.width
                spacing: Theme.paddingSmall

                Button {
                    text: qsTr("Save")
                    onClicked: saveEntry()
                }

                Button {
                    text: qsTr("Delete")
                    color: Theme.errorColor
                    onClicked: deleteEntry()
                }
            }
        }
    }

    function loadEntry() {
        if (entryId !== "") {
            entryContent.text = worldSettingManager.getEntry(bookId, category, entryId).content;
        } else {
            entryContent.text = "";
        }
    }

    function saveEntry() {
        var entryId = "";
        if (entryId !== "") {
            worldSettingManager.updateEntry(bookId, category, entryId, entryContent.text);
        } else {
            worldSettingManager.createEntry(bookId, category, "", entryContent.text, entryId);
        }
        Toast.show(qsTr("Entry saved"));
        pageStack.pop();
    }

    function deleteEntry() {
        worldSettingManager.deleteEntry(bookId, category, entryId);
        Toast.show(qsTr("Entry deleted"));
        pageStack.pop();
    }

    function getEntryContent() {
        if (entryId !== "") {
            return worldSettingManager.getEntry(bookId, category, entryId).content;
        }
        return "";
    }
}

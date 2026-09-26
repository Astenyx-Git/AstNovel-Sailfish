import QtQuick 2.15
import Sailfish.Silica 1.0
import harbour.astn 1.0

Page {
    id: exportPage

    property string bookId: ""

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Export Book")
            }

            Label {
                width: parent.width
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Export format")
            }

            OptionSelector {
                id: formatSelector
                width: parent.width
                options: ["ASTN", "TXT", "Markdown"]
                currentIndex: 0
            }

            Button {
                width: parent.width
                text: qsTr("Export")
                onClicked: exportBook()
            }

            Label {
                width: parent.width
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("Note: ASTN export requires C++ backend implementation")
            }
        }
    }

    function exportBook() {
        var book = bookManager.getBook(bookId);
        if (book.isEmpty()) {
            Toast.show(qsTr("Book not found"));
            return;
        }

        // TODO: Implement actual export logic
        Toast.show(qsTr("Export feature coming soon"));
    }
}

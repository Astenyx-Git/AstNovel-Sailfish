import QtQuick 2.15
import Sailfish.Silica 1.0
import harbour.astn 1.0

Page {
    id: rootPage

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
                title: "NovelSpace"
                // Add back button if needed
                menu: MenuItem {
                    text: qsTr("Settings")
                    onClicked: pageStack.push(Qt.resolvedUrl("components/SettingsView.qml"))
                }
            }

            Repeater {
                model: bookManager.getAllBooks()

                BookCard {
                    bookId: modelData.id
                    title: modelData.title
                    description: modelData.description
                    coverDataUri: modelData.coverDataUri
                    createdAt: modelData.createdAt
                    updatedAt: modelData.updatedAt

                    onClicked: pageStack.push(Qt.resolvedUrl("components/BookDetailView.qml"), {
                                                "bookId": modelData.id
                                            })
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Create New Book")
                color: Theme.themePrimary
                onClicked: pageStack.push(Qt.resolvedUrl("components/EditBookDialog.qml"))
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Import ASTN")
                color: Theme.themePrimary
                onClicked: pageStack.push(Qt.resolvedUrl("components/AstnImportView.qml"))
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.themeTextSecondary
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("%1 books loaded").arg(bookManager.getAllBooks().length)
            }
        }
    }

    // Handle back button
    onBackPressed: {
        if (pageStack.depth > 1) {
            pageStack.pop();
        } else {
            nativeUtils.closeApplication();
        }
    }
}

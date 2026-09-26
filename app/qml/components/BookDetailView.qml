import QtQuick 2.15
import Sailfish.Silica 1.0
import harbour.astn 1.0

Page {
    id: bookDetailPage

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
                title: qsTr("Book Details")
                visible: bookManager.bookExists(bookId)
            }

            // Book info
            Column {
                width: parent.width
                spacing: Theme.paddingMedium

                // Title
                Label {
                    width: parent.width
                    color: Theme.themeTextSecondary
                    font.pixelSize: Theme.typography.captionSize
                    text: qsTr("Title")
                }
                Label {
                    width: parent.width
                    color: Theme.themeTextPrimary
                    font.pixelSize: Theme.typography.title2Size
                    font.bold: true
                    text: bookManager.getBook(bookId).title
                }

                // Description
                Label {
                    width: parent.width
                    color: Theme.themeTextSecondary
                    font.pixelSize: Theme.typography.captionSize
                    text: qsTr("Description")
                }
                Label {
                    width: parent.width
                    color: Theme.themeTextPrimary
                    font.pixelSize: Theme.typography.bodySize
                    text: bookManager.getBook(bookId).description
                    wrapMode: Text.WordWrap
                }

                // Last updated
                Label {
                    width: parent.width
                    color: Theme.themeTextSecondary
                    font.pixelSize: Theme.typography.captionSize
                    text: qsTr("Last updated")
                }
                Label {
                    width: parent.width
                    color: Theme.themeTextSecondary
                    font.pixelSize: Theme.typography.bodySize
                    text: DesignSystem.formatDetailedTime(bookManager.getBook(bookId).updatedAt)
                }

                // Actions
                ButtonRow {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    Button {
                        text: qsTr("Edit Book")
                        color: Theme.themePrimary
                        onClicked: pageStack.push(Qt.resolvedUrl("components/EditBookDialog.qml"), {
                                                    "bookId": bookId
                                                })
                    }

                    Button {
                        text: qsTr("Chapters")
                        color: Theme.themePrimary
                        onClicked: pageStack.push(Qt.resolvedUrl("components/ChapterEditorView.qml"), {
                                                      "bookId": bookId,
                                                      "chapterId": ""
                                                  })
                    }

                    Button {
                        text: qsTr("Characters")
                        color: Theme.themePrimary
                        onClicked: pageStack.push(Qt.resolvedUrl("components/CharacterListView.qml"), {
                                                      "bookId": bookId
                                                  })
                    }

                    Button {
                        text: qsTr("World Settings")
                        color: Theme.themePrimary
                        onClicked: pageStack.push(Qt.resolvedUrl("components/WorldSettingListView.qml"), {
                                                       "bookId": bookId
                                                   })
                    }
                }

                Button {
                    width: parent.width
                    text: qsTr("Export ASTN")
                    color: Theme.themePrimary
                    onClicked: pageStack.push(Qt.resolvedUrl("components/ExportView.qml"), {
                                                  "bookId": bookId
                                              })
                }

                Button {
                    width: parent.width
                    text: qsTr("Delete Book")
                    color: Theme.themeDanger
                    onClicked: {
                        confirmDeleteBook();
                    }
                }
            }
        }
    }

    // Delete confirmation dialog
    Dialog {
        id: deleteDialog
        title: qsTr("Delete Book")
        Button {
            text: qsTr("Cancel")
            onClicked: deleteDialog.reject()
        }
        Button {
            text: qsTr("Delete")
            color: Theme.themeDanger
            onClicked: {
                bookManager.deleteBook(bookId);
                pageStack.pop();
                deleteDialog.accept();
            }
        }
    }

    function confirmDeleteBook() {
        deleteDialog.open();
    }
}

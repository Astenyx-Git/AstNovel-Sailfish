import QtQuick 2.15
import Sailfish.Silica 1.0
import harbour.astn 1.0

Page {
    id: worldSettingListPage

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
                title: qsTr("World Settings")
            }

            Repeater {
                model: worldSettingManager.getEntries(bookId, "characters")
                WorldSettingCard {
                    width: parent.width
                    category: "characters"
                    entryId: modelData.id
                    title: modelData.title
                    contentPreview: modelData.content
                    createdAt: modelData.createdAt

                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("components/WorldSettingEntryView.qml"), {
                                               "bookId": bookId,
                                               "category": "characters",
                                               "entryId": entryId
                                           })
                    }
                }
            }

            Repeater {
                model: worldSettingManager.getEntries(bookId, "locations")
                WorldSettingCard {
                    width: parent.width
                    category: "locations"
                    entryId: modelData.id
                    title: modelData.title
                    contentPreview: modelData.content
                    createdAt: modelData.createdAt

                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("components/WorldSettingEntryView.qml"), {
                                               "bookId": bookId,
                                               "category": "locations",
                                               "entryId": entryId
                                           })
                    }
                }
            }

            Repeater {
                model: worldSettingManager.getEntries(bookId, "items")
                WorldSettingCard {
                    width: parent.width
                    category: "items"
                    entryId: modelData.id
                    title: modelData.title
                    contentPreview: modelData.content
                    createdAt: modelData.createdAt

                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("components/WorldSettingEntryView.qml"), {
                                               "bookId": bookId,
                                               "category": "items",
                                               "entryId": entryId
                                           })
                    }
                }
            }

            Repeater {
                model: worldSettingManager.getEntries(bookId, "other")
                WorldSettingCard {
                    width: parent.width
                    category: "other"
                    entryId: modelData.id
                    title: modelData.title
                    contentPreview: modelData.content
                    createdAt: modelData.createdAt

                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("components/WorldSettingEntryView.qml"), {
                                               "bookId": bookId,
                                               "category": "other",
                                               "entryId": entryId
                                           })
                    }
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Add Entry")
                color: Theme.themePrimary
                onClicked: pageStack.push(Qt.resolvedUrl("components/EditWorldSettingDialog.qml"), {
                                               "bookId": bookId,
                                               "category": ""
                                           })
            }
        }
    }

    // Handle back button
    onBackPressed: {
        pageStack.pop();
    }
}

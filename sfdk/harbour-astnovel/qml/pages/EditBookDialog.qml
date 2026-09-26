// EditBookDialog.qml — create or edit a book, custom header
import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import "../styles"
import "../components"

Dialog {
    id: dialog

    property string bookId: ""
    property string initialTitle: ""
    property string initialDescription: ""
    property string initialCover: ""
    property string coverUri: initialCover

    canAccept: titleField.text.length > 0

    onAccepted: {
        if (bookId !== "") {
            store.updateBook(bookId, titleField.text, descriptionArea.text)
        } else {
            store.createBook(titleField.text, descriptionArea.text)
        }
    }

    // Dialog background (app palette — ambience-independent readability)
    Rectangle {
        anchors.fill: parent
        color: AstnStyle.cBackground
        z: -1
    }

    // Image picker for the cover (deferred Component — Pages must not be
    // instantiated as direct children of a Dialog)
    Component {
        id: coverPickerComp
        ImagePickerPage {
            onSelectedContentChanged: {
                if (dialog.bookId !== "" && selectedContent.toString() !== ""
                        && store.setBookCoverFromImage(dialog.bookId, selectedContent))
                    dialog.coverUri = store.book(dialog.bookId).coverDataUri
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            // Custom header: cancel / title / save
            Item {
                width: parent.width
                height: 56

                TextButton {
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("取消")
                    textColor: AstnStyle.cTextSecondary
                    onClicked: dialog.reject()
                }

                Label {
                    anchors.centerIn: parent
                    text: bookId !== "" ? qsTr("编辑书籍") : qsTr("新建书籍")
                    color: AstnStyle.cTextPrimary
                    font.pixelSize: AstnStyle.typeHeadline
                    font.weight: Font.Bold
                }

                TextButton {
                    anchors {
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("保存")
                    enabled: titleField.text.length > 0
                    opacity: enabled ? 1.0 : 0.4
                    onClicked: dialog.accept()
                }
            }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                Label {
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                    }
                    text: qsTr("封面")
                    color: AstnStyle.cTextSecondary
                    font.pixelSize: AstnStyle.typeCaption
                }

                // Cover preview (custom image or gradient + first char)
                Rectangle {
                    id: coverPreview
                    width: 180
                    height: 100
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: AstnStyle.radiusButton
                    clip: true
                    color: coverUri !== "" ? AstnStyle.cSurface : "transparent"

                    Image {
                        anchors.fill: parent
                        visible: coverUri !== ""
                        source: coverUri
                        fillMode: Image.PreserveAspectCrop
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: coverUri === ""
                        radius: AstnStyle.radiusButton
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#FF6B6B" }
                            GradientStop { position: 1.0; color: "#EE5A24" }
                        }

                        Label {
                            anchors.centerIn: parent
                            visible: coverUri === ""
                            text: AstnStyle.firstChar(titleField.text)
                            color: "#FFFFFF"
                            font.pixelSize: 36
                            font.weight: Font.Bold
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.paddingLarge

                    TextButton {
                        text: qsTr("设置封面")
                        enabled: dialog.bookId !== ""
                        opacity: enabled ? 1.0 : 0.4
                        onClicked: pageStack.push(coverPickerComp)
                    }

                    TextButton {
                        text: qsTr("清除封面")
                        textColor: AstnStyle.cTextSecondary
                        enabled: dialog.bookId !== "" && dialog.coverUri !== ""
                        opacity: enabled ? 1.0 : 0.4
                        onClicked: {
                            if (store.clearBookCover(dialog.bookId))
                                dialog.coverUri = ""
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                Label {
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                    }
                    text: qsTr("书名")
                    color: AstnStyle.cTextSecondary
                    font.pixelSize: AstnStyle.typeCaption
                }
                TextField {
                    id: titleField
                    width: parent.width
                    text: dialog.initialTitle
                    color: AstnStyle.cTextPrimary
                    placeholderText: qsTr("输入书名")
                    label: qsTr("书名")
                }
            }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                Label {
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                    }
                    text: qsTr("简介")
                    color: AstnStyle.cTextSecondary
                    font.pixelSize: AstnStyle.typeCaption
                }
                TextArea {
                    id: descriptionArea
                    width: parent.width
                    height: 200
                    text: dialog.initialDescription
                    color: AstnStyle.cTextPrimary
                    placeholderText: qsTr("输入简介（可选）")
                    label: qsTr("简介")
                }
            }
        }
    }
}

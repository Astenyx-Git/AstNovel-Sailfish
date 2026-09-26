// BookDetailPage.qml — book info and navigation, app palette only
import QtQuick 2.2
import Sailfish.Silica 1.0
import "../styles"
import "../components"

Page {
    id: detailPage

    allowedOrientations: Orientation.All
    property string bookId: ""

    property var bookInfo: ({})

    function refresh() {
        bookInfo = store.book(bookId)
    }

    onStatusChanged: {
        if (status === PageStatus.Activating)
            refresh()
    }

    // Delete confirmation (original requires confirm before delete)
    Component {
        id: deleteConfirmDialog
        Dialog {
            canAccept: true

            Rectangle {
                anchors.fill: parent
                color: AstnStyle.cBackground
                z: -1
            }

            onAccepted: {
                store.deleteBook(detailPage.bookId)
                pageStack.pop(null)   // unwind back to the shelf
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: confirmCol.height

                Column {
                    id: confirmCol
                    width: parent.width
                    spacing: Theme.paddingLarge

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
                            onClicked: pageStack.currentPage.reject()
                        }

                        Label {
                            anchors.centerIn: parent
                            text: qsTr("删除书籍")
                            color: AstnStyle.cTextPrimary
                            font.pixelSize: AstnStyle.typeHeadline
                            font.weight: Font.Bold
                        }
                    }

                    Label {
                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: Theme.horizontalPageMargin
                        }
                        text: qsTr("确定要删除《%1》吗？书籍的全部章节、角色与世界观设定将被移除，此操作不可撤销。")
                              .arg(bookInfo.title ? bookInfo.title : "")
                        color: AstnStyle.cTextPrimary
                        font.pixelSize: AstnStyle.typeBody
                        wrapMode: Text.WordWrap
                    }

                    AppleButton {
                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: Theme.horizontalPageMargin
                        }
                        variant: "danger"
                        text: qsTr("确认删除")
                        onClicked: pageStack.currentPage.accept()
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: AstnStyle.cBackground
        z: -1
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge * 2

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            // Header row: back + title
            Item {
                width: parent.width
                height: 64

                TextButton {
                    id: backBtn
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("‹ 书架")
                    onClicked: pageStack.pop()
                }

                Label {
                    anchors.centerIn: parent
                    text: bookInfo.title ? bookInfo.title : ""
                    color: AstnStyle.cTextPrimary
                    font.pixelSize: AstnStyle.typeTitle
                    font.weight: Font.Bold
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    // keep clear of the back button
                    width: parent.width - 2 * (backBtn.width + Theme.paddingLarge)
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Cover preview (gradient by title hash)
            AstnCard {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                showCover: true
                title: bookInfo.title ? bookInfo.title : ""
                meta: (bookInfo.chapterCount ? bookInfo.chapterCount : 0) + "章"
            }

            // Description
            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                Label {
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: Theme.horizontalPageMargin
                        rightMargin: Theme.horizontalPageMargin
                    }
                    text: bookInfo.description && bookInfo.description.length > 0
                          ? bookInfo.description : qsTr("暂无简介")
                    color: AstnStyle.cTextSecondary
                    font.pixelSize: AstnStyle.typeBody
                    wrapMode: Text.WordWrap
                }

                Label {
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: Theme.horizontalPageMargin
                        rightMargin: Theme.horizontalPageMargin
                    }
                    text: bookInfo.updatedAt ? qsTr("更新于 ") + AstnStyle.formatDateTime(bookInfo.updatedAt) : ""
                    color: AstnStyle.cTextTertiary
                    font.pixelSize: AstnStyle.typeCaption
                }
            }

            // Actions (AppleButton)
            Column {
                width: parent.width
                spacing: Theme.paddingMedium

                AppleButton {
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: Theme.horizontalPageMargin
                    }
                    text: qsTr("章节")
                    onClicked: pageStack.push(Qt.resolvedUrl("ChapterListPage.qml"),
                                              { bookId: detailPage.bookId })
                }
                AppleButton {
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: Theme.horizontalPageMargin
                    }
                    text: qsTr("大纲")
                    onClicked: pageStack.push(Qt.resolvedUrl("OutlineListPage.qml"),
                                              { bookId: detailPage.bookId,
                                                bookTitle: detailPage.bookTitle })
                }
                AppleButton {
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: Theme.horizontalPageMargin
                    }
                    text: qsTr("角色")
                    onClicked: pageStack.push(Qt.resolvedUrl("CharacterListPage.qml"),
                                              { bookId: detailPage.bookId })
                }
                AppleButton {
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: Theme.horizontalPageMargin
                    }
                    text: qsTr("世界观")
                    onClicked: pageStack.push(Qt.resolvedUrl("WorldSettingsPage.qml"),
                                              { bookId: detailPage.bookId })
                }
                AppleButton {
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: Theme.horizontalPageMargin
                    }
                    text: qsTr("编辑书籍")
                    onClicked: pageStack.push(Qt.resolvedUrl("EditBookDialog.qml"),
                                              { bookId: detailPage.bookId,
                                                initialTitle: bookInfo.title ? bookInfo.title : "",
                                                initialDescription: bookInfo.description ? bookInfo.description : "",
                                                initialCover: bookInfo.coverDataUri ? bookInfo.coverDataUri : "" })
                }
                AppleButton {
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: Theme.horizontalPageMargin
                    }
                    text: qsTr("导出书籍")
                    onClicked: pageStack.push(Qt.resolvedUrl("ExportDialog.qml"),
                                              { bookId: detailPage.bookId,
                                                bookTitle: bookInfo.title ? bookInfo.title : "" })
                }

                AppleButton {
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: Theme.horizontalPageMargin
                    }
                    variant: "danger"
                    text: qsTr("删除书籍")
                    onClicked: pageStack.push(deleteConfirmDialog)
                }
            }
        }
    }
}

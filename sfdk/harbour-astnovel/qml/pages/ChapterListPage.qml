// ChapterListPage.qml — chapter list with word count, app palette only
import QtQuick 2.2
import Sailfish.Silica 1.0
import "../styles"
import "../components"

Page {
    id: chapterListPage

    allowedOrientations: Orientation.All
    property string bookId: ""

    property var chapterList: []

    function refresh() {
        chapterList = store.chapters(bookId)
    }

    onStatusChanged: {
        if (status === PageStatus.Activating)
            refresh()
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
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("‹ 返回")
                    onClicked: pageStack.pop()
                }

                Label {
                    anchors.centerIn: parent
                    text: qsTr("章节")
                    color: AstnStyle.cTextPrimary
                    font.pixelSize: AstnStyle.typeTitle
                    font.weight: Font.Bold
                }
            }

            EmptyState {
                visible: chapterList.length === 0
                text: qsTr("暂无章节")
                hintText: qsTr("点击下方按钮开始写作")
            }

            Repeater {
                model: chapterList

                AstnCard {
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    x: Theme.horizontalPageMargin
                    showCover: false
                    title: modelData.title
                    subtitle: modelData.content
                    meta: (modelData.wordCount ? modelData.wordCount : 0) + "字 · "
                          + AstnStyle.formatDateTime(modelData.updatedAt)

                    onClicked: pageStack.push(Qt.resolvedUrl("ChapterEditorPage.qml"),
                                              { bookId: chapterListPage.bookId,
                                                chapterId: modelData.id })
                }
            }

            // spacer keeps the last card clear of the pinned bottom button
            Item {
                width: parent.width
                height: 88
            }
        }
    }

    // New chapter button pinned to the bottom
    AppleButton {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
            bottomMargin: Theme.paddingLarge
        }
        text: qsTr("新建章节")
        onClicked: {
            var id = store.createChapter(bookId, qsTr("新章节"))
            if (id !== "")
                pageStack.push(Qt.resolvedUrl("ChapterEditorPage.qml"),
                               { bookId: chapterListPage.bookId, chapterId: id })
        }
    }
}

// BookShelfPage.qml — Book shelf (mirrors BookShelfView.ets: 2-col grid,
// landscape auto-widens to 3 columns for responsiveness)
import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import "../styles"
import "../components"

Page {
    id: shelfPage

    allowedOrientations: Orientation.All

    property var shelfBooks: []
    property string pendingImportPath: ""
    property string conflictBookId: ""

    function refresh() {
        shelfBooks = store.books()
    }

    onStatusChanged: {
        if (status === PageStatus.Activating)
            refresh()
    }

    Component.onCompleted: refresh()

    // Import conflict dialog (mirrors AstnImportService: same-title book found)
    Component {
        id: importConflictDialog

        Dialog {
            id: conflictPage

            canAccept: false     // the user must choose one of the three actions

            Rectangle {
                anchors.fill: parent
                color: AstnStyle.cBackground
                z: -1
            }

            Column {
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
                        onClicked: conflictPage.reject()
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("检测到同名书籍")
                    color: AstnStyle.cTextPrimary
                    font.pixelSize: AstnStyle.typeHeadline
                    font.weight: Font.Bold
                }

                Label {
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("书架中已存在同名的书，请选择导入方式：")
                    color: AstnStyle.cTextSecondary
                    font.pixelSize: AstnStyle.typeBody
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                AppleButton {
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: Theme.horizontalPageMargin
                    }
                    text: qsTr("创建副本")
                    onClicked: {
                        store.importBookFromAstn(shelfPage.pendingImportPath, "copy")
                        shelfPage.refresh()
                        pageStack.pop()
                    }
                }

                AppleButton {
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: Theme.horizontalPageMargin
                    }
                    text: qsTr("覆盖原书")
                    onClicked: {
                        store.deleteBook(shelfPage.conflictBookId)
                        store.importBookFromAstn(shelfPage.pendingImportPath, "")
                        shelfPage.refresh()
                        pageStack.pop()
                    }
                }

                AppleButton {
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: Theme.horizontalPageMargin
                    }
                    variant: "secondary"
                    text: qsTr("跳过")
                    onClicked: pageStack.pop()
                }
            }
        }
    }

    // Book import (.astn file picker, like the original 📥 button)
    FilePickerPage {
        id: importPicker
        nameFilters: [ "*.astn" ]
        onSelectedContentChanged: {
            var p = selectedContent
            if (p.toString() === "" || p === shelfPage.pendingImportPath)
                return
            shelfPage.pendingImportPath = p
            var conflictId = store.importConflictBookId(p)
            if (conflictId !== "") {
                shelfPage.conflictBookId = conflictId
                pageStack.push(importConflictDialog)
            } else {
                store.importBookFromAstn(p, "")
                shelfPage.refresh()
            }
        }
    }

    // Page background (DesignTokens COLOR_BACKGROUND)
    Rectangle {
        anchors.fill: parent
        color: AstnStyle.cBackground
        z: -1
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + Theme.paddingLarge * 2

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.paddingLarge

            // Large title + settings (original: padding 20/16/8, 40x40 buttons)
            Item {
                width: parent.width
                height: 64

                Label {
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingSmall
                    }
                    text: "NovelSpace"
                    color: AstnStyle.cTextPrimary
                    font.pixelSize: 34
                    font.weight: Font.Bold
                }

                Item {
                    id: importBtn
                    anchors {
                        right: settingsBtn.left
                        rightMargin: Theme.paddingMedium
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingSmall
                    }
                    width: 40
                    height: 40

                    Label {
                        anchors.centerIn: parent
                        text: "📥"
                        font.pixelSize: 20
                        color: AstnStyle.cTextSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: pageStack.push(importPicker)
                    }
                }

                Item {
                    id: settingsBtn
                    anchors {
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingSmall
                    }
                    width: 40
                    height: 40

                    Label {
                        anchors.centerIn: parent
                        text: "⚙"
                        font.pixelSize: 22
                        color: AstnStyle.cTextSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
                    }
                }
            }

            // Empty state (original: 📚 48px + hint)
            Item {
                visible: shelfBooks.length === 0
                width: parent.width
                height: shelfPage.height - 220 > 120 ? shelfPage.height - 220 : 120

                Column {
                    anchors.centerIn: parent
                    width: parent.width
                    spacing: Theme.paddingMedium

                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "📚"
                        font.pixelSize: 48
                    }

                    Label {
                        width: parent.width - 80
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("还没有书籍，点击下方按钮开始创作")
                        color: AstnStyle.cTextSecondary
                        font.pixelSize: AstnStyle.typeBody
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // Book grid — responsive: 2 columns portrait, 3 landscape
            Grid {
                id: bookGrid
                visible: shelfBooks.length > 0
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Theme.horizontalPageMargin - 8 > 0 ? Theme.horizontalPageMargin - 8 : 8
                    rightMargin: Theme.horizontalPageMargin - 8 > 0 ? Theme.horizontalPageMargin - 8 : 8
                }
                columns: shelfPage.width > shelfPage.height ? 3 : 2
                spacing: 10

                Repeater {
                    model: shelfBooks

                    AstnCard {
                        width: Math.floor((bookGrid.width - (bookGrid.columns - 1) * bookGrid.columnSpacing)
                                          / bookGrid.columns)
                        showCover: true
                        coverUri: modelData.coverDataUri ? modelData.coverDataUri : ""
                        title: modelData.title
                        meta: qsTr("%1章").arg(modelData.chapterCount ? modelData.chapterCount : 0) + " · "
                              + AstnStyle.formatDate(modelData.updatedAt)

                        onClicked: pageStack.push(Qt.resolvedUrl("BookDetailPage.qml"),
                                                  { bookId: modelData.id })
                        onHold: pageStack.push(Qt.resolvedUrl("EditBookDialog.qml"),
                                               { bookId: modelData.id,
                                                 initialTitle: modelData.title,
                                                 initialDescription: modelData.description ? modelData.description : "",
                                                 initialCover: modelData.coverDataUri ? modelData.coverDataUri : "" })
                    }
                }
            }

            // spacer keeps the last row clear of the pinned bottom button
            Item {
                width: parent.width
                height: 88
            }
        }
    }

    // New-book button pinned to the bottom (original: 90% width, height 50, "+ 新建书籍")
    AppleButton {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
        }
        width: parent.width * 0.9
        customHeight: 50
        text: "+ " + qsTr("新建书籍")
        onClicked: pageStack.push(Qt.resolvedUrl("EditBookDialog.qml"))
    }
}

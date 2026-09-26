// OutlineDetailPage.qml — edit one outline node + linked entity toggles
import QtQuick 2.2
import Sailfish.Silica 1.0
import "../styles"
import "../components"

Page {
    id: outlineDetailPage

    allowedOrientations: Orientation.All
    property string bookId: ""
    property string outlineId: ""
    property var node: ({})
    property var chapterItems: []
    property var charItems: []
    property var worldItems: []          // flattened across all categories
    property var linkChapters: []
    property var linkChars: []
    property var linkWorld: []

    function notify(msg) {
        toastLabel.text = msg
        toastRect.opacity = 0.95
        toastTimer.restart()
    }

    function containsId(arr, id) {
        for (var i = 0; i < arr.length; i++) {
            if (arr[i] === id)
                return true
        }
        return false
    }

    function levelLabel(level) {
        return level === 0 ? qsTr("卷") : (level === 1 ? qsTr("章") : qsTr("节"))
    }

    function entryTitle(e) {
        var fields = e.fields ? e.fields : {}
        var labels = store.worldFields(e.category ? e.category : "OTHER")
        for (var i = 0; i < labels.length; i++) {
            if (labels[i] === "备注")
                continue
            var v = fields[labels[i]] ? fields[labels[i]] : ""
            if (v.length > 0)
                return v
        }
        return qsTr("（未填写）")
    }

    function load() {
        var all = store.outlines(bookId)
        for (var i = 0; i < all.length; i++) {
            if (all[i].id === outlineId) {
                node = all[i]
                break
            }
        }
        chapterItems = store.chapters(bookId)
        charItems = store.characters(bookId)
        worldItems = []
        var cats = ["GEOGRAPHY", "HISTORY", "MAGIC_SYSTEM", "SOCIAL_STRUCTURE", "OTHER"]
        for (var c = 0; c < cats.length; c++) {
            var items = store.worldEntries(bookId, cats[c])
            for (var j = 0; j < items.length; j++)
                worldItems.push(items[j])
        }
        linkChapters = node.linkedChapterIds ? node.linkedChapterIds : []
        linkChars = node.linkedCharacterIds ? node.linkedCharacterIds : []
        linkWorld = node.linkedWorldEntryIds ? node.linkedWorldEntryIds : []
    }

    function toggleLink(kind, id) {
        var arr, key
        if (kind === "chapter") { arr = linkChapters.slice(); key = "linkedChapterIds" }
        else if (kind === "char") { arr = linkChars.slice(); key = "linkedCharacterIds" }
        else { arr = linkWorld.slice(); key = "linkedWorldEntryIds" }
        var pos = arr.indexOf(id)
        if (pos >= 0)
            arr.splice(pos, 1)
        else
            arr.push(id)
        var fields = {}
        fields[key] = arr
        store.updateOutline(bookId, outlineId, fields)
        if (kind === "chapter") linkChapters = arr
        else if (kind === "char") linkChars = arr
        else linkWorld = arr
    }

    function save() {
        if (store.updateOutline(bookId, outlineId, {
                title: titleField.text,
                content: contentArea.text,
                notes: notesArea.text
            }))
            notify(qsTr("已保存"))
        else
            notify(qsTr("保存失败"))
    }

    Component {
        id: deleteOutlineDialog

        Dialog {
            id: delPage

            canAccept: true

            Rectangle {
                anchors.fill: parent
                color: AstnStyle.cBackground
                z: -1
            }

            onAccepted: {
                store.deleteOutline(outlineDetailPage.bookId, outlineDetailPage.outlineId)
                pageStack.pop()   // back to outline list
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
                        onClicked: delPage.reject()
                    }

                    TextButton {
                        anchors {
                            right: parent.right
                            rightMargin: Theme.horizontalPageMargin
                            verticalCenter: parent.verticalCenter
                        }
                        text: qsTr("确认")
                        onClicked: delPage.accept()
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("删除大纲")
                    color: AstnStyle.cTextPrimary
                    font.pixelSize: AstnStyle.typeHeadline
                    font.weight: Font.Bold
                }

                Label {
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("确定删除该大纲节点吗？该操作不可恢复。")
                    color: AstnStyle.cTextSecondary
                    font.pixelSize: AstnStyle.typeBody
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Activating)
            load()
    }

    Rectangle {
        anchors.fill: parent
        color: AstnStyle.cBackground
        z: -1
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: detailColumn.height

        Column {
            id: detailColumn
            width: parent.width
            spacing: Theme.paddingMedium

            Item {
                width: parent.width
                height: 56

                TextButton {
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("‹ 返回")
                    onClicked: pageStack.pop()
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Label {
                        text: qsTr("编辑大纲")
                        color: AstnStyle.cTextPrimary
                        font.pixelSize: AstnStyle.typeTitle
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        radius: 4
                        color: "#E3F2FD"
                        height: 20
                        width: levelChip.width + 12
                        anchors.verticalCenter: parent.verticalCenter

                        Label {
                            id: levelChip
                            anchors.centerIn: parent
                            text: levelLabel(node.level ? node.level : 0)
                            color: AstnStyle.cPrimary
                            font.pixelSize: AstnStyle.typeCaption
                        }
                    }
                }

                TextButton {
                    anchors {
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("保存")
                    onClicked: outlineDetailPage.save()
                }
            }

            TextField {
                id: titleField
                width: parent.width
                text: node.title ? node.title : ""
                color: AstnStyle.cTextPrimary
                label: qsTr("标题")
                placeholderText: qsTr("输入大纲标题")
            }

            AppleButton {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                text: node.level === 0 ? qsTr("添加章") : (node.level === 1 ? qsTr("添加节") : qsTr("添加子节"))
                onClicked: {
                    var childLevel = (node.level ? node.level : 0) + 1
                    var childTitle = childLevel === 1 ? qsTr("新章")
                                   : (childLevel === 2 ? qsTr("新节") : qsTr("新子节"))
                    var id = store.createOutline(bookId, outlineId, childLevel, childTitle)
                    notify(id !== "" ? qsTr("已添加子节点") : qsTr("创建失败"))
                }
            }

            TextArea {
                id: contentArea
                width: parent.width
                height: 240
                text: node.content ? node.content : ""
                color: AstnStyle.cTextPrimary
                label: qsTr("内容")
                placeholderText: qsTr("填写大纲内容")
            }

            TextArea {
                id: notesArea
                width: parent.width
                height: 120
                text: node.notes ? node.notes : ""
                color: AstnStyle.cTextPrimary
                label: qsTr("备注")
                placeholderText: qsTr("填写备注")
            }

            AppleButton {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                variant: "danger"
                text: qsTr("删除该节点")
                onClicked: pageStack.push(deleteOutlineDialog)
            }

            // Linked chapters
            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                }
                text: qsTr("关联章节")
                color: AstnStyle.cTextSecondary
                font.pixelSize: AstnStyle.typeCaption
            }

            Repeater {
                model: chapterItems

                Item {
                    width: parent.width
                    height: 44

                    Label {
                        anchors {
                            left: parent.left
                            leftMargin: Theme.horizontalPageMargin + 12
                            verticalCenter: parent.verticalCenter
                        }
                        width: parent.width - 100
                        text: modelData.title
                        color: AstnStyle.cTextPrimary
                        font.pixelSize: AstnStyle.typeBody
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }

                    Label {
                        anchors {
                            right: parent.right
                            rightMargin: Theme.horizontalPageMargin + 12
                            verticalCenter: parent.verticalCenter
                        }
                        text: containsId(linkChapters, modelData.id) ? "✓" : "○"
                        color: containsId(linkChapters, modelData.id)
                               ? AstnStyle.cPrimary : AstnStyle.cTextTertiary
                        font.pixelSize: AstnStyle.typeHeadline
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: toggleLink("chapter", modelData.id)
                    }
                }
            }

            // Linked characters
            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                }
                text: qsTr("关联角色")
                color: AstnStyle.cTextSecondary
                font.pixelSize: AstnStyle.typeCaption
            }

            Repeater {
                model: charItems

                Item {
                    width: parent.width
                    height: 44

                    Label {
                        anchors {
                            left: parent.left
                            leftMargin: Theme.horizontalPageMargin + 12
                            verticalCenter: parent.verticalCenter
                        }
                        width: parent.width - 100
                        text: modelData.name
                        color: AstnStyle.cTextPrimary
                        font.pixelSize: AstnStyle.typeBody
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }

                    Label {
                        anchors {
                            right: parent.right
                            rightMargin: Theme.horizontalPageMargin + 12
                            verticalCenter: parent.verticalCenter
                        }
                        text: containsId(linkChars, modelData.id) ? "✓" : "○"
                        color: containsId(linkChars, modelData.id)
                               ? AstnStyle.cPrimary : AstnStyle.cTextTertiary
                        font.pixelSize: AstnStyle.typeHeadline
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: toggleLink("char", modelData.id)
                    }
                }
            }

            // Linked world entries
            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                }
                text: qsTr("关联世界观")
                color: AstnStyle.cTextSecondary
                font.pixelSize: AstnStyle.typeCaption
            }

            Repeater {
                model: worldItems

                Item {
                    width: parent.width
                    height: 44

                    Label {
                        anchors {
                            left: parent.left
                            leftMargin: Theme.horizontalPageMargin + 12
                            verticalCenter: parent.verticalCenter
                        }
                        width: parent.width - 100
                        text: entryTitle(modelData)
                        color: AstnStyle.cTextPrimary
                        font.pixelSize: AstnStyle.typeBody
                        maximumLineCount: 1
                        elide: Text.ElideRight
                    }

                    Label {
                        anchors {
                            right: parent.right
                            rightMargin: Theme.horizontalPageMargin + 12
                            verticalCenter: parent.verticalCenter
                        }
                        text: containsId(linkWorld, modelData.id) ? "✓" : "○"
                        color: containsId(linkWorld, modelData.id)
                               ? AstnStyle.cPrimary : AstnStyle.cTextTertiary
                        font.pixelSize: AstnStyle.typeHeadline
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: toggleLink("world", modelData.id)
                    }
                }
            }
        }
    }

    // Toast
    Rectangle {
        id: toastRect
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: Theme.itemSizeLarge
        }
        width: Math.min(parent.width - 2 * Theme.paddingLarge, toastLabel.implicitWidth + 2 * Theme.paddingLarge)
        height: Theme.itemSizeSmall
        radius: AstnStyle.radiusButton
        color: AstnStyle.cPrimary
        opacity: 0

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Label {
            id: toastLabel
            anchors.centerIn: parent
            color: "#FFFFFF"
            font.pixelSize: AstnStyle.typeBody
        }

        Timer {
            id: toastTimer
            interval: 1800
            onTriggered: toastRect.opacity = 0
        }
    }
}

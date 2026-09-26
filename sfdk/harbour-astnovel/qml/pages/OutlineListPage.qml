// OutlineListPage.qml — outline tree: volumes/chapters/sections (mirrors the original 大纲 tab)
import QtQuick 2.2
import Sailfish.Silica 1.0
import "../styles"
import "../components"

Page {
    id: outlineListPage

    allowedOrientations: Orientation.All
    property string bookId: ""
    property string bookTitle: ""

    property var allNodes: []
    property var rows: []           // flattened visible rows {node, depth, hasChildren}
    property var expandedIds: []
    property int deleteIndex: -1

    function containsId(arr, id) {
        for (var i = 0; i < arr.length; i++) {
            if (arr[i] === id)
                return true
        }
        return false
    }

    function childrenOf(pid) {
        var kids = []
        for (var i = 0; i < allNodes.length; i++) {
            if (allNodes[i].parentId === pid)
                kids.push(allNodes[i])
        }
        kids.sort(function(a, b) { return (a.order || 0) - (b.order || 0) })
        return kids
    }

    function levelLabel(level) {
        return level === 0 ? qsTr("卷") : (level === 1 ? qsTr("章") : qsTr("节"))
    }

    function nodeSummary(n) {
        var v = (n.content && n.content.length > 0) ? n.content
              : ((n.notes && n.notes.length > 0) ? n.notes : "")
        return v.length > 50 ? v.substring(0, 50) + "..." : v
    }

    function pushNode(r, node, depth) {
        var kids = childrenOf(node.id)
        r.push({ node: node, depth: depth, hasChildren: kids.length > 0 })
        if (containsId(expandedIds, node.id)) {
            for (var i = 0; i < kids.length; i++)
                pushNode(r, kids[i], depth + 1)
        }
    }

    function rebuild() {
        allNodes = store.outlines(bookId)
        var r = []
        var tops = childrenOf("")
        for (var i = 0; i < tops.length; i++)
            pushNode(r, tops[i], 0)
        rows = r
    }

    onStatusChanged: {
        if (status === PageStatus.Activating)
            rebuild()
    }

    Component {
        id: deleteOutlineDialog

        Dialog {
            id: delPage
            property string delId: ""
            property string delTitle: ""

            canAccept: true

            Rectangle {
                anchors.fill: parent
                color: AstnStyle.cBackground
                z: -1
            }

            onAccepted: {
                store.deleteOutline(outlineListPage.bookId, delPage.delId)
                outlineListPage.rebuild()
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
                    text: qsTr("确定删除「%1」吗？该操作不可恢复。").arg(delPage.delTitle)
                    color: AstnStyle.cTextSecondary
                    font.pixelSize: AstnStyle.typeBody
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
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
        contentHeight: outlineColumn.height

        Column {
            id: outlineColumn
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

                Label {
                    anchors.centerIn: parent
                    text: qsTr("大纲")
                    color: AstnStyle.cTextPrimary
                    font.pixelSize: AstnStyle.typeTitle
                    font.weight: Font.Bold
                }
            }

            Label {
                visible: rows.length === 0
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("还没有大纲，点击下方按钮添加")
                color: AstnStyle.cTextTertiary
                font.pixelSize: AstnStyle.typeBody
            }

            Repeater {
                model: outlineListPage.rows

                Item {
                    width: parent.width
                    height: rowCard.height

                    Rectangle {
                        id: rowCard
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        x: Theme.horizontalPageMargin
                        height: rowInner.height + 2 * AstnStyle.infoVPad
                        radius: AstnStyle.radiusCard
                        color: AstnStyle.cSurface

                        readonly property var node: modelData.node

                        Row {
                            id: rowInner
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: AstnStyle.infoVPad
                                leftMargin: AstnStyle.infoHPad + modelData.depth * 20
                                rightMargin: AstnStyle.infoHPad
                            }
                            spacing: 8

                            Label {
                                visible: modelData.hasChildren
                                text: outlineListPage.containsId(outlineListPage.expandedIds, rowCard.node.id)
                                      ? "▾" : "▸"
                                color: AstnStyle.cPrimary
                                font.pixelSize: AstnStyle.typeBody
                                width: 20
                            }

                            Label {
                                visible: !modelData.hasChildren
                                width: 20
                                text: "·"
                                color: AstnStyle.cTextTertiary
                                font.pixelSize: AstnStyle.typeBody
                            }

                            Column {
                                width: parent.width - 28
                                spacing: 2

                                Row {
                                    spacing: 8

                                    Label {
                                        text: rowCard.node.title && rowCard.node.title.length > 0
                                              ? rowCard.node.title : qsTr("未命名大纲")
                                        color: AstnStyle.cTextPrimary
                                        font.pixelSize: AstnStyle.typeBody
                                        font.weight: Font.Bold
                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        radius: 4
                                        color: "#E3F2FD"
                                        height: 18
                                        width: chipLabel.width + 12

                                        Label {
                                            id: chipLabel
                                            anchors.centerIn: parent
                                            text: outlineListPage.levelLabel(rowCard.node.level)
                                            color: AstnStyle.cPrimary
                                            font.pixelSize: AstnStyle.typeCaption
                                        }
                                    }
                                }

                                Label {
                                    visible: outlineListPage.nodeSummary(rowCard.node).length > 0
                                    width: parent.width
                                    text: outlineListPage.nodeSummary(rowCard.node)
                                    color: AstnStyle.cTextSecondary
                                    font.pixelSize: AstnStyle.typeCaption
                                    maximumLineCount: 2
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: pageStack.push(Qt.resolvedUrl("OutlineDetailPage.qml"),
                                                  { bookId: outlineListPage.bookId,
                                                    outlineId: rowCard.node.id })
                        onPressAndHold: pageStack.push(deleteOutlineDialog,
                                                       { delId: rowCard.node.id,
                                                         delTitle: rowCard.node.title })
                    }
                }
            }

            // spacer keeps the last node clear of the pinned bottom button
            Item {
                width: parent.width
                height: 88
            }
        }
    }

    // Add-volume button pinned to the bottom
    AppleButton {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
            bottomMargin: Theme.paddingLarge
        }
        text: qsTr("添加卷")
        onClicked: {
            var id = store.createOutline(outlineListPage.bookId, "", 0, qsTr("新卷"))
            if (id !== "")
                pageStack.push(Qt.resolvedUrl("OutlineDetailPage.qml"),
                               { bookId: outlineListPage.bookId, outlineId: id })
        }
    }
}

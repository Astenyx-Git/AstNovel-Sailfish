// WorldSettingsPage.qml — worldbuilding (mirrors WorldSettingListView.ets:
// 2-col category grid "N条", then entry list per category; landscape widens)
import QtQuick 2.2
import Sailfish.Silica 1.0
import "../styles"
import "../components"

Page {
    id: worldPage

    allowedOrientations: Orientation.All
    property string bookId: ""

    property string currentCategory: ""     // "" → category grid
    property var entryItems: []
    readonly property var categories: [
        { key: "GEOGRAPHY",       name: qsTr("地理") },
        { key: "HISTORY",         name: qsTr("历史") },
        { key: "MAGIC_SYSTEM",    name: qsTr("力量体系") },
        { key: "SOCIAL_STRUCTURE", name: qsTr("社会结构") },
        { key: "OTHER",           name: qsTr("其他") }
    ]

    function catName(key) {
        for (var i = 0; i < categories.length; i++)
            if (categories[i].key === key) return categories[i].name
        return key
    }

    function catCount(key) {
        return store.worldEntries(bookId, key).length
    }

    function openCategory(key) {
        currentCategory = key
        entryItems = store.worldEntries(bookId, key)
    }

    function backToCategories() {
        currentCategory = ""
        entryItems = []
    }

    onStatusChanged: {
        if (status === PageStatus.Activating && currentCategory !== "")
            entryItems = store.worldEntries(bookId, currentCategory)
    }

    function entryTitle(e) {
        var f = e.fields ? e.fields : {}
        for (var k in f) {
            if (k === "备注") continue
            var v = f[k]
            if (v && v.length > 0) return v
        }
        return qsTr("（未填写）")
    }

    function entrySubtitle(e) {
        var f = e.fields ? e.fields : {}
        return f["备注"] ? f["备注"] : ""
    }

    Component {
        id: entryDialog

        Dialog {
            id: entryPage
            property string eid: ""
            property var initialValues: ({})
            property var currentValues: ({})
            property var fieldLabels: store.worldFields(worldPage.currentCategory)

            // Dialog background (app palette)
            Rectangle {
                anchors.fill: parent
                color: AstnStyle.cBackground
                z: -1
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: column.height

                Column {
                    id: column
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
                            onClicked: entryPage.reject()
                        }

                        Label {
                            anchors.centerIn: parent
                            text: entryPage.eid !== "" ? qsTr("编辑条目") : qsTr("添加条目")
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
                            onClicked: entryPage.accept()
                        }
                    }

                    // Per-category field template (mirrors WorldSettingFieldTemplates)
                    Repeater {
                        model: entryPage.fieldLabels

                        Column {
                            width: parent.width
                            spacing: Theme.paddingSmall

                            Label {
                                anchors {
                                    left: parent.left
                                    leftMargin: Theme.horizontalPageMargin
                                }
                                text: AstnStyle.worldFieldLabel(modelData)
                                color: AstnStyle.cTextSecondary
                                font.pixelSize: AstnStyle.typeCaption
                            }

                            TextField {
                                width: parent.width
                                text: entryPage.initialValues[modelData]
                                      ? entryPage.initialValues[modelData] : ""
                                color: AstnStyle.cTextPrimary
                                placeholderText: qsTr("填写%1").arg(AstnStyle.worldFieldLabel(modelData))
                                onTextChanged: {
                                    var v = entryPage.currentValues
                                    v[modelData] = text
                                    entryPage.currentValues = v
                                }
                            }
                        }
                    }
                }
            }

            onAccepted: {
                var fields = {}
                for (var i = 0; i < entryPage.fieldLabels.length; i++) {
                    var key = entryPage.fieldLabels[i]
                    fields[key] = entryPage.currentValues[key] ? entryPage.currentValues[key] : ""
                }
                if (entryPage.eid !== "")
                    store.updateWorldEntry(worldPage.bookId, worldPage.currentCategory,
                                           entryPage.eid, fields, "")
                else
                    store.createWorldEntry(worldPage.bookId, worldPage.currentCategory,
                                           fields, "")
                worldPage.entryItems = store.worldEntries(worldPage.bookId, worldPage.currentCategory)
            }

            Component.onCompleted: {
                if (entryPage.eid !== "") {
                    var items = worldPage.entryItems
                    for (var i = 0; i < items.length; i++) {
                        if (items[i].id === entryPage.eid) {
                            entryPage.initialValues = items[i].fields ? items[i].fields : {}
                            break
                        }
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
        contentHeight: contentColumn.height + Theme.paddingLarge * 2

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.paddingLarge

            // Header: back / centered title / right slot
            Item {
                width: parent.width
                height: 56

                TextButton {
                    id: backBtn
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    text: currentCategory === "" ? qsTr("‹ 返回") : qsTr("‹ 分类")
                    onClicked: currentCategory === "" ? pageStack.pop() : backToCategories()
                }

                Label {
                    anchors.centerIn: parent
                    text: currentCategory === "" ? qsTr("世界观设定") : catName(currentCategory)
                    color: AstnStyle.cTextPrimary
                    font.pixelSize: AstnStyle.typeHeadline
                    font.weight: Font.Bold
                    width: parent.width - 2 * (backBtn.width + Theme.paddingLarge)
                    horizontalAlignment: Text.AlignHCenter
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }

                TextButton {
                    visible: currentCategory !== ""
                    anchors {
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("＋ 添加")
                    onClicked: pageStack.push(entryDialog)
                }
            }

            // Category grid (2 cols portrait / 3 landscape)
            Grid {
                id: catGrid
                visible: currentCategory === ""
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: Theme.horizontalPageMargin - 8 > 0 ? Theme.horizontalPageMargin - 8 : 8
                    rightMargin: Theme.horizontalPageMargin - 8 > 0 ? Theme.horizontalPageMargin - 8 : 8
                }
                columns: worldPage.width > worldPage.height ? 3 : 2
                spacing: 10

                Repeater {
                    model: categories

                    // WorldSettingCategoryCard: name + "N条", centered
                    Item {
                        width: Math.floor((catGrid.width - (catGrid.columns - 1) * catGrid.spacing)
                                          / catGrid.columns)
                        height: 76

                        Rectangle {
                            id: cardBody
                            anchors.fill: parent
                            radius: AstnStyle.radiusCard
                            color: AstnStyle.cSurface
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Label {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.name
                                color: AstnStyle.cTextPrimary
                                font.pixelSize: AstnStyle.typeBody
                                font.weight: Font.Medium
                            }

                            Label {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: qsTr("%1条").arg(catCount(modelData.key))
                                color: AstnStyle.cTextSecondary
                                font.pixelSize: AstnStyle.typeCaption
                            }
                        }

                        MouseArea {
                            id: catMouse
                            anchors.fill: parent
                            onClicked: openCategory(modelData.key)
                        }

                        scale: catMouse.pressed ? AstnStyle.scalePress : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: AstnStyle.durationPress; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }

            // Entry list for the selected category
            Label {
                visible: currentCategory !== "" && entryItems.length === 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("暂无条目，点击右上角添加")
                color: AstnStyle.cTextSecondary
                font.pixelSize: AstnStyle.typeBody
            }

            Repeater {
                model: entryItems

                AstnCard {
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    x: Theme.horizontalPageMargin
                    title: entryTitle(modelData)
                    subtitle: entrySubtitle(modelData)

                    onClicked: pageStack.push(entryDialog, { eid: modelData.id })
                    onHold: {
                        store.deleteWorldEntry(worldPage.bookId, worldPage.currentCategory, modelData.id)
                        entryItems = store.worldEntries(bookId, currentCategory)
                    }
                }
            }
        }
    }
}

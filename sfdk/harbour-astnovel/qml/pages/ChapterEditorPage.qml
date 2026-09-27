// ChapterEditorPage.qml — write and save a chapter, custom toolbar
import QtQuick 2.2
import Sailfish.Silica 1.0
import "../styles"
import "../components"

Page {
    id: editorPage

    allowedOrientations: Orientation.All
    property string bookId: ""
    property string chapterId: ""
    property string chapterTitle: ""
    property bool dirty: false
    property string savedContent: ""

    function notify(msg) {
        toastLabel.text = msg
        toastRect.opacity = 0.95
        toastTimer.restart()
    }

    // Markdown prefix/suffix insertion (mirrors EditorFormat.getMarkdownPrefix/Suffix)
    function applyFormat(prefix, suffix) {
        var ta = editorTextArea
        var t = ta.text
        var start = ta.selectionStart
        var end = ta.selectionEnd
        if (suffix !== "" && end > start) {
            ta.text = t.substring(0, start) + prefix + t.substring(start, end) + suffix
                     + t.substring(end)
            ta.cursorPosition = end + prefix.length + suffix.length
        } else {
            // line-level format: insert at the start of the current line
            var pos = Math.max(ta.cursorPosition, 0)
            var lineStart = t.lastIndexOf("\n", Math.max(pos - 1, 0)) + 1
            ta.text = t.substring(0, lineStart) + prefix + t.substring(lineStart)
            ta.cursorPosition = pos + prefix.length
        }
        dirty = true
    }

    function saveSilently() {
        if (store.saveChapter(bookId, chapterId, editorTextArea.text)) {
            savedContent = editorTextArea.text
            dirty = false
            store.clearAutosave(bookId, chapterId)
        }
    }

    function save() {
        if (store.saveChapter(bookId, chapterId, editorTextArea.text)) {
            savedContent = editorTextArea.text
            dirty = false
            store.clearAutosave(bookId, chapterId)
            notify(qsTr("已保存"))
        } else {
            notify(qsTr("保存失败"))
        }
    }

    // Markdown toolbar buttons (labels mirror the original EditorToolbar)
    readonly property var toolbarButtons: [
        { label: "B",  pre: "**", suf: "**" },
        { label: "I",  pre: "*",  suf: "*" },
        { label: "H1", pre: "# ", suf: "" },
        { label: "H2", pre: "## ", suf: "" },
        { label: "H3", pre: "### ", suf: "" },
        { label: "OL", pre: "1. ", suf: "" },
        { label: "UL", pre: "- ", suf: "" }
    ]

    // ===== Quick reference bottom sheet (mirrors the original 50%-height drawer) =====
    property bool quickRefOpen: false
    property int quickRefTab: 0            // 0 大纲 | 1 角色 | 2 世界观
    property string expandedOutlineId: ""
    property string expandedCharacterId: ""
    property string expandedCategory: ""
    property var characterItems: []
    property var outlineItems: []
    property bool hasWorldEntries: false
    property string backdropUrl: ""     // one-shot editor snapshot for the glass backdrop
    property var backdropResult: null   // keep the grab result alive or its URL dies

    // Dual-path glass: live GaussianBlur when the probe passed, snapshot otherwise
    readonly property bool liveBlurActive: AstnStyle.liveBlurOk
                                           && blurLoader.status === Component.Ready

    readonly property var quickRefCharLabels: [
        { key: "name",        label: qsTr("姓名") },
        { key: "age",         label: qsTr("年龄") },
        { key: "gender",      label: qsTr("性别") },
        { key: "height",      label: qsTr("身高") },
        { key: "weight",      label: qsTr("体重") },
        { key: "race",        label: qsTr("种族") },
        { key: "appearance",  label: qsTr("外貌描述") },
        { key: "personality", label: qsTr("性格特征") },
        { key: "background",  label: qsTr("背景故事") },
        { key: "notes",       label: qsTr("备注") }
    ]

    readonly property var quickRefWorldCats: [
        { cat: "GEOGRAPHY",        label: qsTr("地理") },
        { cat: "HISTORY",          label: qsTr("历史") },
        { cat: "MAGIC_SYSTEM",     label: qsTr("力量体系") },
        { cat: "SOCIAL_STRUCTURE", label: qsTr("社会结构") },
        { cat: "OTHER",            label: qsTr("其他") }
    ]

    function openQuickRef() {
        editorTextArea.focus = false
        characterItems = store.characters(bookId)
        outlineItems = store.outlines(bookId)
        hasWorldEntries = false
        var cats = quickRefWorldCats
        for (var i = 0; i < cats.length; i++) {
            if (store.worldEntries(bookId, cats[i].cat).length > 0) {
                hasWorldEntries = true
                break
            }
        }
        expandedOutlineId = ""
        expandedCharacterId = ""
        expandedCategory = ""
        quickRefTab = 0
        if (AstnStyle.liveBlurOk) {
            // live path: no snapshot grab needed
            editorPage.quickRefOpen = true
        } else {
            // fallback: grab one static frame (quarter-res = soft), then open
            backdropTimer.restart()
            editorPage.grabToImage(function(result) {
                editorPage.backdropResult = result   // must outlive the callback
                editorPage.backdropUrl = result.url
                if (!editorPage.quickRefOpen)
                    editorPage.quickRefOpen = true
            })
        }
    }

    function topLevelOutlines() {
        var tops = []
        for (var i = 0; i < outlineItems.length; i++) {
            if (!outlineItems[i].parentId || outlineItems[i].parentId === "")
                tops.push(outlineItems[i])
        }
        tops.sort(function(a, b) { return (a.order || 0) - (b.order || 0) })
        return tops
    }

    function childOutlines(pid) {
        var kids = []
        for (var i = 0; i < outlineItems.length; i++) {
            if (outlineItems[i].parentId === pid)
                kids.push(outlineItems[i])
        }
        kids.sort(function(a, b) { return (a.order || 0) - (b.order || 0) })
        return kids
    }

    function nodeSummary(n) {
        var v = (n.content && n.content.length > 0) ? n.content
              : ((n.notes && n.notes.length > 0) ? n.notes : "")
        return v.length > 50 ? v.substring(0, 50) + "..." : v
    }

    function firstFieldSummary(e) {
        // mirrors QuickReferenceDrawer.getFirstFieldSummary: first non-备注 field "字段: 值"
        var fields = e.fields ? e.fields : {}
        var labels = store.worldFields(e.category ? e.category : "OTHER")
        for (var i = 0; i < labels.length; i++) {
            if (labels[i] === "备注")
                continue
            var v = fields[labels[i]] ? fields[labels[i]] : ""
            if (v.length > 0)
                return AstnStyle.worldFieldLabel(labels[i]) + ": " + v
        }
        return ""
    }

    // Auto-save: 30 s interval (original AutoSaveService policy)
    Timer {
        interval: 30000
        repeat: true
        running: editorPage.status === PageStatus.Active
        onTriggered: {
            if (editorPage.dirty && editorTextArea.text !== editorPage.savedContent)
                editorPage.saveSilently()
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            var m = store.chapter(bookId, chapterId)
            chapterTitle = m.title ? m.title : ""
            // Crash recovery: prefer the autosave copy when it differs
            var auto = store.loadAutosave(bookId, chapterId)
            if (auto !== "" && auto !== (m.content ? m.content : "")) {
                editorTextArea.text = auto
                notify(qsTr("已恢复未保存的修改"))
            } else {
                editorTextArea.text = m.content ? m.content : ""
            }
            savedContent = editorTextArea.text
            dirty = false
        } else if (status === PageStatus.Deactivating) {
            if (dirty && editorTextArea.text !== savedContent)
                saveSilently()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: AstnStyle.cBackground
        z: -1
    }

    // Toolbar column pinned to top
    Column {
        id: toolbarColumn
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
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
                text: editorPage.chapterTitle
                color: AstnStyle.cTextPrimary
                font.pixelSize: AstnStyle.typeTitle
                font.weight: Font.Bold
                width: parent.width - 300
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 1
                elide: Text.ElideRight
            }

            Row {
                anchors {
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.paddingMedium

                TextButton {
                    text: qsTr("速查")
                    onClicked: editorPage.openQuickRef()
                }

                TextButton {
                    text: qsTr("保存")
                    onClicked: editorPage.save()
                }
            }
        }

        // Markdown formatting toolbar (original EditorToolbar set, minus align)
        Flickable {
            width: parent.width
            height: 44
            contentWidth: formatRow.width
            boundsBehavior: Flickable.DragOverBounds

            Row {
                id: formatRow
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                spacing: 6

                Repeater {
                    model: editorPage.toolbarButtons

                    TextButton {
                        text: modelData.label
                        textColor: AstnStyle.cTextSecondary
                        onClicked: editorPage.applyFormat(modelData.pre, modelData.suf)
                    }
                }
            }
        }

        AppleButton {
            anchors {
                left: parent.left
                right: parent.right
                margins: Theme.horizontalPageMargin
            }
            variant: "danger"
            text: qsTr("删除本页")
            onClicked: {
                store.deleteChapter(bookId, chapterId)
                pageStack.pop()
            }
        }
    }

    // Word count pinned to bottom (CJK algorithm, mirrors ChapterService.countWords)
    Item {
        id: wordCountRow
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        height: 44

        Label {
            anchors {
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                verticalCenter: parent.verticalCenter
            }
            text: qsTr("%1字").arg(store.countWords(editorTextArea.text))
            color: AstnStyle.cTextTertiary
            font.pixelSize: AstnStyle.typeCaption
        }
    }

    // Editor fills the middle
    TextArea {
        id: editorTextArea
        anchors {
            top: toolbarColumn.bottom
            topMargin: Theme.paddingMedium
            bottom: wordCountRow.top
            left: parent.left
            right: parent.right
        }
        font.pixelSize: AstnStyle.typeBody
        color: AstnStyle.cTextPrimary
        placeholderText: qsTr("开始创作...")
        onTextChanged: {
            editorPage.dirty = true
            if (editorPage.status === PageStatus.Active)
                store.saveAutosave(editorPage.bookId, editorPage.chapterId, text)
        }
    }

    // Safety: if grabToImage never delivers, open the sheet without backdrop
    Timer {
        id: backdropTimer
        interval: 150
        onTriggered: {
            if (!editorPage.quickRefOpen)
                editorPage.quickRefOpen = true
        }
    }

    // ===== Quick reference drawer (scrim + bottom sheet, like the original) =====
    Rectangle {
        id: quickRefScrim
        anchors.fill: parent
        color: "#000000"
        opacity: editorPage.quickRefOpen ? 0.35 : 0
        visible: opacity > 0
        z: 10

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            enabled: editorPage.quickRefOpen
            onClicked: editorPage.quickRefOpen = false
        }
    }

    Rectangle {
        id: quickRefPanel
        anchors {
            left: parent.left
            right: parent.right
        }
        y: editorPage.quickRefOpen ? parent.height - height : parent.height + 2
        height: parent.height / 2
        color: editorPage.liveBlurActive ? "transparent" : AstnStyle.cSurface
        radius: AstnStyle.radiusCard
        border.color: AstnStyle.cSeparator
        border.width: 1
        z: 11

        Behavior on y {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

        // Live path: real GaussianBlur of the editor region behind the panel
        Loader {
            id: blurLoader
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: parent.radius
                bottom: parent.bottom
            }
            active: editorPage.quickRefOpen && AstnStyle.liveBlurOk
            source: Qt.resolvedUrl("../components/QuickRefBlur.qml")
            onStatusChanged: {
                if (status === Loader.Error)
                    console.log("[astn] live blur unavailable, using snapshot backdrop")
            }
            onLoaded: {
                item.sourceItem = editorTextArea
            }
        }

        // Frost veil above the live blur (covers the corner arcs too)
        Rectangle {
            anchors.fill: parent
            color: "#B8FFFFFF"
            visible: editorPage.liveBlurActive
        }

        // Fallback path: static editor snapshot, quarter-res decode (soft), low opacity
        Item {
            id: backdropClip
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: parent.radius
                bottom: parent.bottom
            }
            clip: true
            visible: !editorPage.liveBlurActive
                     && editorPage.backdropUrl !== "" && editorPage.quickRefOpen

            Image {
                id: backdropImage
                y: -backdropClip.height
                width: editorPage.width
                height: editorPage.height
                source: editorPage.backdropUrl
                sourceSize.width: editorPage.width / 4
                sourceSize.height: editorPage.height / 4
                fillMode: Image.Stretch
                smooth: true
                opacity: 0.32
            }
        }

        // hide the bottom rounded corners (fallback path only, panel sits flush)
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: parent.radius
            color: parent.color
        }

        Column {
            anchors.fill: parent
            spacing: 0

            // Sheet header
            Item {
                width: parent.width
                height: 48

                Label {
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("速查面板")
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
                    text: "✕"
                    textColor: AstnStyle.cTextTertiary
                    onClicked: editorPage.quickRefOpen = false
                }
            }

            // Tab bar (大纲 / 角色 / 世界观)
            Item {
                width: parent.width
                height: 40

                Row {
                    anchors.fill: parent

                    Repeater {
                        model: [qsTr("大纲"), qsTr("角色"), qsTr("世界观")]

                        Item {
                            width: parent.width / 3
                            height: parent.height

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Label {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData
                                    color: editorPage.quickRefTab === index
                                           ? AstnStyle.cTextPrimary : AstnStyle.cTextSecondary
                                    font.pixelSize: AstnStyle.typeBody
                                    font.weight: editorPage.quickRefTab === index
                                                 ? Font.Bold : Font.Regular
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: tabLabel.implicitWidth
                                    height: 2
                                    radius: 1
                                    color: editorPage.quickRefTab === index
                                           ? AstnStyle.cPrimary : "transparent"
                                }
                            }

                            Label {
                                id: tabLabel
                                visible: false
                                text: modelData
                                font.pixelSize: AstnStyle.typeBody
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: editorPage.quickRefTab = index
                            }
                        }
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 1
                    color: AstnStyle.cSeparator
                }
            }

            // ---- Tab content ----
            SilicaFlickable {
                width: parent.width
                height: parent.height - 88
                clip: true
                contentHeight: quickRefContent.height

                Column {
                    id: quickRefContent
                    width: parent.width
                    spacing: 6

                    // ---- 大纲 ----
                    Label {
                        visible: editorPage.quickRefTab === 0 && editorPage.outlineItems.length === 0
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("暂无大纲")
                        color: AstnStyle.cTextTertiary
                        font.pixelSize: AstnStyle.typeBody
                    }

                    Repeater {
                        model: editorPage.quickRefTab === 0 ? editorPage.topLevelOutlines() : 0

                        Column {
                            width: parent.width
                            spacing: 4

                            // Volume header (📁)
                            Rectangle {
                                width: parent.width - 2 * Theme.paddingLarge
                                x: Theme.paddingLarge
                                height: 40
                                radius: AstnStyle.radiusButton
                                color: AstnStyle.cBackground

                                Row {
                                    anchors {
                                        left: parent.left
                                        leftMargin: 12
                                        right: parent.right
                                        rightMargin: 12
                                        verticalCenter: parent.verticalCenter
                                    }
                                    spacing: 8

                                    Label { text: "📁"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }

                                    Label {
                                        width: parent.width - 50
                                        text: modelData.title && modelData.title.length > 0
                                              ? modelData.title : qsTr("未命名大纲")
                                        color: AstnStyle.cTextPrimary
                                        font.pixelSize: AstnStyle.typeBody
                                        font.weight: Font.Medium
                                        anchors.verticalCenter: parent.verticalCenter
                                        maximumLineCount: 1
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        text: editorPage.expandedOutlineId === modelData.id ? "▼" : "▶"
                                        color: AstnStyle.cTextTertiary
                                        font.pixelSize: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: editorPage.expandedOutlineId =
                                               (editorPage.expandedOutlineId === modelData.id
                                                ? "" : modelData.id)
                                }
                            }

                            // Expanded: summary + chapters + sections
                            Column {
                                visible: editorPage.expandedOutlineId === modelData.id
                                width: parent.width - 2 * Theme.paddingLarge
                                x: Theme.paddingLarge
                                spacing: 2

                                Label {
                                    visible: editorPage.nodeSummary(modelData).length > 0
                                    width: parent.width - 12
                                    x: 8
                                    text: editorPage.nodeSummary(modelData)
                                    color: AstnStyle.cTextSecondary
                                    font.pixelSize: AstnStyle.typeCaption
                                    wrapMode: Text.WordWrap
                                }

                                Repeater {
                                    model: editorPage.childOutlines(modelData.id)

                                    Column {
                                        width: parent.width
                                        spacing: 2

                                        Row {
                                            width: parent.width
                                            spacing: 6

                                            Label { text: "📄"; font.pixelSize: 12 }

                                            Label {
                                                text: modelData.title && modelData.title.length > 0
                                                      ? modelData.title : qsTr("未命名大纲")
                                                color: AstnStyle.cTextPrimary
                                                font.pixelSize: AstnStyle.typeCaption
                                                font.weight: Font.Medium
                                            }

                                            Label {
                                                visible: editorPage.nodeSummary(modelData).length > 0
                                                width: parent.width - parent.spacing * 2 - 40
                                                text: editorPage.nodeSummary(modelData)
                                                color: AstnStyle.cTextTertiary
                                                font.pixelSize: AstnStyle.typeCaption
                                                maximumLineCount: 1
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Repeater {
                                            model: editorPage.childOutlines(modelData.id)

                                            Row {
                                                width: parent.width
                                                spacing: 4
                                                x: 16

                                                Label { text: "📝"; font.pixelSize: 10 }

                                                Label {
                                                    text: modelData.title && modelData.title.length > 0
                                                          ? modelData.title : qsTr("未命名大纲")
                                                    color: AstnStyle.cTextSecondary
                                                    font.pixelSize: AstnStyle.typeCaption
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---- 角色 ----
                    Label {
                        visible: editorPage.quickRefTab === 1 && editorPage.characterItems.length === 0
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("暂无角色设定")
                        color: AstnStyle.cTextTertiary
                        font.pixelSize: AstnStyle.typeBody
                    }

                    Repeater {
                        model: editorPage.quickRefTab === 1 ? editorPage.characterItems : 0

                        Column {
                            id: sheetCharRow
                            width: parent.width - 2 * Theme.paddingLarge
                            x: Theme.paddingLarge
                            spacing: 2

                            readonly property var charData: modelData

                            Row {
                                width: parent.width
                                spacing: 8

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: AstnStyle.cPrimary

                                    Label {
                                        anchors.centerIn: parent
                                        text: AstnStyle.firstChar(sheetCharRow.charData.name)
                                        color: "#FFFFFF"
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                    }
                                }

                                Column {
                                    width: parent.width - 72
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Label {
                                        text: sheetCharRow.charData.name && sheetCharRow.charData.name.length > 0
                                              ? sheetCharRow.charData.name : qsTr("未命名角色")
                                        color: AstnStyle.cTextPrimary
                                        font.pixelSize: AstnStyle.typeBody
                                        font.weight: Font.Medium
                                    }

                                    Label {
                                        visible: sheetCharRow.charData.personality
                                                 && sheetCharRow.charData.personality.length > 0
                                        width: parent.width
                                        text: sheetCharRow.charData.personality
                                        color: AstnStyle.cTextSecondary
                                        font.pixelSize: AstnStyle.typeCaption
                                        maximumLineCount: 2
                                        wrapMode: Text.WordWrap
                                        elide: Text.ElideRight
                                    }
                                }

                                Label {
                                    text: editorPage.expandedCharacterId === sheetCharRow.charData.id ? "▼" : "▶"
                                    color: AstnStyle.cTextTertiary
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Expanded field pairs (only non-empty, original behavior)
                            Column {
                                visible: editorPage.expandedCharacterId === sheetCharRow.charData.id
                                width: parent.width
                                x: 40
                                spacing: 2

                                Repeater {
                                    model: editorPage.quickRefCharLabels

                                    Label {
                                        visible: sheetCharRow.charData[modelData.key]
                                                 && sheetCharRow.charData[modelData.key].length > 0
                                        width: parent.width
                                        text: modelData.label + "：" + sheetCharRow.charData[modelData.key]
                                        color: AstnStyle.cTextSecondary
                                        font.pixelSize: AstnStyle.typeCaption
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: editorPage.expandedCharacterId =
                                           (editorPage.expandedCharacterId === sheetCharRow.charData.id
                                            ? "" : sheetCharRow.charData.id)
                            }
                        }
                    }

                    // ---- 世界观 ----
                    Label {
                        visible: editorPage.quickRefTab === 2 && !editorPage.hasWorldEntries
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("暂无世界观设定")
                        color: AstnStyle.cTextTertiary
                        font.pixelSize: AstnStyle.typeBody
                    }

                    Repeater {
                        model: editorPage.quickRefTab === 2 ? editorPage.quickRefWorldCats : 0

                        Column {
                            width: parent.width
                            spacing: 4

                            // Category header
                            Rectangle {
                                width: parent.width - 2 * Theme.paddingLarge
                                x: Theme.paddingLarge
                                height: 40
                                radius: AstnStyle.radiusButton
                                color: AstnStyle.cBackground

                                Row {
                                    anchors {
                                        left: parent.left
                                        leftMargin: 12
                                        right: parent.right
                                        rightMargin: 12
                                        verticalCenter: parent.verticalCenter
                                    }
                                    spacing: 8

                                    Label {
                                        width: parent.width - 50
                                        text: modelData.label
                                        color: AstnStyle.cTextPrimary
                                        font.pixelSize: AstnStyle.typeHeadline
                                        font.weight: Font.Medium
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Label {
                                        text: editorPage.expandedCategory === modelData.cat ? "▼" : "▶"
                                        color: AstnStyle.cTextTertiary
                                        font.pixelSize: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: editorPage.expandedCategory =
                                               (editorPage.expandedCategory === modelData.cat
                                                ? "" : modelData.cat)
                                }
                            }

                            // Expanded entries
                            Column {
                                visible: editorPage.expandedCategory === modelData.cat
                                width: parent.width - 2 * Theme.paddingLarge
                                x: Theme.paddingLarge
                                spacing: 4

                                Repeater {
                                    model: store.worldEntries(editorPage.bookId, modelData.cat)

                                    Column {
                                        width: parent.width
                                        x: 20
                                        spacing: 2

                                        Label {
                                            text: modelData.title ? modelData.title : qsTr("（未填写）")
                                            color: AstnStyle.cTextPrimary
                                            font.pixelSize: AstnStyle.typeBody
                                            font.weight: Font.Medium
                                        }

                                        Label {
                                            visible: editorPage.firstFieldSummary(modelData).length > 0
                                            text: editorPage.firstFieldSummary(modelData)
                                            color: AstnStyle.cTextSecondary
                                            font.pixelSize: AstnStyle.typeCaption
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }

                                Label {
                                    visible: store.worldEntries(editorPage.bookId, modelData.cat).length === 0
                                    x: 20
                                    text: qsTr("暂无条目")
                                    color: AstnStyle.cTextTertiary
                                    font.pixelSize: AstnStyle.typeCaption
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Toast (Apple blue pill, fade)
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

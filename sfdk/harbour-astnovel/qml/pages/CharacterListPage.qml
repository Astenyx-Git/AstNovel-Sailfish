// CharacterListPage.qml — character management, app palette only
import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import "../styles"
import "../components"

Page {
    id: characterListPage

    allowedOrientations: Orientation.All
    property string bookId: ""

    property var characterItems: []

    function refresh() {
        characterItems = store.characters(bookId)
    }

    onStatusChanged: {
        if (status === PageStatus.Activating)
            refresh()
    }

    function charSubtitle(c) {
        // mirrors CharacterCard.getShortDescription: personality → appearance → race
        var v = (c.personality && c.personality.length > 0) ? c.personality
              : ((c.appearance && c.appearance.length > 0) ? c.appearance
              : (c.race ? c.race : ""))
        return v.length > 30 ? v.substring(0, 30) + "..." : v
    }

    Component {
        id: characterDialog

        Dialog {
            id: charPage
            property string cid: ""
            property var initialValues: ({})
            property var currentValues: ({})
            property string nameInput: ""
            property string pickMode: ""          // "avatar" | "image"
            property bool hasAvatar: false
            property int avatarRev: 0
            property var imageUris: []

            function avatarThumb() {
                var rev = avatarRev               // dependency for re-evaluation
                if (!hasAvatar || cid === "")
                    return ""
                return store.avatarThumbPath(characterListPage.bookId, cid, 80)
            }

            function reloadImages() {
                var items = characterListPage.characterItems
                for (var i = 0; i < items.length; i++) {
                    if (items[i].id === cid) {
                        imageUris = items[i].imageDataUris ? items[i].imageDataUris : []
                        return
                    }
                }
                imageUris = []
            }

            // Field set mirrors CharacterCard.ets / CharacterDetailView.ets
            readonly property var charFields: [
                { key: "name",        label: qsTr("姓名"), multi: false },
                { key: "age",         label: qsTr("年龄"), multi: false },
                { key: "gender",      label: qsTr("性别"), multi: false },
                { key: "height",      label: qsTr("身高"), multi: false },
                { key: "weight",      label: qsTr("体重"), multi: false },
                { key: "race",        label: qsTr("种族"), multi: false },
                { key: "appearance",  label: qsTr("外貌"), multi: true },
                { key: "personality", label: qsTr("性格"), multi: true },
                { key: "background",  label: qsTr("背景"), multi: true },
                { key: "notes",       label: qsTr("备注"), multi: true }
            ]

            canAccept: nameInput.length > 0

            // Image picker (deferred Component — must not be a Dialog child)
            Component {
                id: imagePickerComp
                ImagePickerPage {
                    onSelectedContentChanged: {
                        if (selectedContent.toString() === "" || charPage.cid === "")
                            return
                        if (charPage.pickMode === "avatar") {
                            store.setCharacterAvatar(characterListPage.bookId, charPage.cid,
                                                     selectedContent)
                            charPage.hasAvatar = true
                            charPage.avatarRev++
                        } else {
                            store.addCharacterImage(characterListPage.bookId, charPage.cid,
                                                    selectedContent)
                        }
                        characterListPage.refresh()
                        charPage.reloadImages()
                    }
                }
            }

            // Dialog background (app palette)
            Rectangle {
                anchors.fill: parent
                color: AstnStyle.cBackground
                z: -1
            }

            onAccepted: {
                var fields = {}
                for (var i = 0; i < charPage.charFields.length; i++) {
                    var k = charPage.charFields[i].key
                    fields[k] = charPage.currentValues[k] ? charPage.currentValues[k] : ""
                }
                if (cid !== "")
                    store.updateCharacter(characterListPage.bookId, cid, fields)
                else
                    store.createCharacter(characterListPage.bookId, fields)
                characterListPage.refresh()
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
                            onClicked: charPage.reject()
                        }

                        Label {
                            anchors.centerIn: parent
                            text: charPage.cid !== "" ? qsTr("编辑角色") : qsTr("添加角色")
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
                            enabled: charPage.nameInput.length > 0
                            opacity: enabled ? 1.0 : 0.4
                            onClicked: charPage.accept()
                        }
                    }

                    // Avatar (edit mode — storage needs the character id)
                    Column {
                        visible: charPage.cid !== ""
                        width: parent.width
                        spacing: Theme.paddingSmall

                        Label {
                            anchors {
                                left: parent.left
                                leftMargin: Theme.horizontalPageMargin
                            }
                            text: qsTr("头像")
                            color: AstnStyle.cTextSecondary
                            font.pixelSize: AstnStyle.typeCaption
                        }

                        Item {
                            width: 80
                            height: 80
                            anchors.horizontalCenter: parent.horizontalCenter

                            Image {
                                anchors.fill: parent
                                visible: charPage.hasAvatar
                                source: charPage.avatarThumb()
                            }

                            Image {
                                anchors.fill: parent
                                visible: !charPage.hasAvatar
                                source: store.gradientCoverPath(
                                            AstnStyle.gradientIndex(charPage.nameInput),
                                            80, 80, 40,
                                            AstnStyle.gradientFor(charPage.nameInput)[0],
                                            AstnStyle.gradientFor(charPage.nameInput)[1])
                            }

                            Label {
                                anchors.centerIn: parent
                                visible: !charPage.hasAvatar
                                text: AstnStyle.firstChar(charPage.nameInput)
                                color: "#FFFFFF"
                                font.pixelSize: 32
                                font.weight: Font.Bold
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Theme.paddingLarge

                            TextButton {
                                text: qsTr("设置头像")
                                onClicked: {
                                    charPage.pickMode = "avatar"
                                    pageStack.push(imagePickerComp)
                                }
                            }

                            TextButton {
                                text: qsTr("清除头像")
                                textColor: AstnStyle.cTextSecondary
                                enabled: charPage.hasAvatar
                                opacity: enabled ? 1.0 : 0.4
                                onClicked: {
                                    store.clearCharacterAvatar(characterListPage.bookId, charPage.cid)
                                    charPage.hasAvatar = false
                                    characterListPage.refresh()
                                }
                            }
                        }
                    }

                    // Setting images gallery (original: add + long-press remove)
                    Column {
                        visible: charPage.cid !== ""
                        width: parent.width
                        spacing: Theme.paddingSmall

                        Label {
                            anchors {
                                left: parent.left
                                leftMargin: Theme.horizontalPageMargin
                            }
                            text: qsTr("设定图片（长按移除）")
                            color: AstnStyle.cTextSecondary
                            font.pixelSize: AstnStyle.typeCaption
                        }

                        Grid {
                            id: imageGrid
                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: Theme.horizontalPageMargin
                                rightMargin: Theme.horizontalPageMargin
                            }
                            columns: 3
                            spacing: 10

                            Repeater {
                                model: charPage.imageUris

                                Item {
                                    width: Math.floor((imageGrid.width - 2 * imageGrid.spacing) / 3)
                                    height: width

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: AstnStyle.radiusButton
                                        color: AstnStyle.cSurface
                                        border.color: AstnStyle.cSeparator
                                        border.width: 1
                                    }

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        source: modelData
                                        fillMode: Image.PreserveAspectCrop
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onPressAndHold: {
                                            store.removeCharacterImage(characterListPage.bookId,
                                                                       charPage.cid, index)
                                            characterListPage.refresh()
                                            charPage.reloadImages()
                                        }
                                    }
                                }
                            }

                            // Add-tile
                            Item {
                                width: Math.floor((imageGrid.width - 2 * imageGrid.spacing) / 3)
                                height: width

                                Rectangle {
                                    anchors.fill: parent
                                    radius: AstnStyle.radiusButton
                                    color: AstnStyle.cSurface
                                    border.color: AstnStyle.cSeparator
                                    border.width: 1

                                    Label {
                                        anchors.centerIn: parent
                                        text: "＋"
                                        color: AstnStyle.cTextSecondary
                                        font.pixelSize: 32
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        charPage.pickMode = "image"
                                        pageStack.push(imagePickerComp)
                                    }
                                }
                            }
                        }
                    }

                    // Structured fields (mirrors original character form)
                    Repeater {
                        model: charPage.charFields

                        Column {
                            width: parent.width
                            spacing: Theme.paddingSmall

                            Label {
                                anchors {
                                    left: parent.left
                                    leftMargin: Theme.horizontalPageMargin
                                }
                                text: modelData.label
                                color: AstnStyle.cTextSecondary
                                font.pixelSize: AstnStyle.typeCaption
                            }

                            TextField {
                                visible: !modelData.multi
                                width: parent.width
                                text: charPage.initialValues[modelData.key]
                                      ? charPage.initialValues[modelData.key] : ""
                                color: AstnStyle.cTextPrimary
                                placeholderText: modelData.key === "name"
                                                 ? qsTr("输入角色姓名（必填）") : modelData.label
                                onTextChanged: {
                                    var v = charPage.currentValues
                                    v[modelData.key] = text
                                    charPage.currentValues = v
                                    if (modelData.key === "name")
                                        charPage.nameInput = text
                                }
                            }

                            TextArea {
                                visible: modelData.multi
                                width: parent.width
                                height: 120
                                text: charPage.initialValues[modelData.key]
                                      ? charPage.initialValues[modelData.key] : ""
                                color: AstnStyle.cTextPrimary
                                label: modelData.label
                                placeholderText: qsTr("填写%1").arg(modelData.label)
                                onTextChanged: {
                                    var v = charPage.currentValues
                                    v[modelData.key] = text
                                    charPage.currentValues = v
                                }
                            }
                        }
                    }
                }
            }

            Component.onCompleted: {
                if (charPage.cid !== "") {
                    var items = characterListPage.characterItems
                    for (var i = 0; i < items.length; i++) {
                        if (items[i].id === charPage.cid) {
                            charPage.initialValues = items[i]
                            charPage.hasAvatar = items[i].avatarDataUri
                                                  ? items[i].avatarDataUri.length > 0 : false
                            break
                        }
                    }
                }
                charPage.reloadImages()
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
                    text: qsTr("角色")
                    color: AstnStyle.cTextPrimary
                    font.pixelSize: AstnStyle.typeTitle
                    font.weight: Font.Bold
                }
            }

            EmptyState {
                visible: characterItems.length === 0
                text: qsTr("暂无角色")
                hintText: qsTr("点击下方按钮添加角色")
            }

            Repeater {
                model: characterItems

                AstnCard {
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    x: Theme.horizontalPageMargin
                    showCover: false
                    showAvatar: true
                    avatarUri: modelData.avatarDataUri && modelData.avatarDataUri.length > 0
                               ? store.avatarThumbPath(bookId, modelData.id, 50) : ""
                    title: modelData.name && modelData.name.length > 0
                           ? modelData.name : qsTr("未命名角色")
                    subtitle: charSubtitle(modelData)
                    meta: AstnStyle.formatDate(modelData.createdAt)

                    onClicked: pageStack.push(characterDialog, { cid: modelData.id })
                }
            }

            // spacer keeps the last card clear of the pinned bottom button
            Item {
                width: parent.width
                height: 88
            }
        }
    }

    // Add-character button pinned to the bottom
    AppleButton {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
            bottomMargin: Theme.paddingLarge
        }
        text: qsTr("添加角色")
        onClicked: pageStack.push(characterDialog)
    }
}

// ExportDialog.qml — export options (mirrors original ExportView.ets:
// TXT / Markdown / ASTN format chips + user-chosen save location)
import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import "../styles"
import "../components"

Dialog {
    id: exportDialog

    property string bookId: ""
    property string bookTitle: ""
    property int formatIndex: 0        // 0 TXT, 1 Markdown, 2 ASTN
    property string exportDir: ""      // "" → default Documents
    property string resultMsg: ""

    canAccept: true

    // Dialog background (app palette)
    Rectangle {
        anchors.fill: parent
        color: AstnStyle.cBackground
        z: -1
    }

    // Folder picker for the save location (deferred Component — Pages must
    // not be instantiated as direct children of a Dialog). FolderPickerPage
    // is a plain Page exposing `selectedPath` (no selectedContent API).
    Component {
        id: folderPickerComp
        FolderPickerPage {
            onSelectedPathChanged: {
                if (selectedPath !== "")
                    exportDialog.exportDir = selectedPath
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

            // Header: cancel / title / close
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
                    onClicked: exportDialog.reject()
                }

                Label {
                    anchors.centerIn: parent
                    text: qsTr("导出书籍")
                    color: AstnStyle.cTextPrimary
                    font.pixelSize: AstnStyle.typeHeadline
                    font.weight: Font.Bold
                }

                TextButton {
                    visible: exportDialog.resultMsg !== ""
                    anchors {
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    text: qsTr("完成")
                    onClicked: exportDialog.accept()
                }
            }

            // Format selection (original: TXT / .md格式 / ASTN chips)
            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                Label {
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                    }
                    text: qsTr("选择导出格式")
                    color: AstnStyle.cTextSecondary
                    font.pixelSize: AstnStyle.typeBody
                    font.weight: Font.Medium
                }

                Row {
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: Theme.horizontalPageMargin
                    }
                    spacing: Theme.paddingSmall

                    Repeater {
                        model: [
                            { label: "TXT", hint: "" },
                            { label: "Markdown", hint: "" },
                            { label: "ASTN", hint: qsTr("AstNovel 编辑器原生格式，包含全部内容，可用于完整导入。") }
                        ]

                        Rectangle {
                            width: (parent.width - 2 * parent.spacing) / 3
                            height: 44
                            radius: AstnStyle.radiusButton
                            color: exportDialog.formatIndex === index ? AstnStyle.cPrimary : AstnStyle.cSurface
                            border.color: AstnStyle.cSeparator
                            border.width: 1

                            Label {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: exportDialog.formatIndex === index ? "#FFFFFF" : AstnStyle.cTextPrimary
                                font.pixelSize: AstnStyle.typeBody
                                font.weight: exportDialog.formatIndex === index ? Font.Bold : Font.Regular
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: exportDialog.formatIndex = index
                            }

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                    }
                }

                Label {
                    visible: exportDialog.formatIndex === 2
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: Theme.horizontalPageMargin
                    }
                    text: qsTr("AstNovel 编辑器原生格式，包含全部内容，可用于完整导入。")
                    color: AstnStyle.cTextSecondary
                    font.pixelSize: AstnStyle.typeCaption
                    wrapMode: Text.WordWrap
                }
            }

            // Save location (original: system save dialog; here: folder picker)
            Column {
                width: parent.width
                spacing: Theme.paddingSmall

                Label {
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                    }
                    text: qsTr("保存位置")
                    color: AstnStyle.cTextSecondary
                    font.pixelSize: AstnStyle.typeBody
                    font.weight: Font.Medium
                }

                Rectangle {
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    x: Theme.horizontalPageMargin
                    height: 56
                    radius: AstnStyle.radiusButton
                    color: AstnStyle.cSurface
                    border.color: AstnStyle.cSeparator
                    border.width: 1

                    Label {
                        anchors {
                            left: parent.left
                            right: locationBtn.left
                            leftMargin: Theme.paddingLarge
                            rightMargin: Theme.paddingSmall
                            verticalCenter: parent.verticalCenter
                        }
                        text: exportDialog.exportDir === ""
                              ? qsTr("默认：文档 (Documents)")
                              : exportDialog.exportDir.replace("file://", "")
                        color: AstnStyle.cTextPrimary
                        font.pixelSize: AstnStyle.typeCaption
                        maximumLineCount: 2
                        elide: Text.ElideMiddle
                    }

                    TextButton {
                        id: locationBtn
                        anchors {
                            right: parent.right
                            rightMargin: Theme.paddingSmall
                            verticalCenter: parent.verticalCenter
                        }
                        text: qsTr("选择位置")
                        onClicked: pageStack.push(folderPickerComp)
                    }
                }
            }

            // Run export
            AppleButton {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                text: qsTr("开始导出")
                onClicked: {
                    var fmt = exportDialog.formatIndex === 2 ? "astn"
                            : (exportDialog.formatIndex === 1 ? "md" : "txt")
                    var p = store.exportBookAs(exportDialog.bookId, fmt, exportDialog.exportDir)
                    exportDialog.resultMsg = p !== "" ? qsTr("已导出到 ") + p : qsTr("导出失败")
                }
            }

            Label {
                visible: exportDialog.resultMsg !== ""
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                text: exportDialog.resultMsg
                color: exportDialog.resultMsg.indexOf(qsTr("已导出")) === 0
                       ? AstnStyle.cPrimary : AstnStyle.cDanger
                font.pixelSize: AstnStyle.typeCaption
                wrapMode: Text.WordWrap
            }
        }
    }
}

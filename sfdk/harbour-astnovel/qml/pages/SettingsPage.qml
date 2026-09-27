// SettingsPage.qml — appearance + about, fully app-palette driven
import QtQuick 2.2
import Sailfish.Silica 1.0
import "../styles"
import "../components"

Page {
    id: settingsPage

    allowedOrientations: Orientation.All

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
                    text: qsTr("设置")
                    color: AstnStyle.cTextPrimary
                    font.pixelSize: AstnStyle.typeTitle
                    font.weight: Font.Bold
                }
            }

            // Appearance group card
            Column {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                spacing: 0

                Label {
                    width: parent.width
                    text: qsTr("外观")
                    color: AstnStyle.cTextTertiary
                    font.pixelSize: AstnStyle.typeCaption
                    font.letterSpacing: 1.0
                }

                Rectangle {
                    width: parent.width
                    height: 56
                    radius: AstnStyle.radiusButton
                    color: AstnStyle.cSurface

                    Label {
                        anchors {
                            left: parent.left
                            leftMargin: Theme.paddingLarge
                            verticalCenter: parent.verticalCenter
                        }
                        text: qsTr("深色模式")
                        color: AstnStyle.cTextPrimary
                        font.pixelSize: AstnStyle.typeBody
                    }

                    // iOS-style toggle
                    Rectangle {
                        id: toggle
                        anchors {
                            right: parent.right
                            rightMargin: Theme.paddingLarge
                            verticalCenter: parent.verticalCenter
                        }
                        width: 51
                        height: 31
                        radius: 15.5
                        color: AstnStyle.isDarkMode ? "#34C759" : "#E9E9EA"

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: AstnStyle.isDarkMode ? parent.width - width - 2 : 2
                            width: 27
                            height: 27
                            radius: 13.5
                            color: "#FFFFFF"

                            Behavior on x {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: AstnStyle.isDarkMode = !AstnStyle.isDarkMode
                        }

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }
                }
            }

            // Language group card
            Column {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                spacing: Theme.paddingSmall

                Label {
                    width: parent.width
                    text: qsTr("语言")
                    color: AstnStyle.cTextTertiary
                    font.pixelSize: AstnStyle.typeCaption
                    font.letterSpacing: 1.0
                }

                Rectangle {
                    width: parent.width
                    radius: AstnStyle.radiusCard
                    color: AstnStyle.cSurface

                    Column {
                        width: parent.width

                        Repeater {
                            model: [
                                { key: "",   name: qsTr("跟随系统") },
                                { key: "zh", name: "简体中文" },
                                { key: "en", name: "English" },
                                { key: "de", name: "Deutsch" },
                                { key: "ru", name: "Русский" },
                                { key: "fi", name: "Suomi" }
                            ]

                            delegate: Item {
                                width: parent.width
                                height: 52

                                Label {
                                    anchors {
                                        left: parent.left
                                        leftMargin: Theme.paddingLarge
                                        verticalCenter: parent.verticalCenter
                                    }
                                    text: modelData.name
                                    color: AstnStyle.cTextPrimary
                                    font.pixelSize: AstnStyle.typeBody
                                }

                                Image {
                                    anchors {
                                        right: parent.right
                                        rightMargin: Theme.paddingLarge
                                        verticalCenter: parent.verticalCenter
                                    }
                                    source: "image://theme/icon-m-acknowledge"
                                    visible: store.uiLanguage() === modelData.key
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: store.setUiLanguage(modelData.key)
                                }
                            }
                        }
                    }
                }

                Label {
                    width: parent.width
                    text: qsTr("重启应用后生效")
                    visible: store.uiLanguage() !== uiLangApplied
                    color: AstnStyle.cPrimary
                    font.pixelSize: AstnStyle.typeCaption
                }
            }

            // About group card
            Column {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                spacing: Theme.paddingSmall

                Label {
                    width: parent.width
                    text: qsTr("关于")
                    color: AstnStyle.cTextTertiary
                    font.pixelSize: AstnStyle.typeCaption
                    font.letterSpacing: 1.0
                }

                Rectangle {
                    width: parent.width
                    height: 100
                    radius: AstnStyle.radiusCard
                    color: AstnStyle.cSurface

                    Column {
                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: Theme.paddingLarge
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 4

                        Label {
                            text: "NovelSpace"
                            color: AstnStyle.cTextPrimary
                            font.pixelSize: AstnStyle.typeHeadline
                            font.weight: Font.Medium
                        }
                        Label {
                            text: qsTr("AstNovel for Sailfish OS · 版本 4.50.Ast.3")
                            color: AstnStyle.cTextSecondary
                            font.pixelSize: AstnStyle.typeCaption
                        }
                    }
                }
            }
        }
    }
}

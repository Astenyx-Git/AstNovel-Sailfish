import QtQuick 2.15
import Sailfish.Silica 1.0

Component {
    id: chapterItemComponent

    ListItem {
        id: chapterItem

        width: parent ? parent.width : Theme.itemSizeLarge

        contentHeight: Theme.itemSizeSmall

        // Background
        background: Rectangle {
            color: Theme.themeSurface
            radius: Theme.cornerRadiusButton
        }

        // Drag handle
        Label {
            anchors {
                left: parent.left
                leftMargin: Theme.paddingSmall
                verticalCenter: parent.verticalCenter
            }
            color: Theme.themeTextTertiary
            font.pixelSize: 20
            text: "≡"
        }

        // Chapter info
        Column {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Theme.paddingLarge
                rightMargin: Theme.paddingLarge
                verticalCenter: parent.verticalCenter
            }

            Label {
                color: Theme.themeTextPrimary
                font.pixelSize: Theme.typography.headlineSize
                font.bold: true
                text: title
                truncationMode: TruncationMode.Fade
                maximumLineCount: 1
            }

            Row {
                spacing: Theme.paddingSmall

                Label {
                    color: Theme.themeTextSecondary
                    font.pixelSize: Theme.typography.captionSize
                    text: qsTr("%1字").arg(content.length)
                }

                Label {
                    color: Theme.themeTextTertiary
                    font.pixelSize: Theme.typography.captionSize
                    text: DesignSystem.formatDetailedTime(createdAt)
                }
            }
        }

        // Mouse area for press effect
        MouseArea {
            anchors.fill: parent
            preventStealing: true
            onClicked: {
                chapterItemComponent.trigger();
            }
            onPressed: {
                chapterItem.scale = AnimationSystem.scalePress
            }
            onReleased: {
                chapterItem.scale = 1.0
            }
        }
    }
}

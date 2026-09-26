import QtQuick 2.15
import Sailfish.Silica 1.0

Component {
    id: worldSettingCardComponent

    Card {
        id: worldSettingCard

        width: parent ? parent.width : Theme.itemSizeLarge
        height: Theme.itemSizeLarge

        // Background color
        color: Theme.themeSurface

        // Shadow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadowCardColor
            shadowBlur: Theme.shadowCardRadius / 8
            shadowOffsetY: Theme.shadowCardOffsetY
        }

        // Title
        Label {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Theme.paddingMedium
                rightMargin: Theme.paddingMedium
                top: parent.top
                topMargin: Theme.paddingMedium
            }
            color: Theme.themeTextPrimary
            font.pixelSize: Theme.typography.headlineSize
            font.bold: true
            text: title
            truncationMode: TruncationMode.Fade
            maximumLineCount: 1
        }

        // Category
        Label {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Theme.paddingMedium
                rightMargin: Theme.paddingMedium
                top: worldSettingCard.bottom
                topMargin: Theme.paddingSmall
            }
            color: Theme.themeTextSecondary
            font.pixelSize: Theme.typography.captionSize
            text: category
            truncationMode: TruncationMode.Fade
            maximumLineCount: 1
        }

        // Created date
        Label {
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
            color: Theme.themeTextTertiary
            font.pixelSize: Theme.typography.captionSize
            text: DesignSystem.formatTime(createdAt)
        }

        // Mouse area for press effect
        MouseArea {
            anchors.fill: parent
            preventStealing: true
            onClicked: {
                worldSettingCardComponent.trigger();
            }
            onPressed: {
                worldSettingCard.scale = AnimationSystem.scalePress
            }
            onReleased: {
                worldSettingCard.scale = 1.0
            }
        }
    }
}

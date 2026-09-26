import QtQuick 2.15
import Sailfish.Silica 1.0

Component {
    id: characterCardComponent

    Card {
        id: characterCard

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

        // Name
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
            text: name
            truncationMode: TruncationMode.Fade
            maximumLineCount: 1
        }

        // Description
        Label {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Theme.paddingMedium
                rightMargin: Theme.paddingMedium
                top: characterCard.bottom
                topMargin: Theme.paddingSmall
            }
            color: Theme.themeTextSecondary
            font.pixelSize: Theme.typography.captionSize
            text: description
            truncationMode: TruncationMode.Fade
            maximumLineCount: 2
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
                characterCardComponent.trigger();
            }
            onPressed: {
                characterCard.scale = AnimationSystem.scalePress
            }
            onReleased: {
                characterCard.scale = 1.0
            }
        }
    }
}

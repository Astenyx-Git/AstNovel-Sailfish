import QtQuick 2.15
import Sailfish.Silica 1.0

Component {
    id: bookCardComponent

    Card {
        id: bookCard

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

        // Cover section
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            radius: Theme.cornerRadiusCard

            // Gradient background (if no cover image)
            Gradient {
                id: coverGradient
                GradientStop { position: 0.0; color: DesignSystem.getGradient(title)[0] }
                GradientStop { position: 1.0; color: DesignSystem.getGradient(title)[1] }
            }

            // Cover image or gradient
            Rectangle {
                anchors.fill: parent
                color: "transparent"

                Image {
                    id: coverImage
                    anchors.fill: parent
                    source: coverDataUri
                    fillMode: Image.PreserveAspectCrop
                    visible: source.toString() !== ""
                    layer.effect: MultiEffect {
                        brightness: 0.8
                    }
                }

                // Placeholder text if no cover
                Label {
                    anchors.centerIn: parent
                    color: Theme.themeTextPrimary
                    font.pixelSize: 36
                    font.bold: true
                    text: DesignSystem.getFirstChar(title)
                    visible: !coverImage.visible
                }
            }

            // Title overlay
            Rectangle {
                anchors.fill: parent
                color: Theme.shadowCardColor
                opacity: 0.7

                Label {
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: Theme.paddingMedium
                        rightMargin: Theme.paddingMedium
                        bottom: parent.bottom
                    }
                    color: Theme.themeTextPrimary
                    font.pixelSize: Theme.typography.headlineSize
                    font.bold: true
                    text: title
                    truncationMode: TruncationMode.Fade
                    maximumLineCount: 2
                }
            }

            // Description overlay
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
                font.pixelSize: Theme.typography.captionSize
                text: description
                truncationMode: TruncationMode.Fade
                maximumLineCount: 2
            }

            // Last updated badge
            Label {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }
                color: Theme.themeTextPrimary
                font.pixelSize: Theme.typography.captionSize
                text: DesignSystem.formatTime(updatedAt)
            }
        }

        // Mouse area for press effect
        MouseArea {
            anchors.fill: parent
            preventStealing: true
            onClicked: {
                bookCardComponent.trigger();
            }
            onPressed: {
                bookCard.scale = AnimationSystem.scalePress
            }
            onReleased: {
                bookCard.scale = 1.0
            }
        }
    }
}

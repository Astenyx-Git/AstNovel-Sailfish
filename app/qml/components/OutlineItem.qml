import QtQuick 2.15
import Sailfish.Silica 1.0

Component {
    id: outlineItemComponent

    ListItem {
        id: outlineItem

        width: parent ? parent.width : Theme.itemSizeLarge

        contentHeight: Theme.itemSizeSmall

        // Title
        Label {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Theme.paddingLarge
                rightMargin: Theme.paddingLarge
                verticalCenter: parent.verticalCenter
            }
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeMedium
            text: title
            truncationMode: TruncationMode.Fade
            maximumLineCount: 1
        }

        // Created date
        Label {
            anchors {
                right: parent.right
                bottom: parent.bottom
            }
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeTiny
            text: Qt.formatDateTime(new Date(createdAt), "MMM dd, yyyy")
        }

        onClicked: {
            outlineItemComponent.trigger();
        }
    }
}

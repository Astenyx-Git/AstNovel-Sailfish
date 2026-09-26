// PageTitle.qml — iOS large title (34px bold, TypographyTokens.LARGE_TITLE)
import QtQuick 2.2
import Sailfish.Silica 1.0
import "../styles"

Item {
    id: root

    width: parent ? parent.width : 0
    height: 56

    property string text: ""

    Label {
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
            bottom: parent.bottom
            bottomMargin: Theme.paddingSmall
        }
        text: root.text
        color: AstnStyle.cTextPrimary
        font.pixelSize: 34
        font.weight: Font.Bold
        maximumLineCount: 1
        elide: Text.ElideRight
    }
}

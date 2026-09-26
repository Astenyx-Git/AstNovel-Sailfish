// EmptyState.qml — centered empty-list placeholder
import QtQuick 2.2
import Sailfish.Silica 1.0
import "../styles"

Column {
    id: root

    width: parent ? parent.width : 0
    spacing: Theme.paddingSmall

    property string text: ""
    property string hintText: ""

    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.text
        color: AstnStyle.cTextSecondary
        font.pixelSize: 20
        font.weight: Font.Medium
    }

    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.hintText
        color: AstnStyle.cTextTertiary
        font.pixelSize: AstnStyle.typeBody
    }
}

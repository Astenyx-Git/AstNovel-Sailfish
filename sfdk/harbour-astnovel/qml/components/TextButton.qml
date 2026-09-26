// TextButton.qml — borderless text action (Apple blue by default)
import QtQuick 2.2
import Sailfish.Silica 1.0
import "../styles"

Item {
    id: btn

    width: label.implicitWidth + 2 * Theme.paddingMedium
    height: 44

    property string text: ""
    property color textColor: AstnStyle.cPrimary
    property int textPixelSize: AstnStyle.typeBody

    signal clicked()

    Label {
        id: label
        anchors.centerIn: parent
        text: btn.text
        color: btn.textColor
        font.pixelSize: btn.textPixelSize
        font.weight: Font.Medium
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        onClicked: btn.clicked()
    }

    opacity: ma.pressed ? 0.5 : 1.0
    Behavior on opacity {
        NumberAnimation { duration: AstnStyle.durationPress }
    }
}

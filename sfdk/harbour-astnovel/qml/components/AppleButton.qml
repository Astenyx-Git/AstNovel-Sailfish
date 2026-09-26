// AppleButton.qml — solid Apple-style button (primary/danger), ambience-independent
import QtQuick 2.2
import Sailfish.Silica 1.0
import "../styles"

Rectangle {
    id: btn

    width: parent ? parent.width : 0
    height: customHeight > 0 ? customHeight : 50
    radius: AstnStyle.radiusButton
    color: variant === "danger" ? AstnStyle.cDanger
         : (variant === "secondary" ? AstnStyle.cSurface : AstnStyle.cPrimary)
    border.color: variant === "secondary" ? AstnStyle.cSeparator : "transparent"
    border.width: variant === "secondary" ? 1 : 0

    property string text: ""
    property string variant: "primary"
    property real customHeight: 0

    signal clicked()

    Label {
        anchors.centerIn: parent
        text: btn.text
        color: btn.variant === "secondary" ? AstnStyle.cTextPrimary : "#FFFFFF"
        font.pixelSize: AstnStyle.typeBody
        font.weight: Font.Medium
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        onClicked: btn.clicked()
    }

    // Press feedback (AnimationTokens: 160ms, scale 0.97)
    scale: ma.pressed ? AstnStyle.scalePress : 1.0
    Behavior on scale {
        NumberAnimation { duration: AstnStyle.durationPress; easing.type: Easing.OutCubic }
    }
    opacity: ma.pressed ? 0.85 : 1.0
    Behavior on opacity {
        NumberAnimation { duration: AstnStyle.durationPress }
    }
}

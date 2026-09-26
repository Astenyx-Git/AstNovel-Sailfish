import QtQuick 2.15
import Sailfish.Silica 1.0

TextField {
    id: textField
    width: parent.width
    color: Theme.primaryColor
    font.pixelSize: Theme.fontSizeMedium
    placeholderTextColor: Theme.secondaryColor
    placeholderText: ""
    label: ""
    errorHighlight: false
    EnterKey.enabled: true
    EnterKey.iconSource: "image://theme/icon-m-enter"
    EnterKey.onClicked: {
        focus = false;
        onAccepted();
    }

    signal onAccepted()
}

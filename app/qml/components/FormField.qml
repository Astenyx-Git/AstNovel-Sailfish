import QtQuick 2.15
import Sailfish.Silica 1.0

Column {
    id: formField

    width: parent.width
    spacing: Theme.paddingSmall

    property string label: ""
    property string placeholder: ""
    property string text: ""
    property string value: ""
    property bool required: false

    Label {
        width: parent.width
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeSmall
        text: label + (required ? " *" : "")
    }

    TextField {
        id: textField
        width: parent.width
        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeMedium
        placeholderTextColor: Theme.secondaryColor
        placeholderText: placeholder
        text: value
        EnterKey.enabled: true
        EnterKey.iconSource: "image://theme/icon-m-enter"
        EnterKey.onClicked: {
            focus = false;
        }

        onAccepted: {
            value = text;
        }
    }
}

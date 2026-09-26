import QtQuick 2.15
import Sailfish.Silica 1.0

Rectangle {
    id: glassPanel

    width: parent.width
    height: 120
    color: Theme.rgba(Theme.highlightBackgroundColor, 0.7)
    radius: Theme.paddingMedium

    border {
        width: 1
        color: Theme.rgba(Theme.highlightColor, 0.3)
    }

    // Glass effect
    layer.enabled: true
    layer.effect: MultiEffect {
        blurEnabled: true
        blur: 0.1
    }
}

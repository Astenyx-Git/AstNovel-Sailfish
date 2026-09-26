import QtQuick 2.15
import Sailfish.Silica 1.0

Button {
    id: holdConfirmButton

    property bool isHeld: false
    property int holdDuration: 1000  // milliseconds

    signal triggered()

    // Prevent normal click
    MouseArea {
        anchors.fill: parent
        onPressed: {
            isHeld = true;
            pressTimer.start();
        }
        onReleased: {
            if (isHeld) {
                pressTimer.stop();
                isHeld = false;
            }
        }
        onClicked: {
            if (!isHeld) {
                // Normal click behavior
                isHeld = false;
                pressTimer.stop();
                triggered();
            }
        }
    }

    Timer {
        id: pressTimer
        interval: holdDuration
        repeat: false
        onTriggered: {
            if (isHeld) {
                isHeld = false;
                triggered();
            }
        }
    }
}

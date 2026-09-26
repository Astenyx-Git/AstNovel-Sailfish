import QtQuick 2.15
import Sailfish.Silica 1.0

Item {
    id: toast

    width: parent ? parent.width : 600
    height: 60

    property string message: ""

    function show(msg) {
        message = msg;
        visible = true;
        animation.start();
    }

    function hide() {
        visible = false;
    }

    Rectangle {
        id: toastRect
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.paddingLarge, toast.message.length * 10 + 100)
        height: 60
        color: Theme.themePrimary
        radius: Theme.cornerRadiusButton

        // Shadow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadowCardColor
            shadowBlur: 4
            shadowOffsetY: 2
        }

        Label {
            anchors {
                centerIn: parent
            }
            color: Theme.themeSurface
            font.pixelSize: Theme.typography.bodySize
            text: toast.message
        }

        SequentialAnimation {
            id: animation
            NumberAnimation {
                to: 1.0
                duration: AnimationSystem.durationPress
                property: "opacity"
                easing.type: Easing.OutCubic
            }
            ParallelAnimation {
                NumberAnimation {
                    to: 200
                    duration: AnimationSystem.durationPress
                    property: "y"
                    easing.type: Easing.OutCubic
                }
            }
            NumberAnimation {
                to: 0
                duration: AnimationSystem.durationPress
                property: "opacity"
            }
            ScriptAction {
                script: {
                    toast.hide();
                    animation.stop();
                }
            }
        }
    }
}

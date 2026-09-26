// main.qml — ApplicationWindow entry (official Sailfish template structure)
import QtQuick 2.2
import Sailfish.Silica 1.0
import "pages"

ApplicationWindow {
    initialPage: Component { BookShelfPage { } }

    // One-shot GaussianBlur capability probe (dynamic: plugin-missing or slow
    // renderers simply keep liveBlurOk = false and the app uses the snapshot)
    Loader {
        active: true
        source: Qt.resolvedUrl("components/BlurProbe.qml")
        onStatusChanged: {
            if (status === Loader.Error)
                AstnStyle.liveBlurOk = false
        }
        onLoaded: item.runProbe()
    }

    // Sailfish app cover (minimized-app tile): icon lifted above center
    cover: Component {
        CoverBackground {
            Image {
                id: coverIcon
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: -Theme.paddingMedium
                }
                source: "image://theme/harbour-astnovel"
                width: parent.width * 0.5
                height: width
                fillMode: Image.PreserveAspectFit
            }

            Label {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: coverIcon.bottom
                    topMargin: Theme.paddingMedium
                }
                text: "NovelSpace"
                color: "#FFFFFF"
                font.pixelSize: 16
            }
        }
    }
}

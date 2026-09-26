// main.qml — ApplicationWindow entry (official Sailfish template structure)
import QtQuick 2.2
import Sailfish.Silica 1.0
import "pages"
import "styles"

ApplicationWindow {
    id: windowRoot

    initialPage: Component { BookShelfPage { } }

    // Cover thumbnail state: newest grabbed frame, saved to a real file so
    // the cover window (a separate QQuickWindow, no itemgrabber provider)
    // can load it. Two alternating paths defeat Image caching.
    property bool _thumbFlip: false
    property string coverThumbUrl: ""

    function captureCoverThumb() {
        var page = pageStack.currentPage
        if (!page)
            return
        var cb = function(result) {
            if (!result)
                return   // grab failed (e.g. window already hidden): keep old frame
            windowRoot._thumbFlip = !windowRoot._thumbFlip
            var p = store.saveCoverFrame(result.image,
                                         windowRoot._thumbFlip ? "cover_a.png" : "cover_b.png")
            if (p !== "")
                windowRoot.coverThumbUrl = "file://" + p
        }
        page.grabToImage(cb)
    }

    // Re-capture shortly after each navigation (transition settled)
    Connections {
        target: pageStack
        onCurrentPageChanged: coverGrabTimer.restart()
    }

    Timer {
        id: coverGrabTimer
        interval: 420
        onTriggered: windowRoot.captureCoverThumb()
    }

    // First capture shortly after startup so the cover has content
    // even if the app is backgrounded immediately
    Timer {
        interval: 1200
        running: true
        onTriggered: windowRoot.captureCoverThumb()
    }

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

    // Sailfish app cover (minimized-app tile):
    //   live path  - a grabToImage thumbnail of the current page, re-captured
    //                on navigation while the app is in the foreground; the
    //                tile then shows the state at backgrounding time
    //   fallback   - the app's solid background colour filling the whole
    //                card, with icon + name, whenever no frame is available
    cover: Component {
        CoverBackground {
            // Fallback base: solid UI background across the entire card
            Rectangle {
                anchors.fill: parent
                color: AstnStyle.cBackground
            }

            // Fallback content: icon + name (hidden while a frame is shown)
            Image {
                id: coverIcon
                visible: !coverThumb.visible
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
                visible: !coverThumb.visible
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: coverIcon.bottom
                    topMargin: Theme.paddingMedium
                }
                text: "NovelSpace"
                color: AstnStyle.cTextPrimary
                font.pixelSize: 16
            }

            // Live path: newest captured frame of the current page
            Image {
                id: coverThumb
                anchors.fill: parent
                source: windowRoot.coverThumbUrl
                visible: source !== "" && status === Image.Ready
                fillMode: Image.Stretch
                cache: false
            }

            // Freshen the frame when the app is being covered (best effort:
            // if the window no longer renders, the previous frame persists)
            onStatusChanged: {
                if (status === Cover.Activating)
                    windowRoot.captureCoverThumb()
            }
        }
    }
}

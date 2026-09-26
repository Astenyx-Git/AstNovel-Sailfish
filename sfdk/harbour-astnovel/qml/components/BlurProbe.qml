// BlurProbe.qml — one-shot GaussianBlur capability probe (dynamic component so a
// missing QtGraphicalEffects plugin only fails here, never the whole page)
import QtQuick 2.2
import QtGraphicalEffects 1.0
import "../styles"

Item {
    id: probeRoot

    width: 300
    height: 300
    // Visible but buried under every page: grabToImage must actually render
    // the item, and fully invisible items may never deliver in Qt 5.6
    visible: true
    opacity: 0.01
    z: -999

    property int runCount: 0
    // Mirror of the real panel workload: ~360x380 region, radius 24, 16 samples
    readonly property int probeRadius: 24

    Timer {
        id: giveUpTimer
        interval: 3000
        onTriggered: {
            if (!AstnStyle.liveBlurOk && probeRoot.runCount < 2)
                console.warn("[astn] blur probe: no result in 3s, snapshot fallback stays")
        }
    }

    Rectangle {
        id: probeSource
        anchors.fill: parent
        color: "#3366CC"

        Text {
            width: parent.width
            text: "速查面板毛玻璃性能探测文本"
            color: "#FFFFFF"
            font.pixelSize: 20
            wrapMode: Text.WordWrap
        }
    }

    GaussianBlur {
        anchors.fill: parent
        source: probeSource
        radius: probeRoot.probeRadius
        samples: 16
        cached: false
    }

    Timer {
        id: rerunTimer
        interval: 60
        onTriggered: probeRoot.runOnce()
    }

    Timer {
        id: attachTimer
        interval: 120
        onTriggered: probeRoot.runProbe()
    }

    function runProbe() {
        runCount = 0
        giveUpTimer.restart()
        runOnce()
    }

    function runOnce() {
        var t0 = Date.now()
        var res = probeRoot.grabToImage(function(result) {
            var dt = Date.now() - t0
            probeRoot.runCount++
            if (probeRoot.runCount === 1) {
                rerunTimer.restart()   // first pass warms up shaders; measure the second
            } else {
                // Threshold: only "severely insufficient" falls back to the snapshot
                AstnStyle.liveBlurOk = dt < 400
                console.warn("[astn] blur probe: " + dt + " ms -> live blur " +
                             (AstnStyle.liveBlurOk ? "enabled" : "disabled"))
            }
        })
        // Qt 5.6 has no Item.window: grabToImage returns null when unattached
        if (!res)
            attachTimer.restart()
    }
}

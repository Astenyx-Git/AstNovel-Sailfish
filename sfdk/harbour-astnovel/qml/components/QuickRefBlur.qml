// QuickRefBlur.qml — live GaussianBlur backdrop for the quick-reference sheet.
// Loaded dynamically: a missing QtGraphicalEffects plugin fails this file only,
// and the sheet falls back to the static snapshot backdrop.
import QtQuick 2.2
import QtGraphicalEffects 1.0

Item {
    id: blurRoot

    property var sourceItem: null        // the editor TextArea behind the panel
    property real blurRadius: 24

    ShaderEffectSource {
        id: effectSource
        anchors.fill: parent
        sourceItem: blurRoot.sourceItem
        // sample only the source slice hidden behind the panel (no recursion)
        sourceRect: Qt.rect(
            0,
            blurRoot.sourceItem
                ? Math.max(0, blurRoot.sourceItem.height - blurRoot.height) : 0,
            blurRoot.width,
            blurRoot.height)
        textureSize: Qt.size(blurRoot.width / 2, blurRoot.height / 2)  // half-res: faster + softer
        smooth: true
        live: true
        recursive: false
    }

    GaussianBlur {
        anchors.fill: parent
        source: effectSource
        radius: blurRoot.blurRadius
        samples: 16
        cached: true   // recompute only when the source changes (e.g. caret blink)
    }
}

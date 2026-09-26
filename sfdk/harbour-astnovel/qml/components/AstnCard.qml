// AstnCard.qml — Apple-style card (mirrors BookCard.ets proportions)
// Corner trick: cover is rounded on ALL corners but extends `radius` px below
// the visible cover line; the info area sits on the surface-colored body and
// hides the bottom arcs — giving top-rounded/square-bottom exactly like the
// original, with no shader effects (Qt 5.6 safe).
import QtQuick 2.2
import Sailfish.Silica 1.0
import "../styles"

Item {
    id: root

    width: parent ? parent.width : 0
    height: coverHeight + infoTopPad + (infoCol.height > 0 ? infoCol.height : 0) + infoVPad

    property string title: ""
    property string subtitle: ""
    property string meta: ""
    property bool showCover: false
    property string coverUri: ""
    property string avatarUri: ""
    property bool showAvatar: false       // circular avatar row (CharacterCardView)
    property real coverRatio: 0.45         // cover proportion (user-tuned down from 0.6)
    property real coverHeight: showCover ? Math.round(width * coverRatio) : 0
    property real infoVPad: 10             // BookCard.ets padding top/bottom
    property real infoTopPad: 14           // breathing room between cover and title
    property real infoHPad: 12             // BookCard.ets padding left/right

    signal clicked()
    signal hold()                          // mirrors original LongPressGesture

    // Cover gradient selection (same hash as original)
    readonly property int gradientIdx: AstnStyle.gradientIndex(root.title)
    readonly property string coverTopColor: AstnStyle.coverGradients[gradientIdx][0]
    readonly property string coverBottomColor: AstnStyle.coverGradients[gradientIdx][1]

    // Card body (surface)
    // (The original's subtle shadow is fully occluded by the opaque body on
    // this flat design — skipped to keep one blend layer less per card.)
    Rectangle {
        id: cardBody
        anchors.fill: parent
        radius: AstnStyle.radiusCard
        color: AstnStyle.cSurface
    }

    // Info area backing: hides the cover's hidden bottom-radius strip
    // (drawn above the cover, below the labels; bottom rounding matches card)
    Rectangle {
        anchors {
            top: parent.top
            topMargin: root.coverHeight
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        radius: AstnStyle.radiusCard
        color: AstnStyle.cSurface
        visible: root.showCover && root.coverHeight > 0
    }

    // Cover — rounded rect extending below the visible line by `radius`
    // (bottom arcs are hidden by the info section below). The gradient is
    // pre-baked by C++ into a rounded PNG and drawn as a plain texture —
    // per-frame Gradient materials are too slow on software rendering.
    Rectangle {
        id: cover
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: root.coverHeight + AstnStyle.radiusCard
        radius: AstnStyle.radiusCard
        visible: root.showCover
        color: root.coverTopColor

        // Baked gradient texture
        Image {
            anchors.fill: parent
            visible: root.coverUri === "" && root.coverHeight > 0
            source: root.coverUri === "" && root.coverHeight > 0
                    ? store.gradientCoverPath(root.gradientIdx, cover.width, cover.height,
                                              AstnStyle.radiusCard,
                                              root.coverTopColor, root.coverBottomColor)
                    : ""
            fillMode: Image.Stretch
        }

        // First-character placeholder (original: 36px white bold)
        Label {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -AstnStyle.radiusCard / 2
            visible: root.coverUri === ""
            text: AstnStyle.firstChar(root.title)
            color: "#FFFFFF"
            font.pixelSize: 36
            font.weight: Font.Bold
        }

        // Custom cover image
        Image {
            anchors.fill: parent
            visible: root.coverUri !== ""
            source: root.coverUri
            fillMode: Image.PreserveAspectCrop
        }
    }

    // Circular avatar (original CharacterCardView: 50px, dataUri or gradient+char)
    Item {
        visible: root.showAvatar
        anchors {
            left: parent.left
            leftMargin: root.infoHPad
            top: parent.top
            topMargin: root.coverHeight + root.infoTopPad
        }
        width: 50
        height: 50

        Image {
            anchors.fill: parent
            visible: root.avatarUri !== ""
            source: root.avatarUri
        }

        Image {
            anchors.fill: parent
            visible: root.avatarUri === ""
            source: store.gradientCoverPath(root.gradientIdx, 50, 50, 25,
                                            root.coverTopColor, root.coverBottomColor)
        }

        Label {
            anchors.centerIn: parent
            visible: root.avatarUri === ""
            text: AstnStyle.firstChar(root.title)
            color: "#FFFFFF"
            font.pixelSize: 24
            font.weight: Font.Bold
        }
    }

    // Info section (overlaps cover's hidden bottom arcs)
    Column {
        id: infoCol
        anchors {
            top: parent.top
            topMargin: root.coverHeight + root.infoTopPad
            left: parent.left
            right: parent.right
            leftMargin: root.infoHPad + (root.showAvatar ? 62 : 0)
            rightMargin: root.infoHPad
        }
        spacing: 4

        Label {
            width: parent.width
            text: root.title
            color: AstnStyle.cTextPrimary
            font.pixelSize: AstnStyle.typeHeadline
            font.weight: Font.Medium
            maximumLineCount: 1
            elide: Text.ElideRight
            visible: root.title !== ""
        }

        Label {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            color: AstnStyle.cTextSecondary
            font.pixelSize: AstnStyle.typeCaption
            maximumLineCount: 1
            elide: Text.ElideRight
        }

        Label {
            width: parent.width
            visible: root.meta !== ""
            text: root.meta
            color: AstnStyle.cTextTertiary
            font.pixelSize: AstnStyle.typeCaption
            maximumLineCount: 1
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: root.clicked()
        onPressAndHold: root.hold()
    }

    // Press feedback (AnimationTokens: 160ms, scale 0.97, ease-out)
    scale: mouseArea.pressed ? AstnStyle.scalePress : 1.0
    Behavior on scale {
        NumberAnimation { duration: AstnStyle.durationPress; easing.type: Easing.OutCubic }
    }
}

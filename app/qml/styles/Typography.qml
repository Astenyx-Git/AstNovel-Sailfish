// Typography.qml - Apple-style typography tokens
// Based on original HarmonyOS TypographyTokens.ets

pragma Singleton

QtObject {
    // Large Title
    readonly property int largeTitleSize: 34
    readonly property int largeTitleWeight: Font.Bold
    readonly property real largeTitleLetterSpacing: -0.02
    readonly property int largeTitleLineHeight: 36

    // Title 1
    readonly property int title1Size: 28
    readonly property int title1Weight: Font.Bold
    readonly property real title1LetterSpacing: -0.02
    readonly property int title1LineHeight: 31

    // Title 2
    readonly property int title2Size: 22
    readonly property int title2Weight: Font.Bold
    readonly property real title2LetterSpacing: -0.01
    readonly property int title2LineHeight: 25

    // Title 3
    readonly property int title3Size: 20
    readonly property int title3Weight: Font.Medium
    readonly property real title3LetterSpacing: 0
    readonly property int title3LineHeight: 24

    // Headline
    readonly property int headlineSize: 17
    readonly property int headlineWeight: Font.Medium
    readonly property real headlineLetterSpacing: 0
    readonly property int headlineLineHeight: 22

    // Body
    readonly property int bodySize: 17
    readonly property int bodyWeight: Font.Regular
    readonly property real bodyLetterSpacing: 0
    readonly property int bodyLineHeight: 26

    // Callout
    readonly property int calloutSize: 16
    readonly property int calloutWeight: Font.Regular
    readonly property real calloutLetterSpacing: 0
    readonly property int calloutLineHeight: 22

    // Caption
    readonly property int captionSize: 12
    readonly property int captionWeight: Font.Regular
    readonly property real captionLetterSpacing: 0.02
    readonly property int captionLineHeight: 16
}

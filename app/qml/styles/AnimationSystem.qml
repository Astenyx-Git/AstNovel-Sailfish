// AnimationSystem.qml - Apple-style animation tokens
// Based on original HarmonyOS AnimationTokens.ets

pragma Singleton

QtObject {
    // Curves (CSS cubic-bezier format)
    readonly property string easeOut: "cubic-bezier(0.23, 1, 0.32, 1)"
    readonly property string easeInOut: "cubic-bezier(0.77, 0, 0.175, 1)"
    readonly property string easeDrawer: "cubic-bezier(0.32, 0.72, 0, 1)"

    // Durations (ms)
    readonly property int durationPress: 160
    readonly property int durationTooltip: 125
    readonly property int durationDropdown: 200
    readonly property int durationModal: 250
    readonly property int durationPageTransition: 300
    readonly property int durationDrawer: 500
    readonly property int durationToast: 400
    readonly property int durationAccordion: 200

    // Stagger
    readonly property int staggerDelay: 50

    // Scale values
    readonly property real scalePress: 0.97
    readonly property real scaleEnter: 0.95
}

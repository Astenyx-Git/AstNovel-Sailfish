// DesignSystem.qml - Apple-style design tokens for AstNovel Sailfish
// Based on original HarmonyOS DesignTokens.ets

pragma Singleton

QtObject {
    // Corner radius (px)
    readonly property real cornerRadiusCard: 16
    readonly property real cornerRadiusButton: 8
    readonly property real cornerRadiusSmall: 4

    // Shadows
    readonly property color shadowCardColor: "#14000000" // rgba(0,0,0,0.08)
    readonly property real shadowCardRadius: 8
    readonly property real shadowCardOffsetX: 0
    readonly property real shadowCardOffsetY: 2

    // Light theme colors
    readonly property color themeBackground: "#F2F2F7"
    readonly property color themeSurface: "#FFFFFF"
    readonly property color themePrimary: "#007AFF"
    readonly property color themeTextPrimary: "#000000"
    readonly property color themeTextSecondary: "#8E8E93"
    readonly property color themeTextTertiary: "#C7C7CC"
    readonly property color themeSeparator: "#C6C6C8"
    readonly property color themeDanger: "#FF3B30"
    readonly property color themeSuccess: "#30D158"

    // Dark theme colors
    readonly property color darkThemeBackground: "#000000"
    readonly property color darkThemeSurface: "#1C1C1E"
    readonly property color darkThemePrimary: "#0A84FF"
    readonly property color darkThemeTextPrimary: "#E5E5EA"
    readonly property color darkThemeTextSecondary: "#8E8E93"
    readonly property color darkThemeTextTertiary: "#636366"
    readonly property color darkThemeSeparator: "#38383A"
    readonly property color darkThemeDanger: "#FF453A"

    // Book cover gradients
    readonly property var coverGradients: [
        ["#FF6B6B", "#EE5A24"], // Red-Orange
        ["#6C5CE7", "#A29BFE"], // Purple-Blue
        ["#00B894", "#55EFC4"], // Green-Cyan
        ["#FDCB6E", "#E17055"], // Orange-Yellow
        ["#0984E3", "#74B9FF"], // Blue-Cyan
        ["#E84393", "#FD79A8"], // Pink-Magenta
        ["#636E72", "#B2BEC3"], // Gray-Blue
        ["#D63031", "#FF7675"]  // Red-Pink
    ]

    // Helper to get gradient index from string
    function getGradientIndex(str) {
        if (!str) return 0
        let hash = 0
        for (let i = 0; i < str.length; i++) {
            hash = ((hash << 5) - hash) + str.charCodeAt(i)
            hash = hash & hash
        }
        return Math.abs(hash) % coverGradients.length
    }

    // Helper to get gradient colors
    function getGradient(str) {
        const idx = getGradientIndex(str)
        return coverGradients[idx]
    }

    // Helper to get first character
    function getFirstChar(str) {
        if (!str || str.length === 0) return "📖"
        return str.charAt(0)
    }

    // Helper to format time
    function formatTime(timestamp) {
        if (!timestamp || timestamp === 0) return ""
        const date = new Date(timestamp)
        const month = date.getMonth() + 1
        const day = date.getDate()
        return month + "月" + day + "日"
    }

    // Helper to format detailed time
    function formatDetailedTime(timestamp) {
        if (!timestamp || timestamp === 0) return ""
        const date = new Date(timestamp)
        const month = date.getMonth() + 1
        const day = date.getDate()
        const hour = date.getHours()
        const minute = date.getMinutes()
        return month + "/" + day + " " + (hour < 10 ? "0" + hour : hour) + ":" + (minute < 10 ? "0" + minute : minute)
    }
}

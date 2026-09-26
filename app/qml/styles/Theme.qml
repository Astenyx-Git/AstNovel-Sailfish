// Theme.qml - Theme switching between light and dark mode
// Based on original HarmonyOS DarkModeTokens.ets

pragma Singleton

QtObject {
    // Theme mode
    property bool isDarkMode: false

    // Get current theme colors based on mode
    readonly property color themeBackground: isDarkMode ? DesignSystem.darkThemeBackground : DesignSystem.themeBackground
    readonly property color themeSurface: isDarkMode ? DesignSystem.darkThemeSurface : DesignSystem.themeSurface
    readonly property color themePrimary: isDarkMode ? DesignSystem.darkThemePrimary : DesignSystem.themePrimary
    readonly property color themeTextPrimary: isDarkMode ? DesignSystem.darkThemeTextPrimary : DesignSystem.themeTextPrimary
    readonly property color themeTextSecondary: isDarkMode ? DesignSystem.darkThemeTextSecondary : DesignSystem.themeTextSecondary
    readonly property color themeTextTertiary: isDarkMode ? DesignSystem.darkThemeTextTertiary : DesignSystem.themeTextTertiary
    readonly property color themeSeparator: isDarkMode ? DesignSystem.darkThemeSeparator : DesignSystem.themeSeparator
    readonly property color themeDanger: isDarkMode ? DesignSystem.darkThemeDanger : DesignSystem.themeDanger
    readonly property color themeSuccess: isDarkMode ? DesignSystem.themeSuccess : DesignSystem.themeSuccess

    // Toggle dark mode
    function toggleDarkMode() {
        isDarkMode = !isDarkMode
    }

    // Set dark mode directly
    function setDarkMode(enabled) {
        isDarkMode = enabled
    }
}

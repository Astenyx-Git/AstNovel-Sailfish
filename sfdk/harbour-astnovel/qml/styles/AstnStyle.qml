// AstnStyle.qml — design tokens singleton (Apple-style, adapted for Qt 5.6)
pragma Singleton
import QtQuick 2.2

QtObject {
    // Dark mode switch
    property bool isDarkMode: false

    // Live GaussianBlur capability probe result (set once from main.qml)
    property bool liveBlurOk: false

    // Light theme
    readonly property color cBackground:    isDarkMode ? "#000000" : "#F2F2F7"
    readonly property color cSurface:       isDarkMode ? "#1C1C1E" : "#FFFFFF"
    readonly property color cPrimary:       isDarkMode ? "#0A84FF" : "#007AFF"
    readonly property color cTextPrimary:   isDarkMode ? "#E5E5EA" : "#000000"
    readonly property color cTextSecondary: isDarkMode ? "#8E8E93" : "#8E8E93"
    readonly property color cTextTertiary:  isDarkMode ? "#636366" : "#C7C7CC"
    readonly property color cSeparator:     isDarkMode ? "#38383A" : "#C6C6C8"
    readonly property color cDanger:        isDarkMode ? "#FF453A" : "#FF3B30"
    readonly property color cShadow:        isDarkMode ? "#40000000" : "#14000000"

    // Corner radius (px, mirrors DesignTokens.ets)
    readonly property int radiusCard: 16
    readonly property int radiusButton: 8

    // Animation (mirrors AnimationTokens.ets: EASE_OUT 0.23,1,0.32,1 ≈ OutCubic)
    readonly property int durationPress: 160
    readonly property real scalePress: 0.97

    // Typography (mirrors TypographyTokens.ets)
    readonly property int typeTitle: 22
    readonly property int typeHeadline: 17
    readonly property int typeBody: 17
    readonly property int typeCaption: 12

    // Book cover gradients (mirrors DesignTokens.COVER_GRADIENTS)
    readonly property var coverGradients: [
        ["#FF6B6B", "#EE5A24"],
        ["#6C5CE7", "#A29BFE"],
        ["#00B894", "#55EFC4"],
        ["#FDCB6E", "#E17055"],
        ["#0984E3", "#74B9FF"],
        ["#E84393", "#FD79A8"],
        ["#636E72", "#B2BEC3"],
        ["#D63031", "#FF7675"]
    ]

    function gradientIndex(title) {
        var s = title ? title : ""
        var hash = 0
        for (var i = 0; i < s.length; i++) {
            hash = ((hash << 5) - hash) + s.charCodeAt(i)
            hash = hash & hash
        }
        return Math.abs(hash) % coverGradients.length
    }

    function gradientFor(title) {
        return coverGradients[gradientIndex(title)]
    }

    function firstChar(title) {
        if (!title || title.length === 0)
            return "\uD83D\uDCD6"
        return title.charAt(0)
    }

    function formatDate(ts) {
        if (!ts)
            return ""
        var d = new Date(ts)
        return qsTr("%1月%2日").arg(d.getMonth() + 1).arg(d.getDate())
    }

    function formatDateTime(ts) {
        if (!ts)
            return ""
        var d = new Date(ts)
        var hh = d.getHours()
        var mm = d.getMinutes()
        if (hh < 10) hh = "0" + hh
        if (mm < 10) mm = "0" + mm
        return (d.getMonth() + 1) + "/" + d.getDate() + " " + hh + ":" + mm
    }

    // World field data keys (Chinese, as stored in .astn files) → translated
    // display labels. Data access always uses the Chinese key; only display
    // goes through this mapping.
    function worldFieldLabel(key) {
        switch (key) {
        case "地区名称": return qsTr("地区名称")
        case "地形地貌": return qsTr("地形地貌")
        case "气候特征": return qsTr("气候特征")
        case "自然资源": return qsTr("自然资源")
        case "居民分布": return qsTr("居民分布")
        case "与相邻地区关系": return qsTr("与相邻地区关系")
        case "事件名称": return qsTr("事件名称")
        case "发生时间": return qsTr("发生时间")
        case "关键人物": return qsTr("关键人物")
        case "事件经过": return qsTr("事件经过")
        case "影响与后果": return qsTr("影响与后果")
        case "与其他事件关联": return qsTr("与其他事件关联")
        case "体系名称": return qsTr("体系名称")
        case "能量来源": return qsTr("能量来源")
        case "施法规则": return qsTr("施法规则")
        case "限制条件": return qsTr("限制条件")
        case "与其他体系的关系": return qsTr("与其他体系的关系")
        case "组织名称": return qsTr("组织名称")
        case "组织类型": return qsTr("组织类型")
        case "层级结构": return qsTr("层级结构")
        case "权力分布": return qsTr("权力分布")
        case "核心价值观": return qsTr("核心价值观")
        case "与其他组织关系": return qsTr("与其他组织关系")
        case "条目标题": return qsTr("条目标题")
        case "详细描述": return qsTr("详细描述")
        case "备注": return qsTr("备注")
        default: return key
        }
    }
}

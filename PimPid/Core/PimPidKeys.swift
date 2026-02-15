import Foundation

/// คีย์สำหรับ UserDefaults ใช้ที่เดียว (ตาม code-organization + data-persistence)
enum PimPidKeys {
    static let enabled = "pimpid.enabled"
    static let excludeWords = "pimpid.excludeWords"
    static let shortcutKeyCode = "pimpid.shortcutKeyCode"
    static let shortcutModifierFlags = "pimpid.shortcutModifierFlags"

    // Auto-correction settings
    static let autoCorrectEnabled = "pimpid.autoCorrect.enabled"
    static let autoCorrectDelay = "pimpid.autoCorrect.delay"
    static let autoCorrectSoundEnabled = "pimpid.autoCorrect.soundEnabled"
    static let autoCorrectVisualFeedback = "pimpid.autoCorrect.visualFeedback"
    static let autoCorrectExcludedApps = "pimpid.autoCorrect.excludedApps"

    // Onboarding
    static let hasCompletedOnboarding = "pimpid.onboarding.completed"

    // Appearance
    static let appearanceTheme = "pimpid.appearance.theme"
    static let appearanceFontSize = "pimpid.appearance.fontSize"
    static let notificationStyle = "pimpid.appearance.notificationStyle"
}

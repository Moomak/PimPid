import Foundation
import AppKit

/// คีย์สำหรับ UserDefaults ใช้ที่เดียว (ตาม code-organization + data-persistence)
///
/// | Key | ใช้ที่ | ค่าเริ่มต้น |
/// |-----|--------|-------------|
/// | enabled | เปิด/ปิด PimPid ทั้งหมด | true |
/// | excludeWords | รายการคำที่ exclude (array) | [] |
/// | shortcutKeyCode / shortcutModifierFlags | Shortcut แปลงข้อความที่เลือก | ⌘⇧L (37, 768) |
/// | autoCorrectEnabled | เปิด Auto-Correct | false |
/// | autoCorrectDelay | ความล่าช้าก่อนแก้ (ms), 0=ใช้ 200ms | 0 |
/// | autoCorrectMinChars | จำนวนตัวอักษรขั้นต่ำก่อนแก้ (2–5) | 3 |
/// | autoCorrectPostReplaceDelayMs | delay หลัง replace (ms) | 25 |
/// | autoCorrectSoundEnabled | เสียงเมื่อแก้ | false |
/// | autoCorrectVisualFeedback | แสดง toast เมื่อแก้ | true |
/// | autoCorrectExcludedApps | Bundle ID ที่ไม่ให้ auto-correct | [] |
/// | hasCompletedOnboarding | ผ่าน onboarding แล้ว | false |
/// | onboardingDidOpenAccessibilitySettings | เคยกดเปิด Accessibility settings จาก onboarding | false |
/// | appearanceTheme | auto/light/dark | auto |
/// | appearanceFontSize | small/medium/large | medium |
/// | notificationStyle | toast/minimal/off | toast |
/// | toastDuration | วินาที (1.5/2/3) | 2.0 |
enum PimPidKeys {
    static let enabled = "pimpid.enabled"
    static let excludeWords = "pimpid.excludeWords"
    static let shortcutKeyCode = "pimpid.shortcutKeyCode"
    static let shortcutModifierFlags = "pimpid.shortcutModifierFlags"

    // Auto-correction settings
    static let autoCorrectEnabled = "pimpid.autoCorrect.enabled"
    static let autoCorrectDelay = "pimpid.autoCorrect.delay"
    static let autoCorrectMinChars = "pimpid.autoCorrect.minChars"
    static let autoCorrectPostReplaceDelayMs = "pimpid.autoCorrect.postReplaceDelayMs"
    static let backspaceDelayMs = "pimpid.autoCorrect.backspaceDelayMs"
    static let autoCorrectSoundEnabled = "pimpid.autoCorrect.soundEnabled"
    static let autoCorrectVisualFeedback = "pimpid.autoCorrect.visualFeedback"
    static let autoCorrectExcludedApps = "pimpid.autoCorrect.excludedApps"
    /// Task 8: รายการ "bundleID:windowNumber" ที่ไม่ให้ auto-correct (exclude ต่อหน้าต่าง)
    static let autoCorrectExcludedWindows = "pimpid.autoCorrect.excludedWindows"

    /// Task 9: ชื่อ layout ไทย (kedmanee / pattachoti) — ใช้โหลด KeyboardLayout-<name>.plist
    static let thaiKeyboardLayout = "pimpid.thaiKeyboardLayout"

    // Onboarding
    static let hasCompletedOnboarding = "pimpid.onboarding.completed"
    static let onboardingDidOpenAccessibilitySettings = "pimpid.onboarding.didOpenAccessibilitySettings"

    // Appearance
    static let appearanceTheme = "pimpid.appearance.theme"
    static let appearanceFontSize = "pimpid.appearance.fontSize"
    static let notificationStyle = "pimpid.appearance.notificationStyle"
    static let toastDuration = "pimpid.appearance.toastDuration"
    static let appLanguage = "pimpid.appearance.language"

    // Shortcut defaults (⌘⇧L): L = keyCode 37, Cmd+Shift = 768
    static let defaultShortcutKeyCode: UInt16 = 37
    static let defaultShortcutModifierFlags: UInt = NSEvent.ModifierFlags([.command, .shift]).rawValue
}

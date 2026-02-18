import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: PimPidKeys.enabled) }
    }

    // Auto-correction settings
    @Published var autoCorrectEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoCorrectEnabled, forKey: PimPidKeys.autoCorrectEnabled)
            if autoCorrectEnabled {
                AutoCorrectionEngine.shared.start()
            } else {
                AutoCorrectionEngine.shared.stop()
            }
        }
    }

    @Published var autoCorrectDelay: Double {
        didSet { UserDefaults.standard.set(autoCorrectDelay, forKey: PimPidKeys.autoCorrectDelay) }
    }

    @Published var autoCorrectSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(autoCorrectSoundEnabled, forKey: PimPidKeys.autoCorrectSoundEnabled) }
    }

    @Published var autoCorrectVisualFeedback: Bool {
        didSet { UserDefaults.standard.set(autoCorrectVisualFeedback, forKey: PimPidKeys.autoCorrectVisualFeedback) }
    }

    @Published var excludedApps: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(excludedApps), forKey: PimPidKeys.autoCorrectExcludedApps)
        }
    }

    /// Task 8: หน้าต่างที่ exclude (รูปแบบ "bundleID:windowNumber")
    @Published var excludedWindows: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(excludedWindows), forKey: PimPidKeys.autoCorrectExcludedWindows)
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: PimPidKeys.hasCompletedOnboarding) }
    }

    // Appearance
    @Published var appearanceTheme: String {
        didSet { UserDefaults.standard.set(appearanceTheme, forKey: PimPidKeys.appearanceTheme) }
    }
    @Published var appearanceFontSize: String {
        didSet { UserDefaults.standard.set(appearanceFontSize, forKey: PimPidKeys.appearanceFontSize) }
    }
    @Published var notificationStyle: String {
        didSet { UserDefaults.standard.set(notificationStyle, forKey: PimPidKeys.notificationStyle) }
    }

    @Published var appLanguage: String {
        didSet {
            UserDefaults.standard.set(appLanguage, forKey: PimPidKeys.appLanguage)
            // Apply language override immediately (takes full effect on next launch)
            if appLanguage == "system" {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.set([appLanguage], forKey: "AppleLanguages")
            }
        }
    }

    init() {
        // Initialize isEnabled
        if UserDefaults.standard.object(forKey: PimPidKeys.enabled) == nil {
            UserDefaults.standard.set(true, forKey: PimPidKeys.enabled)
        }
        self.isEnabled = UserDefaults.standard.bool(forKey: PimPidKeys.enabled)

        // Initialize auto-correction settings
        if UserDefaults.standard.object(forKey: PimPidKeys.autoCorrectEnabled) == nil {
            UserDefaults.standard.set(false, forKey: PimPidKeys.autoCorrectEnabled) // Default: OFF
        }
        self.autoCorrectEnabled = UserDefaults.standard.bool(forKey: PimPidKeys.autoCorrectEnabled)

        if UserDefaults.standard.object(forKey: PimPidKeys.autoCorrectDelay) == nil {
            UserDefaults.standard.set(0.0, forKey: PimPidKeys.autoCorrectDelay) // Default: 0ms
        }
        self.autoCorrectDelay = UserDefaults.standard.double(forKey: PimPidKeys.autoCorrectDelay)

        if UserDefaults.standard.object(forKey: PimPidKeys.autoCorrectSoundEnabled) == nil {
            UserDefaults.standard.set(false, forKey: PimPidKeys.autoCorrectSoundEnabled) // Default: OFF
        }
        self.autoCorrectSoundEnabled = UserDefaults.standard.bool(forKey: PimPidKeys.autoCorrectSoundEnabled)

        if UserDefaults.standard.object(forKey: PimPidKeys.autoCorrectVisualFeedback) == nil {
            UserDefaults.standard.set(true, forKey: PimPidKeys.autoCorrectVisualFeedback) // Default: ON
        }
        self.autoCorrectVisualFeedback = UserDefaults.standard.bool(forKey: PimPidKeys.autoCorrectVisualFeedback)

        // Initialize excluded apps
        if let apps = UserDefaults.standard.stringArray(forKey: PimPidKeys.autoCorrectExcludedApps) {
            self.excludedApps = Set(apps)
        } else {
            self.excludedApps = []
        }
        if let wins = UserDefaults.standard.stringArray(forKey: PimPidKeys.autoCorrectExcludedWindows) {
            self.excludedWindows = Set(wins)
        } else {
            self.excludedWindows = []
        }

        // Initialize onboarding
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: PimPidKeys.hasCompletedOnboarding)

        // Appearance
        if UserDefaults.standard.object(forKey: PimPidKeys.appearanceTheme) == nil {
            UserDefaults.standard.set("auto", forKey: PimPidKeys.appearanceTheme)
        }
        self.appearanceTheme = UserDefaults.standard.string(forKey: PimPidKeys.appearanceTheme) ?? "auto"
        if UserDefaults.standard.object(forKey: PimPidKeys.appearanceFontSize) == nil {
            UserDefaults.standard.set("medium", forKey: PimPidKeys.appearanceFontSize)
        }
        self.appearanceFontSize = UserDefaults.standard.string(forKey: PimPidKeys.appearanceFontSize) ?? "medium"
        if UserDefaults.standard.object(forKey: PimPidKeys.notificationStyle) == nil {
            UserDefaults.standard.set("toast", forKey: PimPidKeys.notificationStyle)
        }
        self.notificationStyle = UserDefaults.standard.string(forKey: PimPidKeys.notificationStyle) ?? "toast"

        self.appLanguage = UserDefaults.standard.string(forKey: PimPidKeys.appLanguage) ?? "th"
    }
}

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

    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: PimPidKeys.hasCompletedOnboarding) }
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

        // Initialize onboarding
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: PimPidKeys.hasCompletedOnboarding)
    }
}

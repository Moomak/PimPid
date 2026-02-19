import SwiftUI
import AppKit

@main
struct PimPidApp: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showOnboarding = false

    init() {
        // Apply language setting before UI loads — default: Thai
        let saved = UserDefaults.standard.string(forKey: PimPidKeys.appLanguage)
        let lang = saved ?? "th"
        if saved == nil {
            UserDefaults.standard.set("th", forKey: PimPidKeys.appLanguage)
        }
        if lang == "system" {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([lang], forKey: "AppleLanguages")
        }
    }

    private var menuBarIconName: String {
        appState.isEnabled ? "character.bubble.fill" : "character.bubble"
    }

    private var menuBarIconColor: Color {
        if appState.isEnabled, appState.autoCorrectEnabled { return .orange }
        return .primary
    }

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appState)
        }

        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(appState)
        } label: {
            Image(systemName: menuBarIconName)
                .foregroundStyle(menuBarIconColor)
        }
        .menuBarExtraStyle(.window)

        // Onboarding window (shown on first launch)
        Window("Welcome to PimPid", id: "onboarding") {
            OnboardingView()
                .environmentObject(appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowObservers: [NSObjectProtocol] = []
    private let serviceProvider = PimPidServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.servicesProvider = serviceProvider
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        // Observe window visibility to show/hide dock icon
        windowObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in self?.updateDockIconVisibility() }
        )
        windowObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                // Delay slightly so the window count updates
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self?.updateDockIconVisibility()
                }
            }
        )

        // Initialize auto-correction engine if enabled (read UserDefaults directly)
        if UserDefaults.standard.bool(forKey: PimPidKeys.enabled)
            && UserDefaults.standard.bool(forKey: PimPidKeys.autoCorrectEnabled) {
            AutoCorrectionEngine.shared.start()
        }

        KeyboardShortcutManager.shared.start()

        // Task 19: โหลดคำไทยใน background พร้อม progress
        ThaiWordListLoader.shared.beginLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let checker = NSSpellChecker.shared
            checker.setLanguage("en")
            _ = checker.checkSpelling(of: "the", startingAt: 0)
        }

        // Show onboarding on first launch
        if !UserDefaults.standard.bool(forKey: PimPidKeys.hasCompletedOnboarding) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "onboarding" }) {
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                } else {
                    NSWorkspace.shared.open(URL(string: "pimpid://onboarding")!)
                }
            }
        }

        // แจ้งเตือนเมื่อเปิด Auto-Correct แต่ยังไม่มีสิทธิ์ Accessibility (task 64)
        if UserDefaults.standard.bool(forKey: PimPidKeys.autoCorrectEnabled), !AccessibilityHelper.isAccessibilityTrusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                Task { @MainActor in
                    NotificationService.shared.showToast(message: "ต้องการสิทธิ์ Accessibility เพื่อให้ Auto-Correct ทำงาน", type: .warning)
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        AutoCorrectionEngine.shared.stop()
        KeyboardShortcutManager.shared.stop()
        windowObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    /// Show dock icon when any regular window is visible, hide when all closed
    private func updateDockIconVisibility() {
        let hasVisibleWindow = NSApp.windows.contains { window in
            window.isVisible
            && window.level == .normal
            && !(window.className.contains("MenuBarExtra") || window.className.contains("StatusBar"))
        }
        let newPolicy: NSApplication.ActivationPolicy = hasVisibleWindow ? .regular : .accessory
        if NSApp.activationPolicy() != newPolicy {
            NSApp.setActivationPolicy(newPolicy)
            if hasVisibleWindow {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    @objc private func appDidBecomeActive() {
        if UserDefaults.standard.bool(forKey: PimPidKeys.enabled),
           UserDefaults.standard.bool(forKey: PimPidKeys.autoCorrectEnabled),
           AccessibilityHelper.isAccessibilityTrusted,
           !AutoCorrectionEngine.shared.isRunning {
            AutoCorrectionEngine.shared.start()
        }
    }
}

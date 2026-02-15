import SwiftUI
import AppKit

@main
struct PimPidApp: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showOnboarding = false

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appState)
        }

        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(appState)
        } label: {
            Image(systemName: appState.isEnabled ? "character.bubble.fill" : "character.bubble")
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

    func applicationDidFinishLaunching(_ notification: Notification) {
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
        if UserDefaults.standard.bool(forKey: PimPidKeys.autoCorrectEnabled) {
            AutoCorrectionEngine.shared.start()
        }

        // โหลดรายการคำไทยและ warm spell checker ล่วงหน้า เพื่อไม่ให้การแปลงครั้งแรกค้าง
        DispatchQueue.global(qos: .utility).async {
            _ = ThaiWordList.words
        }
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
    }

    func applicationWillTerminate(_ notification: Notification) {
        AutoCorrectionEngine.shared.stop()
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
        if UserDefaults.standard.bool(forKey: PimPidKeys.autoCorrectEnabled),
           AccessibilityHelper.isAccessibilityTrusted,
           !AutoCorrectionEngine.shared.isRunning {
            AutoCorrectionEngine.shared.start()
        }
    }
}

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
        KeyboardShortcutManager.shared.register()

        // Register services provider
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()

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
        KeyboardShortcutManager.shared.unregister()
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
        KeyboardShortcutManager.shared.reregisterIfNeeded()
        if UserDefaults.standard.bool(forKey: PimPidKeys.autoCorrectEnabled),
           KeyboardShortcutManager.isAccessibilityTrusted,
           !AutoCorrectionEngine.shared.isRunning {
            AutoCorrectionEngine.shared.start()
        }
    }

    // MARK: - Services Menu

    /// Convert selected text (Services menu: "Convert Thai ↔ English")
    @objc func convertText(_ pasteboard: NSPasteboard, userData: String, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let text = pasteboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check exclude list from UserDefaults directly (avoid @MainActor dependency)
        let excludeWords = Set(
            (UserDefaults.standard.stringArray(forKey: PimPidKeys.excludeWords) ?? [])
                .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        )
        let lower = trimmed.lowercased()
        if excludeWords.contains(lower) { return }
        let tokens = lower.split(separator: " ").map(String.init)
        if !tokens.isEmpty && tokens.allSatisfy({ excludeWords.contains($0) }) { return }

        // Convert text
        let converted = KeyboardLayoutConverter.convertAuto(trimmed)
        guard converted != trimmed else { return }

        let direction = KeyboardLayoutConverter.dominantLanguage(trimmed)

        // Write back to pasteboard (synchronously)
        pasteboard.clearContents()
        pasteboard.setString(converted, forType: .string)

        // Switch keyboard layout
        switch direction {
        case .thaiToEnglish:
            InputSourceSwitcher.switchTo(.english)
        case .englishToThai:
            InputSourceSwitcher.switchTo(.thai)
        case .none:
            break
        }

        // Show notification if enabled (fire-and-forget to main thread)
        if UserDefaults.standard.bool(forKey: PimPidKeys.autoCorrectVisualFeedback) {
            let msg = "\(trimmed) → \(converted)"
            DispatchQueue.main.async {
                NotificationService.shared.showToast(message: msg)
            }
        }
    }
}

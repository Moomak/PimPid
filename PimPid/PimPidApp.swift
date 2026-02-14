import SwiftUI
import AppKit

@main
struct PimPidApp: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appState)
        }

        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(appState)
                .environment(\.openSettings) {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
        } label: {
            Image(systemName: appState.isEnabled ? "character.bubble.fill" : "character.bubble")
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // ลงทะเบียน global shortcut สำหรับสลับภาษาข้อความที่เลือก
        KeyboardShortcutManager.shared.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        KeyboardShortcutManager.shared.unregister()
    }
}

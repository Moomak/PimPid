import AppKit
import Foundation

/// ลงทะเบียน global shortcut Cmd+Shift+L สำหรับสลับภาษาข้อความที่เลือก (ต้องเปิด Accessibility ให้แอปใน System Settings)
final class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()
    private var globalMonitor: Any?

    private init() {}

    func register() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains([.command, .shift]),
                  event.charactersIgnoringModifiers?.lowercased() == "l" else { return }
            Task { @MainActor in
                self?.performConvert()
            }
        }
    }

    func unregister() {
        if let m = globalMonitor {
            NSEvent.removeMonitor(m)
        }
        globalMonitor = nil
    }

    @MainActor
    private func performConvert() {
        let excludeStore = ExcludeListStore.shared
        let enabled = UserDefaults.standard.bool(forKey: PimPidKeys.enabled)
        TextReplacementService.convertSelectedText(excludeStore: excludeStore, enabled: enabled)
    }
}

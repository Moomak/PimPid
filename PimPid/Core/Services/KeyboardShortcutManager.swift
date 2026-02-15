import AppKit
import ApplicationServices
import Foundation

/// ลงทะเบียน global shortcut สำหรับแก้ภาษาที่พิมพ์ผิด — ตั้งค่าได้ใน Settings
final class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()
    private var globalMonitor: Any?
    private static let modifierMask: UInt = NSEvent.ModifierFlags([.command, .shift, .option, .control]).rawValue

    private init() {}

    /// มีสิทธิ์ Accessibility หรือยัง (ต้องมีถึงจะรับ global key ได้)
    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrustedWithOptions([
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false
        ] as CFDictionary)
    }

    /// เปิด System Settings ไปที่หน้า Accessibility
    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func register() {
        unregister()
        guard Self.isAccessibilityTrusted else {
            Task { @MainActor in
                Self.openAccessibilitySettings()
            }
            return
        }
        let keyCode = ShortcutPreference.keyCode
        let modifierFlags = ShortcutPreference.modifierFlags
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let eventMod = event.modifierFlags.rawValue & Self.modifierMask
            guard event.keyCode == keyCode, eventMod == modifierFlags else { return }
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

    /// ลงทะเบียนใหม่เมื่อแอปกลับมา active (หลังผู้ใช้ให้สิทธิ์)
    func reregisterIfNeeded() {
        guard globalMonitor == nil, Self.isAccessibilityTrusted else { return }
        register()
    }

    @MainActor
    private func performConvert() {
        let excludeStore = ExcludeListStore.shared
        let enabled = UserDefaults.standard.bool(forKey: PimPidKeys.enabled)
        TextReplacementService.convertSelectedText(excludeStore: excludeStore, enabled: enabled)
    }
}

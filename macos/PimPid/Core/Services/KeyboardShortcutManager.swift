import AppKit
import Foundation

/// จัดการ global keyboard shortcut สำหรับ "Convert Selected Text" (ค่าเริ่มต้น ⌘⇧L)
/// ใช้ NSEvent.addGlobalMonitorForEvents — ต้องมีสิทธิ์ Accessibility
final class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()

    private var monitor: Any?
    private let lock = NSLock()

    private init() {}

    func start() {
        lock.lock()
        defer { lock.unlock() }
        if monitor != nil { return }

        let keyCode = currentKeyCode
        let modifierFlags = currentModifierFlags

        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode == keyCode,
                  event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue == modifierFlags else {
                return
            }
            guard UserDefaults.standard.bool(forKey: PimPidKeys.enabled) else { return }

            DispatchQueue.main.async {
                Task { @MainActor in
                    TextReplacementService.convertSelectedText(
                        excludeStore: ExcludeListStore.shared,
                        enabled: UserDefaults.standard.bool(forKey: PimPidKeys.enabled),
                        direction: nil
                    )
                }
            }
        }
    }

    func stop() {
        lock.lock()
        defer { lock.unlock() }
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }

    /// อัปเดต shortcut จาก UserDefaults แล้วเริ่มใหม่ (เรียกเมื่อผู้ใช้เปลี่ยน shortcut)
    func update() {
        stop()
        start()
    }

    private var currentKeyCode: UInt16 {
        let raw = UserDefaults.standard.object(forKey: PimPidKeys.shortcutKeyCode)
        if let n = raw as? NSNumber { return n.uint16Value }
        return PimPidKeys.defaultShortcutKeyCode
    }

    private var currentModifierFlags: UInt {
        let raw = UserDefaults.standard.object(forKey: PimPidKeys.shortcutModifierFlags)
        if let n = raw as? NSNumber { return n.uintValue }
        return PimPidKeys.defaultShortcutModifierFlags
    }

    /// สตริง shortcut ปัจจุบัน เช่น "⌘⇧L" สำหรับแสดงใน UI
    static func shortcutDisplayString() -> String {
        let keyCode: UInt16
        let modifierFlags: UInt
        if let n = UserDefaults.standard.object(forKey: PimPidKeys.shortcutKeyCode) as? NSNumber {
            keyCode = n.uint16Value
        } else {
            keyCode = PimPidKeys.defaultShortcutKeyCode
        }
        if let n = UserDefaults.standard.object(forKey: PimPidKeys.shortcutModifierFlags) as? NSNumber {
            modifierFlags = n.uintValue
        } else {
            modifierFlags = PimPidKeys.defaultShortcutModifierFlags
        }
        let flags = NSEvent.ModifierFlags(rawValue: modifierFlags)
        var parts: [String] = []
        if flags.contains(.command) { parts.append("⌘") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.control) { parts.append("⌃") }
        let char = keyCodeToCharacter(keyCode)
        parts.append(char)
        return parts.joined()
    }

    private static func keyCodeToCharacter(_ keyCode: UInt16) -> String {
        let map: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
            20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
            29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M",
            47: ".", 48: "Tab", 49: "Space", 50: "`", 51: "Delete", 52: "Enter", 53: "Escape",
        ]
        return map[keyCode] ?? "Key\(keyCode)"
    }
}

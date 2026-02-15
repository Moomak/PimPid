import AppKit
import Foundation

/// ค่า default และ helper สำหรับ shortcut แก้ภาษาที่พิมพ์ผิด
enum ShortcutPreference {
    static let defaultKeyCode: UInt16 = 37 // kVK_ANSI_L
    static let defaultModifierFlags: UInt = NSEvent.ModifierFlags([.command, .shift]).rawValue

    static var keyCode: UInt16 {
        let n = UserDefaults.standard.object(forKey: PimPidKeys.shortcutKeyCode) as? Int
        guard let n = n, n >= 0, n <= 0xFFFF else { return defaultKeyCode }
        return UInt16(n)
    }

    static var modifierFlags: UInt {
        let n = UserDefaults.standard.object(forKey: PimPidKeys.shortcutModifierFlags) as? Int
        guard let n = n, n >= 0 else { return defaultModifierFlags }
        return UInt(truncatingIfNeeded: n)
    }

    static func set(keyCode: UInt16, modifierFlags: UInt) {
        UserDefaults.standard.set(Int(keyCode), forKey: PimPidKeys.shortcutKeyCode)
        UserDefaults.standard.set(Int(truncatingIfNeeded: modifierFlags), forKey: PimPidKeys.shortcutModifierFlags)
    }

    /// แปลง keyCode เป็นตัวอักษร/ชื่อปุ่มสำหรับแสดง
    static func keyCodeToString(_ keyCode: UInt16) -> String {
        let map: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
            20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
            29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return", 37: "L",
            38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M",
            47: ".", 48: "Tab", 49: "Space", 50: "`", 51: "Delete", 52: "Enter", 53: "Escape",
        ]
        return map[keyCode] ?? "Key(\(keyCode))"
    }

    /// แปลง modifier flags เป็นสัญลักษณ์ ⌘⇧⌥⌃
    static func modifierFlagsToSymbols(_ flags: UInt) -> String {
        var s = ""
        let m = NSEvent.ModifierFlags(rawValue: flags)
        if m.contains(.control) { s += "⌃" }
        if m.contains(.option) { s += "⌥" }
        if m.contains(.shift) { s += "⇧" }
        if m.contains(.command) { s += "⌘" }
        return s
    }

    /// ข้อความ shortcut สำหรับแสดง เช่น "⌘⇧L"
    static func displayString(keyCode: UInt16, modifierFlags: UInt) -> String {
        modifierFlagsToSymbols(modifierFlags) + keyCodeToString(keyCode)
    }
}

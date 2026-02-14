import AppKit
import Foundation

/// ดึงข้อความที่เลือกจากแอปที่โฟกัส แล้วแทนที่ด้วยข้อความที่แปลงแล้ว (ใช้ Cmd+C แล้ว Cmd+V)
enum TextReplacementService {
    /// ดึงข้อความที่เลือกผ่าน pasteboard (ผู้ใช้กด Cmd+C หรือเรา simulate Copy แล้วอ่าน)
    static func getSelectedTextViaPasteboard() -> String? {
        let pasteboard = NSPasteboard.general
        let oldCount = pasteboard.changeCount
        // Simulate Copy
        let source = CGEventSource(stateID: .combinedSessionState)
        keyPress(keyCode: 8, modifier: .maskCommand, source: source) // Cmd+C (C = 8)
        Thread.sleep(forTimeInterval: 0.1)
        if pasteboard.changeCount != oldCount, let str = pasteboard.string(forType: .string) {
            return str
        }
        return pasteboard.string(forType: .string)
    }

    /// ส่งข้อความที่แปลงแล้วกลับไป (แทนที่ selection โดยการ Paste)
    static func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let source = CGEventSource(stateID: .combinedSessionState)
        keyPress(keyCode: 9, modifier: .maskCommand, source: source) // Cmd+V (V = 9)
    }

    /// แก้ข้อความที่เลือก: Copy → แปลง (และเช็ค exclude) → Paste. เรียกจาก MainActor (ใช้กับ ExcludeListStore)
    @MainActor
    static func convertSelectedText(
        excludeStore: ExcludeListStore,
        enabled: Bool,
        direction: KeyboardLayoutConverter.ConversionDirection? = nil
    ) {
        guard enabled else { return }
        let original = getSelectedTextViaPasteboard()
        guard let raw = original?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return }
        if excludeStore.shouldExclude(text: raw) { return }
        let converted: String
        if let dir = direction {
            switch dir {
            case .thaiToEnglish: converted = KeyboardLayoutConverter.convertThaiToEnglish(raw)
            case .englishToThai: converted = KeyboardLayoutConverter.convertEnglishToThai(raw)
            case .none: converted = raw
            }
        } else {
            converted = KeyboardLayoutConverter.convertAuto(raw)
        }
        if converted != raw {
            pasteText(converted)
        }
    }

    private static func keyPress(keyCode: CGKeyCode, modifier: CGEventFlags, source: CGEventSource?) {
        guard let source = source else { return }
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyDown?.flags = modifier
        keyUp?.flags = modifier
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}

import Foundation
import CoreGraphics
import AppKit

/// จัดการลบและพิมพ์ข้อความโดยใช้ CGEvent simulation สำหรับ auto-correction
enum TextManipulator {

    /// ลบข้อความที่พิมพ์ไปแล้ว (simulate backspace)
    /// - Parameter count: จำนวนตัวอักษรที่ต้องการลบ
    static func deleteCharacters(count: Int) {
        guard count > 0 else { return }

        let source = CGEventSource(stateID: .combinedSessionState)

        for _ in 0..<count {
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: true) {
                keyDown.post(tap: .cghidEventTap)
            }
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: false) {
                keyUp.post(tap: .cghidEventTap)
            }
            usleep(5000) // 5ms between backspaces
        }
    }

    /// แทนที่ข้อความโดยลบคำเดิมแล้ว paste คำใหม่ผ่าน clipboard (Cmd+V)
    /// - Parameters:
    ///   - deleteCount: จำนวนตัวอักษรที่ต้องลบ
    ///   - text: ข้อความใหม่ที่จะ paste
    static func replaceWithClipboard(deleteCount: Int, text: String) {
        let pasteboard = NSPasteboard.general

        // Save current clipboard
        let savedItems = pasteboard.pasteboardItems?.compactMap { item -> (String, String)? in
            guard let type = item.types.first,
                  let data = item.string(forType: type) else { return nil }
            return (type.rawValue, data)
        } ?? []

        // Delete original characters
        deleteCharacters(count: deleteCount)
        usleep(30000) // 30ms wait for backspaces to complete

        // Set clipboard to converted text
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        usleep(10000) // 10ms wait for clipboard

        // Simulate Cmd+V (paste)
        let source = CGEventSource(stateID: .combinedSessionState)

        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) { // 0x09 = 'v'
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }

        // Restore clipboard after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !savedItems.isEmpty {
                pasteboard.clearContents()
                for (typeRaw, data) in savedItems {
                    pasteboard.setString(data, forType: NSPasteboard.PasteboardType(typeRaw))
                }
            }
        }
    }

    /// พิมพ์ข้อความใหม่ (simulate typing) — fallback, prefer replaceWithClipboard
    /// - Parameter text: ข้อความที่ต้องการพิมพ์
    static func typeText(_ text: String) {
        guard !text.isEmpty else { return }

        let source = CGEventSource(stateID: .combinedSessionState)

        for char in text {
            let chars = Array(String(char).utf16)

            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                keyDown.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: chars)
                keyDown.post(tap: .cghidEventTap)
            }

            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                keyUp.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: chars)
                keyUp.post(tap: .cghidEventTap)
            }

            usleep(1000)
        }
    }

    /// ทดสอบว่า TextManipulator ทำงานได้หรือไม่ (ต้องมี Accessibility permission)
    static func testPermission() -> Bool {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let _ = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
            return false
        }
        return true
    }
}

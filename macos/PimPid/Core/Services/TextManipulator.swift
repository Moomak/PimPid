import Foundation
import CoreGraphics
import AppKit

/// จัดการลบและพิมพ์ข้อความโดยใช้ CGEvent simulation สำหรับ auto-correction
enum TextManipulator {

    /// ลบข้อความที่พิมพ์ไปแล้ว (simulate backspace)
    /// - Parameter count: จำนวนตัวอักษรที่ต้องการลบ
    /// - Delay ระหว่าง backspace อ่านจาก UserDefaults (backspaceDelayMs), ค่าเริ่มต้น 5ms
    static func deleteCharacters(count: Int) {
        guard count > 0 else { return }

        let delayMs = UserDefaults.standard.object(forKey: PimPidKeys.backspaceDelayMs).flatMap { $0 as? NSNumber }.map(\.intValue)
        let delayUs = UInt32((delayMs.map { max(1, min(20, $0)) } ?? 5) * 1000)

        let source = CGEventSource(stateID: .combinedSessionState)

        for _ in 0..<count {
            if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: true) {
                keyDown.post(tap: .cghidEventTap)
            }
            if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x33, keyDown: false) {
                keyUp.post(tap: .cghidEventTap)
            }
            usleep(delayUs)
        }
    }

    /// แทนที่ข้อความโดยลบคำเดิมแล้ว paste คำใหม่ผ่าน clipboard (Cmd+V)
    /// Task 26: Save/Restore clipboard หลาย type; Task 27: ใช้ custom pasteboard เก็บของ user ระหว่าง replace
    static func replaceWithClipboard(deleteCount: Int, text: String) {
        let general = NSPasteboard.general
        let customName = NSPasteboard.Name("com.pimpid.replace.\(UUID().uuidString)")
        let custom = NSPasteboard(name: customName)

        // Save current clipboard ไป custom pasteboard (ลดโอกาสแอปอื่นอ่าน/เขียน general ระหว่าง replace)
        var savedItems: [[(type: NSPasteboard.PasteboardType, data: Data)]] = []
        if let items = general.pasteboardItems {
            for item in items {
                var itemData: [(NSPasteboard.PasteboardType, Data)] = []
                for type in item.types {
                    if let data = item.data(forType: type) {
                        itemData.append((type, data))
                    }
                }
                if !itemData.isEmpty { savedItems.append(itemData) }
            }
        }

        custom.clearContents()
        if !savedItems.isEmpty {
            var newItems: [NSPasteboardItem] = []
            for itemData in savedItems {
                let newItem = NSPasteboardItem()
                for (type, data) in itemData {
                    newItem.setData(data, forType: type)
                }
                newItems.append(newItem)
            }
            custom.writeObjects(newItems)
        }

        deleteCharacters(count: deleteCount)
        usleep(30000)
        general.clearContents()
        general.setString(text, forType: .string)
        usleep(10000)

        let source = CGEventSource(stateID: .combinedSessionState)
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }

        let hadItems = !savedItems.isEmpty
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if hadItems {
                general.clearContents()
                if let items = custom.pasteboardItems {
                    var restore: [NSPasteboardItem] = []
                    for item in items {
                        let newItem = NSPasteboardItem()
                        for type in item.types {
                            if let data = item.data(forType: type) {
                                newItem.setData(data, forType: type)
                            }
                        }
                        restore.append(newItem)
                    }
                    general.writeObjects(restore)
                }
                var expectedString: String?
                for itemData in savedItems {
                    if let pair = itemData.first(where: { $0.0 == .string }), let s = String(data: pair.1, encoding: .utf8) {
                        expectedString = s
                        break
                    }
                }
                let exp = expectedString
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if let expected = exp, general.string(forType: .string) != expected {
                        Task { @MainActor in
                            NotificationService.shared.showToast(message: "คลิปบอร์ดอาจถูกเขียนทับ — อาจต้อง paste เอง", type: .warning)
                        }
                    }
                }
            }
        }
    }

    /// Fallback เมื่อสร้าง custom pasteboard ไม่ได้ (task 27)
    private static func replaceWithClipboardFallback(deleteCount: Int, text: String) {
        let pasteboard = NSPasteboard.general
        var savedItems: [[(type: NSPasteboard.PasteboardType, data: Data)]] = []
        if let items = pasteboard.pasteboardItems {
            for item in items {
                var itemData: [(NSPasteboard.PasteboardType, Data)] = []
                for type in item.types {
                    if let data = item.data(forType: type) {
                        itemData.append((type, data))
                    }
                }
                if !itemData.isEmpty { savedItems.append(itemData) }
            }
        }
        deleteCharacters(count: deleteCount)
        usleep(30000)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        usleep(10000)
        let source = CGEventSource(stateID: .combinedSessionState)
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }
        let hadItems = !savedItems.isEmpty
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if hadItems {
                pasteboard.clearContents()
                var newItems: [NSPasteboardItem] = []
                for itemData in savedItems {
                    let newItem = NSPasteboardItem()
                    for (type, data) in itemData {
                        newItem.setData(data, forType: type)
                    }
                    newItems.append(newItem)
                }
                pasteboard.writeObjects(newItems)
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

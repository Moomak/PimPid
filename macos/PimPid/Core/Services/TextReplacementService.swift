import AppKit
import Foundation

/// ดึงข้อความที่เลือกจากแอปที่โฟกัส แล้วแทนที่ด้วยข้อความที่แปลงแล้ว (ใช้ Cmd+C แล้ว Cmd+V)
enum TextReplacementService {
    /// ดึงข้อความที่เลือกผ่าน pasteboard (ผู้ใช้กด Cmd+C หรือเรา simulate Copy แล้วอ่าน)
    static func getSelectedTextViaPasteboard() async -> String? {
        let pasteboard = NSPasteboard.general
        let oldCount = pasteboard.changeCount
        // Simulate Copy
        let source = CGEventSource(stateID: .combinedSessionState)
        keyPress(keyCode: 8, modifier: .maskCommand, source: source) // Cmd+C (C = 8)
        try? await Task.sleep(nanoseconds: 200_000_000)
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
    ) async {
        guard enabled else { return }
        let original = await getSelectedTextViaPasteboard()
        guard let raw = original?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return }
        if excludeStore.shouldExclude(text: raw) { return }
        let directionUsed: KeyboardLayoutConverter.ConversionDirection
        let converted: String
        if let dir = direction {
            directionUsed = dir
            switch dir {
            case .thaiToEnglish: converted = KeyboardLayoutConverter.convertThaiToEnglish(raw)
            case .englishToThai: converted = KeyboardLayoutConverter.convertEnglishToThai(raw)
            case .none: converted = raw
            }
        } else {
            directionUsed = KeyboardLayoutConverter.dominantLanguage(raw)
            converted = KeyboardLayoutConverter.convertAuto(raw)
        }
        if converted != raw, ConversionValidator.shouldReplace(converted: converted, direction: directionUsed, original: raw) {
            pasteText(converted)
            // สลับคีย์บอร์ดให้ตรงกับภาษาที่แปลงไป เพื่อพิมพ์ต่อได้ทันที
            switch directionUsed {
            case .thaiToEnglish: InputSourceSwitcher.switchTo(.english)
            case .englishToThai: InputSourceSwitcher.switchTo(.thai)
            case .none: break
            }
            // แสดง toast เมื่อเปิดการแจ้งเตือน (task 60)
            let style = UserDefaults.standard.string(forKey: PimPidKeys.notificationStyle) ?? "toast"
            if style != "off" {
                NotificationService.shared.showToast(message: "\(raw) → \(converted)", type: .success)
            }
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

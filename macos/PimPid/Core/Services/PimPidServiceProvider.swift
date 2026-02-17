import AppKit
import Foundation

/// จัดการ NSServices — เมื่อผู้ใช้เลือก "Convert Selected Text - PimPid" จาก Services menu
/// ระบบจะส่ง pasteboard มาให้ เราอ่านข้อความ แปลง แล้วเขียนกลับ
final class PimPidServiceProvider: NSObject {
    @objc
    func convertSelectedText(_ pboard: NSPasteboard, userData: String?, error: NSErrorPointer) {
        guard let raw = pboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return }

        var converted: String?
        var shouldWrite = false
        DispatchQueue.main.sync {
            if ExcludeListStore.shared.shouldExclude(text: raw) { return }
            let direction = KeyboardLayoutConverter.dominantLanguage(raw)
            let result = KeyboardLayoutConverter.convertAuto(raw)
            if result != raw,
               ConversionValidator.shouldReplace(converted: result, direction: direction, original: raw) {
                converted = result
                shouldWrite = true
            }
        }
        guard shouldWrite, let out = converted else { return }
        pboard.clearContents()
        pboard.setString(out, forType: .string)
    }
}

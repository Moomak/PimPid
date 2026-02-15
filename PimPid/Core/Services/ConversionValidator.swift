import AppKit
import Foundation

/// ตรวจว่าผลลัพธ์หลังแปลงควรใช้แทนที่หรือไม่ — ป้องกันแปลงคำไทยที่ถูกต้องเป็นคำผิด (เช่น เทศ→gmL)
/// ใช้ NSSpellChecker ตรวจว่าข้อความหลังแปลงเป็นคำอังกฤษที่ยอมรับได้ (สำหรับทิศทาง Thai→English)
enum ConversionValidator {

    /// ควรแทนที่ด้วยข้อความที่แปลงแล้วหรือไม่
    /// - Parameters:
    ///   - converted: ข้อความหลังแปลงแล้ว (จาก KeyboardLayoutConverter)
    ///   - direction: ทิศทางที่ใช้แปลง
    /// - Returns: true = แทนที่ได้, false = ไม่แทนที่ (เช่น คำไทยที่ตั้งใจพิมพ์)
    static func shouldReplace(converted: String, direction: KeyboardLayoutConverter.ConversionDirection) -> Bool {
        switch direction {
        case .thaiToEnglish:
            return isValidEnglish(converted)
        case .englishToThai:
            return true
        case .none:
            return false
        }
    }

    /// ตรวจว่าข้อความเป็นคำอังกฤษที่ยอมรับได้ (ใช้ NSSpellChecker)
    /// ต้องเรียกจาก main thread
    private static func isValidEnglish(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let words = trimmed.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard !words.isEmpty else { return true }

        let checker = NSSpellChecker.shared
        checker.setLanguage("en")

        for word in words {
            let range = checker.checkSpelling(of: word, startingAt: 0)
            if range.location != NSNotFound {
                return false
            }
        }
        return true
    }
}

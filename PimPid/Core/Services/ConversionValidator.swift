import AppKit
import Foundation

/// ตรวจว่าผลลัพธ์หลังแปลงควรใช้แทนที่หรือไม่
/// Thai→English: แปลงก็ต่อเมื่อผลลัพธ์เป็นคำอังกฤษที่จริง (มีใน dictionary/มีความหมาย) — ต่อให้ต้นทางไม่อยู่ใน list ก็ไม่แปลงถ้าแปลงแล้วไม่มีคำนั้น
/// English→Thai: แปลงก็ต่อเมื่อต้นทางไม่ใช่คำอังกฤษที่ตั้งใจพิมพ์
enum ConversionValidator {

    /// ควรแทนที่ด้วยข้อความที่แปลงแล้วหรือไม่
    static func shouldReplace(converted: String, direction: KeyboardLayoutConverter.ConversionDirection, original: String) -> Bool {
        switch direction {
        case .thaiToEnglish:
            return isValidEnglishForReplace(converted)
        case .englishToThai:
            if original.contains(where: { $0.isNumber }) { return true }
            if !original.allSatisfy({ $0.isLetter || $0 == " " || $0 == "'" }) { return true }
            return !isValidEnglish(original)
        case .none:
            return false
        }
    }

    /// ตรวจว่าข้อความหลังแปลง (Thai→English) ควรใช้แทนที่ได้หรือไม่
    /// ไม่แทนที่ถ้ามีตัวเลข/ punctuation ปน คำเดี่ยวสั้นเกินไป หรือไม่ผ่าน spell check
    private static func isValidEnglishForReplace(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if trimmed.contains(where: { $0.isNumber }) { return false }
        if trimmed.contains(where: { !$0.isLetter && $0 != " " && $0 != "'" }) { return false }
        let words = trimmed.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard !words.isEmpty else { return true }
        if words.count == 1 && words[0].count <= 3 { return false }
        return isValidEnglish(trimmed)
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

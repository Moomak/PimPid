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
            // ต้นทางที่เป็นสระ/วรรณยุกต์นำ (ไม่มีตัวอักษรนำ) มักเป็นคำผิด (พิมพ์ผิด layout) — ให้แปลงเป็นอังกฤษได้
            let originalLikelyWrongLayout = hasLeadingThaiVowelOrSign(original)
            return isValidEnglishForReplace(converted, allowShortWhenOriginalIsSuspiciousThai: originalLikelyWrongLayout)
        case .englishToThai:
            // อย่าแปลงเมื่อเป็นแค่ตัวเลขหรือช่องว่าง (เช่น 897, 154, 897 154) — ไม่มีความหมายเป็นคำไทย
            if !original.contains(where: { $0.isLetter }) {
                return false
            }
            if original.contains(where: { $0.isNumber }) { return true }
            if !original.allSatisfy({ $0.isLetter || $0 == " " || $0 == "'" }) { return true }
            return !isValidEnglish(original)
        case .none:
            return false
        }
    }

    /// ตรวจว่าข้อความหลังแปลง (Thai→English) ควรใช้แทนที่ได้หรือไม่
    /// ไม่แทนที่ถ้ามีตัวเลข/ punctuation ปน หรือไม่ผ่าน spell check
    /// คำเดี่ยวสั้นมาก (≤2 ตัว) ไม่แทนที่ ยกเว้นกรณี allowShortWhenOriginalIsSuspiciousThai (สระนำ = มักผิด layout)
    private static func isValidEnglishForReplace(_ text: String, allowShortWhenOriginalIsSuspiciousThai: Bool = false) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if trimmed.contains(where: { $0.isNumber }) { return false }
        if trimmed.contains(where: { !$0.isLetter && $0 != " " && $0 != "'" }) { return false }
        let words = trimmed.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard !words.isEmpty else { return true }
        // คำเดี่ยว ≤2 ตัว ไม่แทนที่; ถ้าต้นทางเป็นสระนำ (ผิด layout) อนุญาตคำ 2 ตัว เช่น "is", "to"
        let minSingleWordLength = allowShortWhenOriginalIsSuspiciousThai ? 1 : 2
        if words.count == 1 && words[0].count <= minSingleWordLength { return false }
        return isValidEnglish(trimmed)
    }

    /// ข้อความไทยที่ขึ้นต้นด้วยสระหรือวรรณยุกต์ (ไม่มีตัวอักษรนำ) มักเป็นคำผิด (พิมพ์ผิด layout)
    /// Thai consonants = U+0E01..0x0E2E (ก–ฮ), สระ/วรรณยุกต์ = 0x0E2F–0x0E5B
    private static func hasLeadingThaiVowelOrSign(_ text: String) -> Bool {
        guard let first = text.trimmingCharacters(in: .whitespacesAndNewlines).unicodeScalars.first else { return false }
        let v = first.value
        return (v >= 0x0E01 && v <= 0x0E5B) && (v > 0x0E2E)
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

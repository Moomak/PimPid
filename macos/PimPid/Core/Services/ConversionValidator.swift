import AppKit
import Foundation

/// ตรวจว่าผลลัพธ์หลังแปลงควรใช้แทนที่หรือไม่
/// Thai→English: แปลงก็ต่อเมื่อผลลัพธ์เป็นคำอังกฤษที่จริง (มีใน dictionary/มีความหมาย) — ต่อให้ต้นทางไม่อยู่ใน list ก็ไม่แปลงถ้าแปลงแล้วไม่มีคำนั้น
/// English→Thai: แปลงก็ต่อเมื่อต้นทางไม่ใช่คำอังกฤษที่ตั้งใจพิมพ์
enum ConversionValidator {

    /// ควรแทนที่ด้วยข้อความที่แปลงแล้วหรือไม่
    /// หลัก: แปลงแล้วต้องมีความหมาย — ถ้าแปลงแล้วไม่มีความหมาย ไม่ต้องแปลง
    static func shouldReplace(converted: String, direction: KeyboardLayoutConverter.ConversionDirection, original: String) -> Bool {
        switch direction {
        case .thaiToEnglish:
            // ต้นทางเป็นคำไทยที่รู้จัก (เช่น ยัง, เป็น, เก็บ, งงๆ) — ไม่แปลง
            if ThaiWordList.containsKnownThai(original) { return false }
            // ต้นทางเป็นคำนำของคำไทยที่รู้จัก (กำลังพิมพ์อยู่ เช่น เก็ ก่อน เก็บ) — ไม่แปลง
            if ThaiWordList.hasWordWithPrefix(original) { return false }
            // ผลลัพธ์อังกฤษที่มีตัวพิมพ์ใหญ่กลางคำ (เช่น gdH จาก เก็) มักผิด — ไม่แปลง
            if convertedEnglishHasSuspiciousCasing(converted) { return false }
            // แปลงแล้วเป็นคำสั้นมาก + มี apostrophe (เช่น ''q จาก งงๆ) ไม่ใช่คำ — ไม่แปลง
            if convertedLooksLikeGarbageEnglish(converted) { return false }
            // ต้นทางที่เป็นสระ/วรรณยุกต์นำ มักเป็นคำผิด layout — ให้แปลงเป็นอังกฤษได้
            let originalLikelyWrongLayout = hasLeadingThaiVowelOrSign(original)
            return isValidEnglishForReplace(converted, allowShortWhenOriginalIsSuspiciousThai: originalLikelyWrongLayout)
        case .englishToThai:
            // อย่าแปลงเมื่อเป็นแค่ตัวเลขหรือช่องว่าง
            if !original.contains(where: { $0.isLetter }) {
                return false
            }
            // แปลงแล้วต้องมีความหมายเป็นคำไทย หรือเป็น prefix ของคำ (เช่น megd→ทำเก เป็นต้นของ ทำเกม)
            if !ThaiWordList.containsKnownThai(converted) && !ThaiWordList.hasWordWithPrefix(converted) {
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

    /// ผลลัพธ์ที่แปลงแล้วดูไม่ใช่คำ (เช่น ''q จาก งงๆ, py'w'd จาก ยังไงก) — ไม่แทนที่
    private static func convertedLooksLikeGarbageEnglish(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let words = t.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard words.count == 1, let single = words.first else { return false }
        // คำสั้นมาก + มี apostrophe/backtick (เช่น ''q จาก งงๆ)
        if single.count <= 3 {
            let lettersOnly = single.filter(\.isLetter)
            if lettersOnly.count <= 1 && (single.contains("'") || single.contains("`")) { return true }
        }
        // มี apostrophe/backtick มากกว่า 1 ตัว มักเป็นผลจากสระไทย (เช่น py'w'd จาก ยังไงก) — ไม่มีความหมาย
        let apostropheCount = single.filter { $0 == "'" || $0 == "`" }.count
        if apostropheCount >= 2 { return true }
        return false
    }

    /// ผลลัพธ์อังกฤษที่มีตัวพิมพ์ใหญ่กลางคำ (เช่น gdH จาก เก็) มักมาจาก shift+key ในไทย — ไม่ใช้แทนที่
    private static func convertedEnglishHasSuspiciousCasing(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var i = t.startIndex
        while i < t.endIndex {
            let c = t[i]
            if c.isUppercase {
                let isStart = i == t.startIndex
                let afterSpace = i > t.startIndex && t[t.index(before: i)] == " "
                if !isStart && !afterSpace { return true }
            }
            i = t.index(after: i)
        }
        return false
    }

    /// ข้อความไทยที่ขึ้นต้นด้วยสระหรือวรรณยุกต์ (ไม่มีตัวอักษรนำ) มักเป็นคำผิด (พิมพ์ผิด layout)
    /// Thai consonants = U+0E01..0x0E2E (ก–ฮ), สระ/วรรณยุกต์ = 0x0E2F–0x0E5B
    private static func hasLeadingThaiVowelOrSign(_ text: String) -> Bool {
        guard let first = text.trimmingCharacters(in: .whitespacesAndNewlines).unicodeScalars.first else { return false }
        let v = first.value
        return (v >= 0x0E01 && v <= 0x0E5B) && (v > 0x0E2E)
    }

    /// Cache ผล spell check ต่อคำ (task 17) — ลดการเรียก NSSpellChecker ซ้ำ
    private static let spellCacheLock = NSLock()
    private static var spellCache: [String: Bool] = [:]
    private static let spellCacheMax = 500

    /// ตรวจว่าข้อความเป็นคำอังกฤษที่ยอมรับได้ (ใช้ NSSpellChecker + cache)
    /// เรียกตรง ๆ ได้จากทุก thread เพราะ NSSpellChecker.checkSpelling(of:) ไม่ต้องการ main thread
    private static func isValidEnglish(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let words = trimmed.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard !words.isEmpty else { return true }

        if words.contains(where: { $0.count > 50 }) { return false }

        return isValidEnglishImpl(words: words)
    }

    private static func isValidEnglishImpl(words: [String]) -> Bool {
        let checker = NSSpellChecker.shared

        for word in words {
            let lower = word.lowercased()
            spellCacheLock.lock()
            if let cached = spellCache[lower] {
                spellCacheLock.unlock()
                if !cached { return false }
                continue
            }
            spellCacheLock.unlock()

            var wordCount: Int = 0
            let range = checker.checkSpelling(of: word, startingAt: 0, language: "en", wrap: false, inSpellDocumentWithTag: 0, wordCount: &wordCount)
            let valid = range.location == NSNotFound

            spellCacheLock.lock()
            if spellCache.count >= spellCacheMax, let first = spellCache.keys.first {
                spellCache.removeValue(forKey: first)
            }
            spellCache[lower] = valid
            spellCacheLock.unlock()

            if !valid { return false }
        }
        return true
    }
}

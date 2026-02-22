import Foundation

/// Logic การตัดสินใจว่าจะแทนที่คำที่พิมพ์ด้วยอะไร — ใช้ร่วมได้ทั้ง engine จริงและ simulation (ไม่มี app/window)
/// สำหรับจำลองบทความ: รับ word + excludeWords แล้วคืน (converted, direction) หรือ nil
enum AutoCorrectionLogic {

    struct ReplacementResult {
        let converted: String
        let direction: KeyboardLayoutConverter.ConversionDirection
    }

    /// คืนผลลัพธ์ที่ engine จะใช้แทนที่สำหรับ "คำที่ user พิมพ์" (ผิด layout)
    /// ไม่เช็ค app/window — ใช้สำหรับ simulation หรือเมื่อ caller ตรวจแล้ว
    static func replacement(
        for word: String,
        excludeWords: Set<String>
    ) -> ReplacementResult? {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lower = trimmed.lowercased()
        if excludeWords.contains(lower) { return nil }

        let direction = KeyboardLayoutConverter.dominantLanguage(trimmed)
        let converted = KeyboardLayoutConverter.convertAuto(trimmed)

        // กรณี mixed (เช่น "20" พิมพ์ผิดเป็น "/จ") ได้ direction .none — ลอง Thai→English ถ้าผลเป็นตัวเลขให้ใช้
        if direction == .none {
            let asEnglish = KeyboardLayoutConverter.convertThaiToEnglish(trimmed)
            if asEnglish != trimmed,
               Self.looksLikeNumber(asEnglish),
               ConversionValidator.shouldReplace(converted: asEnglish, direction: .thaiToEnglish, original: trimmed) {
                return ReplacementResult(converted: asEnglish, direction: .thaiToEnglish)
            }
            return nil
        }

        guard converted != trimmed else { return nil }

        guard ConversionValidator.shouldReplace(converted: converted, direction: direction, original: trimmed) else {
            return nil
        }

        return ReplacementResult(converted: converted, direction: direction)
    }

    private static func looksLikeNumber(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return false }
        let dots = t.filter { $0 == "." }.count
        return t.allSatisfy { $0.isNumber || $0 == "." } && dots <= 1
    }
}

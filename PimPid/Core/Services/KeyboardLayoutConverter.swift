import Foundation

/// แปลงข้อความระหว่างภาษาไทย (คีย์บอร์ด Kedmanee) กับอังกฤษ (QWERTY) ตามตำแหน่งปุ่มเดียวกัน
struct KeyboardLayoutConverter {
    private static let thaiToEnglish: [Character: Character] = [
        "ๅ": "`", "๑": "1", "๒": "2", "๓": "3", "๔": "4", "๕": "5", "๖": "6", "๗": "7", "๘": "8", "๙": "9", "๐": "0", "-": "-", "=": "=",
        "ๆ": "q", "ไ": "w", "ำ": "e", "พ": "r", "ะ": "t", "ั": "y", "ี": "u", "ร": "i", "น": "o", "ย": "p", "บ": "[", "ล": "]",
        "ฟ": "a", "ห": "s", "ก": "d", "ด": "f", "้": "g", "่": "h", "จ": "j", "ข": "k", "ิ": "l", "์": ";", "\"": "'",
        "ผ": "z", "ป": "x", "แ": "c", "อ": "v", "็": "b", "ื": "n", "ท": "m", "ม": ",", "ใ": ".", "ฝ": "/",
        "ฤ": "1", "ู": "2", "ฺ": "3", "ฎ": "4", "ฏ": "5", "ฐ": "6", "ฑ": "7", "ฒ": "8", "ณ": "9", "ฯ": "0",
        " ": " "
    ]

    private static var englishToThai: [Character: Character] = {
        var map: [Character: Character] = [:]
        for (thai, eng) in thaiToEnglish {
            map[eng] = thai
        }
        return map
    }()

    /// ตรวจว่าเป็นตัวอักษรไทย (ช่วง Unicode Thai)
    static func isThai(_ c: Character) -> Bool {
        guard let scalar = c.unicodeScalars.first else { return false }
        let v = scalar.value
        return (v >= 0x0E01 && v <= 0x0E5B) || (v >= 0x0E50 && v <= 0x0E59) // ไทย + ตัวเลขไทย
    }

    /// ตรวจว่าเป็นตัวอักษรอังกฤษ (ละติน)
    static func isEnglish(_ c: Character) -> Bool {
        c.isASCII && (c.isLetter || c.isNumber || "`-=[];',./ ".contains(c))
    }

    /// ตรวจว่าข้อความส่วนใหญ่เป็นภาษาไหน (ใช้ตัดสินใจทิศทางแปลง)
    static func dominantLanguage(_ text: String) -> ConversionDirection {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .none }
        var thaiCount = 0
        var engCount = 0
        for c in trimmed {
            if isThai(c) { thaiCount += 1 }
            else if isEnglish(c) { engCount += 1 }
        }
        if thaiCount > engCount { return .thaiToEnglish }
        if engCount > thaiCount { return .englishToThai }
        return .none
    }

    enum ConversionDirection {
        case thaiToEnglish
        case englishToThai
        case none
    }

    /// แปลงไทย → อังกฤษ (ตามตำแหน่งปุ่ม)
    static func convertThaiToEnglish(_ text: String) -> String {
        text.map { thaiToEnglish[$0] ?? $0 }.map(String.init).joined()
    }

    /// แปลงอังกฤษ → ไทย (ตามตำแหน่งปุ่ม)
    static func convertEnglishToThai(_ text: String) -> String {
        text.map { englishToThai[$0] ?? $0 }.map(String.init).joined()
    }

    /// แปลงอัตโนมัติตามภาษาที่เดาได้
    static func convertAuto(_ text: String) -> String {
        switch dominantLanguage(text) {
        case .thaiToEnglish: return convertThaiToEnglish(text)
        case .englishToThai: return convertEnglishToThai(text)
        case .none: return text
        }
    }
}

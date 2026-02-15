import Foundation

/// แปลงข้อความระหว่างภาษาไทย (คีย์บอร์ด Kedmanee) กับอังกฤษ (QWERTY) ตามตำแหน่งปุ่มเดียวกัน
///
/// IMPORTANT: Thai combining marks (sara am ั, sara ii ี, mai ek ่, etc.) combine with preceding
/// consonants into grapheme clusters in Swift's `Character` type. We use `Unicode.Scalar` keys
/// to ensure each code point is looked up individually.
struct KeyboardLayoutConverter {

    // MARK: - Kedmanee Layout Mapping (English key → Thai character)
    // Source of truth: each English key maps to exactly one Thai character.
    // thaiToEnglish is derived by inverting this (no conflicts in that direction).

    /// Unshifted keys
    private static let englishToThaiUnshifted: [Unicode.Scalar: Unicode.Scalar] = [
        // Number row
        "`": "ๅ", "1": "ๆ", "2": "/", "3": "-", "4": "ภ", "5": "ถ",
        "6": "ุ", "7": "ึ", "8": "ค", "9": "ต", "0": "จ", "-": "ข", "=": "ช",
        // Top row (QWERTY)
        "q": "ๆ", "w": "ไ", "e": "ำ", "r": "พ", "t": "ะ", "y": "ั",
        "u": "ี", "i": "ร", "o": "น", "p": "ย", "[": "บ", "]": "ล", "\\": "ฃ",
        // Home row (ASDF)
        "a": "ฟ", "s": "ห", "d": "ก", "f": "ด", "g": "เ", "h": "้",
        "j": "่", "k": "า", "l": "ส", ";": "ว", "'": "ง",
        // Bottom row (ZXCV)
        "z": "ผ", "x": "ป", "c": "แ", "v": "อ", "b": "ิ", "n": "ื",
        "m": "ท", ",": "ม", ".": "ใ", "/": "ฝ",
        // Space
        " ": " ",
    ]

    /// Shifted keys
    private static let englishToThaiShifted: [Unicode.Scalar: Unicode.Scalar] = [
        // Number row (shifted)
        "~": "%", "!": "+", "@": "๑", "#": "๒", "$": "๓", "%": "๔",
        "^": "ู", "&": "฿", "*": "๕", "(": "๖", ")": "๗", "_": "๘", "+": "๙",
        // Top row (shifted)
        "Q": "๐", "W": "\"", "E": "ฎ", "R": "ฑ", "T": "ธ", "Y": "ํ",
        "U": "๊", "I": "ณ", "O": "ฯ", "P": "ญ", "{": "ฐ", "}": ",", "|": "ฅ",
        // Home row (shifted)
        "A": "ฤ", "S": "ฆ", "D": "ฏ", "F": "โ", "G": "ฌ", "H": "็",
        "J": "๋", "K": "ษ", "L": "ศ", ":": "ซ", "\"": ".",
        // Bottom row (shifted)
        "Z": "(", "X": ")", "C": "ฉ", "V": "ฮ", "B": "ฺ", "N": "์",
        "M": "?", "<": "ฒ", ">": "ฬ", "?": "ฦ",
    ]

    /// Combined English → Thai (unshifted + shifted)
    private static let englishToThai: [Unicode.Scalar: Unicode.Scalar] = {
        var map = englishToThaiUnshifted
        for (k, v) in englishToThaiShifted {
            map[k] = v
        }
        return map
    }()

    /// Thai → English (inverted from englishToThai)
    private static let thaiToEnglish: [Unicode.Scalar: Unicode.Scalar] = {
        var map: [Unicode.Scalar: Unicode.Scalar] = [:]
        for (eng, thai) in englishToThai {
            map[thai] = eng
        }
        return map
    }()

    /// ตรวจว่าเป็นตัวอักษรไทย (ช่วง Unicode Thai)
    static func isThai(_ c: Character) -> Bool {
        guard let scalar = c.unicodeScalars.first else { return false }
        let v = scalar.value
        return (v >= 0x0E01 && v <= 0x0E5B)
    }

    /// ตรวจว่า Unicode scalar เป็นภาษาไทย
    private static func isThai(_ scalar: Unicode.Scalar) -> Bool {
        let v = scalar.value
        return (v >= 0x0E01 && v <= 0x0E5B)
    }

    /// ตรวจว่า Unicode scalar เป็นภาษาอังกฤษ/ASCII
    private static func isEnglish(_ scalar: Unicode.Scalar) -> Bool {
        scalar.isASCII
    }

    /// ตรวจว่าเป็นตัวอักษรอังกฤษ (ละติน)
    static func isEnglish(_ c: Character) -> Bool {
        c.isASCII && (c.isLetter || c.isNumber || "`-=[];',./ ~!@#$%^&*()_+{}|:\"<>?\\".contains(c))
    }

    /// ตรวจว่าข้อความส่วนใหญ่เป็นภาษาไหน (ใช้ตัดสินใจทิศทางแปลง)
    /// ใช้ unicodeScalars เพื่อนับ combining marks แยกจากตัวอักษรหลัก
    static func dominantLanguage(_ text: String) -> ConversionDirection {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .none }
        var thaiCount = 0
        var engCount = 0
        for scalar in trimmed.unicodeScalars {
            if isThai(scalar) { thaiCount += 1 }
            else if isEnglish(scalar) && scalar != " " { engCount += 1 }
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
    /// ใช้ unicodeScalars เพราะ Thai combining marks รวมกับ consonant เป็น grapheme cluster
    static func convertThaiToEnglish(_ text: String) -> String {
        var result = ""
        for scalar in text.unicodeScalars {
            if let mapped = thaiToEnglish[scalar] {
                result.unicodeScalars.append(mapped)
            } else {
                result.unicodeScalars.append(scalar)
            }
        }
        return result
    }

    /// แปลงอังกฤษ → ไทย (ตามตำแหน่งปุ่ม)
    static func convertEnglishToThai(_ text: String) -> String {
        var result = ""
        for scalar in text.unicodeScalars {
            if let mapped = englishToThai[scalar] {
                result.unicodeScalars.append(mapped)
            } else {
                result.unicodeScalars.append(scalar)
            }
        }
        return result
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

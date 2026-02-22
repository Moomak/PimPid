import Foundation

/// แปลงข้อความระหว่างภาษาไทย (คีย์บอร์ด Kedmanee) กับอังกฤษ (QWERTY) ตามตำแหน่งปุ่มเดียวกัน
/// Task 101: โครงสร้างรองรับ layout อังกฤษอื่น (เช่น Dvorak) — เพิ่ม mapping อื่นได้โดยไม่แตะ Kedmanee
///
/// Unicode Thai block (U+0E01–U+0E5B):
/// - Consonants: U+0E01–U+0E2E (ก–ฮ)
/// - Vowels / tone marks: U+0E2F–U+0E5B (ฯ–๛); ตัวเหล่านี้รวมกับพยัญชนะหน้าเป็น grapheme cluster
/// เราจึงใช้ `Unicode.Scalar` เป็น key ในการแมป ไม่ใช้ `Character`
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

    /// เลือกคีย์ที่เหมาะสำหรับ Thai→English เมื่อมีหลายคีย์แมปถึงตัวไทยเดียวกัน:  prefer ตัวเลข/สัญลักษณ์ over ตัวอักษร
    private static func preferKeyForThaiToEnglish(_ eng: Unicode.Scalar, over existing: Unicode.Scalar) -> Bool {
        let e = Character(eng), x = Character(existing)
        if e.isNumber && !x.isNumber { return true }
        if e.isNumber == x.isNumber && !e.isLetter && x.isLetter { return true }
        return false
    }

    /// Thai → English (inverted from englishToThai)
    private static let thaiToEnglish: [Unicode.Scalar: Unicode.Scalar] = {
        var map: [Unicode.Scalar: Unicode.Scalar] = [:]
        for (eng, thai) in englishToThai {
            map[thai] = eng
        }
        return map
    }()

    /// Task 13 + Task 9: โหลด mapping ตามชื่อ layout (KeyboardLayout.plist หรือ KeyboardLayout-<name>.plist)
    private static let overlayCacheLock = NSLock()
    private static var overlayCache: [String: [Unicode.Scalar: Unicode.Scalar]?] = [:]

    // MARK: - Effective map cache
    private static let mapCacheLock = NSLock()
    private static var _cachedLayoutName: String? = nil
    private static var _cachedEffectiveE2T: [Unicode.Scalar: Unicode.Scalar]? = nil
    private static var _cachedEffectiveT2E: [Unicode.Scalar: Unicode.Scalar]? = nil

    /// สร้าง (E→T, T→E) หนึ่งครั้งต่อ layout name แล้ว cache ไว้ — เร็วกว่า rebuild ทุกครั้ง
    private static func effectiveMaps() -> (e2t: [Unicode.Scalar: Unicode.Scalar], t2e: [Unicode.Scalar: Unicode.Scalar]) {
        let name = currentThaiLayoutName
        mapCacheLock.lock()
        defer { mapCacheLock.unlock() }
        if name == _cachedLayoutName, let e2t = _cachedEffectiveE2T, let t2e = _cachedEffectiveT2E {
            return (e2t, t2e)
        }
        var e2t = englishToThai
        if let overlay = loadBundleMapping(forLayoutName: name) {
            for (k, v) in overlay { e2t[k] = v }
        }
        // สร้าง T→E โดยเมื่อมีหลาย eng แมปถึง thai เดียวกัน ให้เลือกตัวเลข/สัญลักษณ์ก่อน (เช่น  ๆ → "1" ไม่ใช่ "q") เพื่อให้ตัวเลข round-trip ถูกต้อง
        var t2e: [Unicode.Scalar: Unicode.Scalar] = [:]
        for (eng, thai) in e2t {
            if let existing = t2e[thai] {
                if preferKeyForThaiToEnglish(eng, over: existing) { t2e[thai] = eng }
            } else {
                t2e[thai] = eng
            }
        }
        _cachedEffectiveE2T = e2t
        _cachedEffectiveT2E = t2e
        _cachedLayoutName = name
        return (e2t, t2e)
    }

    private static func loadBundleMapping(forLayoutName name: String?) -> [Unicode.Scalar: Unicode.Scalar]? {
        let key = name ?? "kedmanee"
        overlayCacheLock.lock()
        if let cached = overlayCache[key] {
            overlayCacheLock.unlock()
            return cached
        }
        overlayCacheLock.unlock()

        let baseName = (key == "kedmanee" || key.isEmpty) ? "KeyboardLayout" : "KeyboardLayout-\(key)"
        let dict: [String: String]?
        if let url = Bundle.main.url(forResource: baseName, withExtension: "plist"),
           let plist = NSDictionary(contentsOf: url) as? [String: String] {
            dict = plist
        } else if let url = Bundle.main.url(forResource: baseName, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            dict = decoded
        } else {
            dict = nil
        }
        var result: [Unicode.Scalar: Unicode.Scalar]? = nil
        if let d = dict, !d.isEmpty {
            var overlay: [Unicode.Scalar: Unicode.Scalar] = [:]
            for (k, v) in d {
                guard let kScalar = k.unicodeScalars.first, k.unicodeScalars.count == 1,
                      let vScalar = v.unicodeScalars.first, v.unicodeScalars.count == 1 else { continue }
                overlay[kScalar] = vScalar
            }
            result = overlay.isEmpty ? nil : overlay
        }
        overlayCacheLock.lock()
        overlayCache[key] = result
        overlayCacheLock.unlock()
        return result
    }

    /// ชื่อ layout ไทยจาก settings (ค่าเริ่มต้น kedmanee)
    private static var currentThaiLayoutName: String {
        UserDefaults.standard.string(forKey: PimPidKeys.thaiKeyboardLayout) ?? "kedmanee"
    }

    /// English → Thai ที่ใช้จริง (จาก cache — rebuild เมื่อ layout เปลี่ยนเท่านั้น)
    private static var effectiveEnglishToThai: [Unicode.Scalar: Unicode.Scalar] { effectiveMaps().e2t }

    /// Thai → English ที่ใช้จริง (จาก cache — rebuild เมื่อ layout เปลี่ยนเท่านั้น)
    private static var effectiveThaiToEnglish: [Unicode.Scalar: Unicode.Scalar] { effectiveMaps().t2e }

    /// ตรวจว่าเป็นตัวอักษรไทย (ช่วง Unicode Thai)
    static func isThai(_ c: Character) -> Bool {
        guard let scalar = c.unicodeScalars.first else { return false }
        let v = scalar.value
        return (v >= 0x0E01 && v <= 0x0E5B)
    }

    /// ตรวจว่า Unicode scalar เป็นภาษาไทย (U+0E01–U+0E5B: พยัญชนะ + สระ + วรรณยุกต์)
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

    /// Task 14: ตัวเลขและสัญลักษณ์ — ผ่านการแมปตามตาราง layout (มีใน englishToThai/thaiToEnglish)
    /// ส่วนที่ไม่มีในตารางจะไม่ถูกแปลง (append scalar เดิม) ดังนั้นข้อความผสมตัวเลขจะแปลงเฉพาะตัวอักษร

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
        let map = effectiveThaiToEnglish
        var result = ""
        for scalar in text.unicodeScalars {
            if let mapped = map[scalar] {
                result.unicodeScalars.append(mapped)
            } else {
                result.unicodeScalars.append(scalar)
            }
        }
        return result
    }

    /// แปลงอังกฤษ → ไทย (ตามตำแหน่งปุ่ม)
    static func convertEnglishToThai(_ text: String) -> String {
        let map = effectiveEnglishToThai
        var result = ""
        for scalar in text.unicodeScalars {
            if let mapped = map[scalar] {
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

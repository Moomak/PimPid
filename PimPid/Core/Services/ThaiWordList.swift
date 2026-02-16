import Foundation

/// รายการคำไทยที่ถือว่าเป็นคำที่ตั้งใจพิมพ์ — ไม่แปลงเป็นอังกฤษ (ป้องกัน ประ→xit, เจอ→g0v, ประเทศ→...)
/// โหลดจากคำในตัวแอป (embedded) และถ้ามีไฟล์ ThaiWords.txt ใน bundle จะโหลดเพิ่ม
enum ThaiWordList {
    private static let lock = NSLock()
    private static var _words: Set<String>?
    static var words: Set<String> {
        lock.lock()
        defer { lock.unlock() }
        if let w = _words { return w }
        var set = Set(embeddedWords)
        if let extra = loadFromBundle() { set.formUnion(extra) }
        _words = set
        return set
    }

    /// ตรวจว่าข้อความเป็นคำไทยที่รู้จัก (ทั้งก้อนหรือทุกคำในข้อความ)
    /// ถ้าใช่ = ไม่ควรแปลง Thai→English
    static func containsKnownThai(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let tokenized = trimmed.split(separator: " ").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !tokenized.isEmpty else { return false }
        let w = words
        return tokenized.allSatisfy { w.contains($0) }
    }

    /// ตรวจว่ามีคำไทยที่รู้จักที่ขึ้นต้นด้วย prefix นี้ (เช่น เก็ เป็นต้นของ เก็บ) — กำลังพิมพ์อยู่ ไม่แปลง
    static func hasWordWithPrefix(_ prefix: String) -> Bool {
        let p = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard p.unicodeScalars.count >= 2 else { return false }
        let w = words
        return w.contains { $0.hasPrefix(p) }
    }

    private static func loadFromBundle() -> Set<String>? {
        let bundles: [Bundle] = {
            #if canImport(AppKit)
            return [Bundle.main, Bundle.module]
            #else
            return [Bundle.module]
            #endif
        }()
        for bundle in bundles {
            if let url = bundle.url(forResource: "ThaiWords", withExtension: "txt"),
               let set = loadWords(from: url) {
                return set
            }
        }
        return nil
    }

    private static func loadWords(from url: URL) -> Set<String>? {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else { return nil }
        let lines = content.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
        return Set(lines)
    }

    /// คำไทยที่ฝังในแอป (คำที่พบบ่อยและเคยทำให้ถูกแปลงผิด)
    private static var embeddedWords: [String] {
        EmbeddedThaiWords.list
    }
}

/// คำไทยที่ฝังในแอป — แก้ไข/เพิ่มได้ที่ไฟล์นี้ หรือใช้ ThaiWords.txt ใน bundle
private enum EmbeddedThaiWords {
    static let list: [String] = embeddedString
        .split(separator: "\n")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
    private static let embeddedString = """
ประเทศ
เทศ
รัก
ช่วย
ประ
เจอ
ครับ
ค่ะ
เป็น
อยู่
ที่
และ
หรือ
แต่
จะ
ได้
ไว้
ไป
มา
ว่า
นี้
นั้น
อะไร
ทำ
มาก
น้อย
มิ้ง
ดี
ไม่
มี
ให้
กับ
ใน
บน
ขึ้น
ลง
ใหญ่
เล็ก
ใหม่
เก่า
คน
งาน
วัน
คืน
ปี
เรา
เขา
เธอ
ฉัน
ผม
คุณ
ใคร
อย่างไร
เพราะ
เนื่องจาก
ก่อน
หลัง
ระหว่าง
เกี่ยวกับ
ตาม
ต่อ
โดย
จาก
ถึง
จน
ตั้งแต่
เกือบ
ค่อนข้าง
คิด
รู้
เห็น
กิน
ดื่ม
นอน
ทำงาน
เรียน
สอน
ดู
ฟัง
อ่าน
เขียน
พูด
เปิด
ปิด
สูง
ต่ำ
ยาว
สั้น
เร็ว
ช้า
ดีกว่า
แย่
ถูก
ผิด
จริง
เท็จ
อย่างไรก็ตาม
ก่อนอื่น
สุดท้าย
อย่างน้อย
อย่างมาก
แม้ว่า
ถ้า
หาก
ถึงแม้
เพราะว่า
นั่น
โน่น
นี่
ครับผม
ขอบคุณ
ขอโทษ
ไม่เป็นไร
ได้เลย
คะ
จ้ะ
จ้า
นะ
นะครับ
นะคะ
ใช่
ไม่ใช่
อาจ
ต้อง
ควร
อยาก
ต้องการ
ชอบ
เกลียด
กลัว
ดีใจ
เสียใจ
รู้สึก
บางที
บางครั้ง
มัก
กำลัง
เคย
เพิ่ง
ยัง
เกือบจะ
เพียง
แค่
มากมาย
ดีมาก
แย่มาก
สวย
ใหญ่โต
เร็วมาก
ช้ามาก
หนัก
เบา
หนา
บาง
กว้าง
แคบ
ลึก
ตื้น
เต็ม
ว่าง
เปล่า
ง่าย
ยาก
ร้อน
หนาว
สุข
เศร้า
สนุก
น่าเบื่อ
น่าสนใจ
ปลอดภัย
อันตราย
สะอาด
สกปรก
สว่าง
มืด
เงียบ
ดัง
แข็ง
นุ่ม
เรียบ
เปียก
แห้ง
หวาน
ขม
เค็ม
จืด
เผ็ด
เย็น
อุ่น
"""
}
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
        if let cached = ThaiWordListLoader.cachedWordsIfAvailable {
            _words = cached
            return cached
        }
        var set = Set(embeddedWords)
        if let extra = loadFromBundle() { set.formUnion(extra) }
        _words = set
        return set
    }

    /// ตัวอักษร  ๆ (ไม้ยมก U+0E46 / repetition mark) — ถ้าต่อท้ายคำ ให้ถือว่าเป็นคำเดียวกัน (งงๆ = งง)
    /// Task 24: รูปแบบอื่นของไม้ยมกถ้ามีใน Unicode สามารถเพิ่มในเช็คเดียวกันได้
    private static let thaiRepetitionMark = "\u{0E46}"

    /// ตรวจว่าข้อความเป็นคำไทยที่รู้จัก (ทั้งก้อนหรือทุกคำในข้อความ)
    /// ถ้าใช่ = ไม่ควรแปลง Thai→English
    /// รองรับคำลงท้าย  ๆ เช่น งงๆ (ถือว่าเป็นคำว่า งง)
    /// รองรับคำไทยติดกันไม่มีเว้นวรรค เช่น ไม่เป็น = ไม่ + เป็น (greedy longest-match)
    static func containsKnownThai(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let tokenized = trimmed.split(separator: " ").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard !tokenized.isEmpty else { return false }
        let w = words
        return tokenized.allSatisfy { token in
            if w.contains(token) { return true }
            if token.hasSuffix(thaiRepetitionMark) {
                let base = String(token.dropLast(thaiRepetitionMark.count))
                if !base.isEmpty, w.contains(base) { return true }
            }
            // Thai word segmentation: ลองแยกคำไทยติดกัน (greedy longest-match)
            if canDecomposeIntoKnownWords(token, wordSet: w) { return true }
            return false
        }
    }

    /// แยกข้อความไทยที่ไม่มีเว้นวรรคเป็นคำที่รู้จัก (dynamic programming)
    /// เช่น "ไม่เป็น" → "ไม่" + "เป็น"
    /// กำหนดให้แต่ละ segment ต้องยาว ≥ 2 ตัวอักษร (ป้องกัน false positive จากคำ 1 ตัว)
    private static func canDecomposeIntoKnownWords(_ text: String, wordSet w: Set<String>) -> Bool {
        let chars = Array(text)
        let n = chars.count
        guard n >= 4 else { return false } // ต้องแยกเป็น 2+ คำ แต่ละคำ ≥ 2 ตัว

        let maxWordLen = min(n, 20)
        let minWordLen = 2

        // dp[i] = true ถ้า chars[0..<i] แยกเป็นคำ (≥ 2 ตัว) ที่รู้จักได้ทั้งหมด
        var dp = [Bool](repeating: false, count: n + 1)
        dp[0] = true

        for i in minWordLen...n {
            for j in stride(from: i - minWordLen, through: 0, by: -1) {
                guard dp[j] else { continue }
                if i - j > maxWordLen { break }
                let sub = String(chars[j..<i])
                if w.contains(sub) {
                    dp[i] = true
                    break
                }
            }
        }

        guard dp[n] else { return false }

        // ต้องมี split point ระหว่างทาง (ไม่ใช่ match ทั้งก้อน ซึ่ง handled แล้วข้างบน)
        for mid in minWordLen...(n - minWordLen) {
            if dp[mid] {
                let suffixChars = Array(chars[mid...])
                if decomposeAll(suffixChars, wordSet: w, minLen: minWordLen, maxLen: maxWordLen) {
                    return true
                }
            }
        }
        return false
    }

    private static func decomposeAll(_ chars: [Character], wordSet w: Set<String>, minLen: Int, maxLen: Int) -> Bool {
        let n = chars.count
        guard n >= minLen else { return false }
        var dp = [Bool](repeating: false, count: n + 1)
        dp[0] = true
        for i in minLen...n {
            for j in stride(from: i - minLen, through: 0, by: -1) {
                guard dp[j] else { continue }
                if i - j > maxLen { break }
                if w.contains(String(chars[j..<i])) {
                    dp[i] = true
                    break
                }
            }
        }
        return dp[n]
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

/// คำไทยที่ฝังในแอป — แก้ไข/เพิ่มได้ที่ไฟล์นี้ หรือใช้ ThaiWords.txt ใน bundle (internal สำหรับ ThaiWordListLoader)
enum EmbeddedThaiWords {
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
ไปที่
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
ยังไง
ยังไงก็
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
เสร็จ
เสรี
เสริม
สนุก
เกม
ทำเกม
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
พก
ใบ
ออก
รอ
สัก
ครึ่ง
แต่ง
ตัว
ใส่
ซึ่ง
ตน
ความ
แนะนำ
จัดสรร
สบาย
พร้อม
รู้จัก
ย่าน
แจ่มชัด
ซึมซับ
เสน่ห์
รส
แท้
สะดุดตา
ผนึก
กระเป๋า
ผ้า
นาที
ผ่าน
ฟ้า
บริเวณ
เต็ม
ตึก
สูง
ระฟ้า
ก้าว
รุด
หน้า
จังหวะ
เร่ง
รีบ
เกิน
เปิด
ฉ่ำ
มอบ
ประสบการณ์
ซ้ำ
แตกต่าง
หา
ทั่ว
โลก
ละ
ตัวตน
อาหาร
รส
สิ่ง
ก่อสร้าง
สะดุดตา
เรื่องราว
นานัปการ
เขต
พระนคร
นำ
ข้าม
สำรวจ
แนว
กำแพง
โบราณ
เหลือ
เลือก
เดิน
กว่า
แห่ง
มัก
ตาม
รูป
มือ
ปิด
ความ
เมื่อ
คราว
หลวง
บรรยากาศ
สาย
หลาย
ทอด
บรรจบ
ราว
ร้อย
ต้น
ป้อม
รับมือ
ข้าศึก
ยก
เข้า
ตี
ทิศ
ตะวันออก
ด้วย
ก็
อย่าง
ชม
มุม
จึง
ถึง
ฝูง
ลง
สู่
หนังสือ
ทักษะ
ใช้
แทน
โอกาส
ลิ้มรส
วัง
ขุนนาง
หู
น้ำมัน
เดือด
พล่าน
ชวน
หวาดหวั่น
เรียกว่า
คลอง
รอบ
กรุง
สี่
แยก
ป้าย
เด่น
หรา
ระบุ
คาเฟ่
ตกแต่ง
เก๋
ย้าย
นาน
ตา
นัก
อ่าน
กรุงเทพ
โอบ
ล้อม
ทุก
ด้าน
ห่าง
ทรง
เทพ
สถาปนา
ได้รับ
ผ่านมา
แทรก
ตัวอย่าง
กลมกลืน
ยุค
เริ่มต้น
เข้าใจ
เยือน
ภาพรวม
อดีต
ด้านหลัง
บ้านพัก
ท่ามกลาง
ร่มรื่น
ไม่ไกล
อุทิศ
ถือเป็น
แห่งแรก
ภายใน
เงียบสงบ
เต็มอิ่ม
ออกเดินทาง
หมู่บ้าน
เครื่องปั้น
ดินเผา
ใจกลาง
กิโลเมตร
พิกัด
แถบ
ประมาณ
เสร็จ
กลับบ้าน
พลาด
ตำรับ
แรงบันดาลใจ
ภูมิภาค
วัตถุดิบ
พิเศษ
คึกคัก
เฉพาะตัว
ด้านล่าง
ดัดแปลง
สมัยใหม่
กิจกรรม
ตระเวน
ต้นกำเนิด
คิดค้น
แวะ
ส่วนผสม
สดชื่น
คลายร้อน
โดยเฉพาะ
สองข้าง
ขบวน
ซ่อน
ตรอก
ชื่นชอบ
สัญจร
ไปมา
ดื่มด่ำ
มุ่งหน้า
ทะเลสาบ
ไปยัง
ด้านข้าง
ทอดผ่าน
เกาะกลาง
สูงกว่า
รูปแบบ
เติมพลัง
ร้านดัง
กินพร้อม
นานาชนิด
ผักสด
ไม่อั้น
อร่อย
เต็มไปด้วย
อาทิ
ต้นแบบ
เก็บรวบรวม
ค้นพบ
นับหมื่น
เกิดขึ้น
สูตร
ต้นตำรับ
ลงตัว
ความอร่อย
เนื้อนุ่ม
เครื่องเคียง
สารพัด
ให้บริการ
ตรง
วันละ
เมือง
สำรอง
การ
เงิน
นำเรื่อง
วาง
ลี้
จำนวน
ประเด็น
รวดเร็ว
ตัวละคร
เผยแพร่
จุดประสงค์
วิจัย
ประกอบด้วย
หัวเรื่อง
เนื้อเรื่อง
สรุป
แก่นเรื่อง
หน่วยงาน
ประสาน
ดำเนินงาน
เป้าหมาย
ฤดูกาล
จอง
ล่วงหน้า
ค่าใช้จ่าย
สม่ำเสมอ
แจ่มใส
เด็ก
ทฤษฎี
ผลไม้
ที่สุด
สุขภาพ
ความสำคัญ
รู้เท่าทัน
โรค
พัฒนา
ต่อเนื่อง
ต้องการ
รักษา
เร่งด่วน
ความสนใจ
เรียนรู้
จำเป็น
อนาคต
ข่าวสาร
พักผ่อน
เพียงพอ
ขนาด
เคล็ดลับ
สิ่งพิมพ์
อิเล็กทรอนิกส์
ปลัด
กระทรวง
สหกรณ์
ประธาน
กรรมการ
บริหาร
ประชุม
คณะ
เยียวยา
ภาวะ
หนี้เสีย
มาตรการ
วิถี
เทศกาล
ธรรมเนียม
เคารพ
เอกลักษณ์
แสดง
ความเชื่อ
หน้าที่
รหัสผ่าน
ข้อมูล
ความปลอดภัย
ปัจจุบัน
ชีวิตประจำวัน
ระบบ
จัดจ้าน
หลากหลาย
เมนู
นิยม
ต่างชาติ
สดใหม่
ปรุง
ถูกวิธี
ปลอดภัย
ล้างมือ
รับประทาน
วอร์ม
บาดเจ็บ
กล้ามเนื้อ
คลายตัว
สมดุล
สิ่งแวดล้อม
รุ่นหลัง
พลาสติก
แยกขยะ
ปลูก
ต้นไม้
เลี้ยง
พืช
อากาศ
สงบ
งานอดิเรก
ครอบครัว
หน่วย
สังคม
ความสัมพันธ์
เลี้ยงดู
เติบโต
คุณภาพ
ความรัก
ความเข้าใจ
แบบอย่าง
ลูก
ปีนี้
แข็งแรง
จิตใจ
สวยงาม
ศึกษา
โทรศัพท์
พูดคุย
สั่งการ
เกษตรกร
ทุกครั้ง
สื่อสาร
เปิดเผย
รับฟัง
ความเห็น
เพื่อนร่วมงาน
จัดสรรเวลา
ป้องกัน
ความเครียด
ประสิทธิภาพ
ธุรกิจ
ขนาดเล็ก
กำลัง
เศรษฐกิจ
สินค้า
บริการ
แข่งขัน
ตลาด
วิเคราะห์
ต้นทุน
รอบคอบ
ความเสี่ยง
โอกาส
ความสำเร็จ
ลูกค้า
พึงพอใจ
แผน
หลัก
น่าอยู่
ลด
ทิ้ง
ทำสวน
ท้องถิ่น
สะท้อน
รักษา
ตั้ง
แชร์
ที่บ้าน
ว่ายน้ำ
วิ่ง
ยืดเส้น
ต้มยำ
ผัดไทย
ส้มตำ
ครั้ง
แยก
เห็น
หลายคน
ใช้เวลา
ร่วมกัน
เร็วขึ้น
กลาง
ทำ
เพิ่ม
กล่าว
แนวทาง
ทบทวน
ออกจาก
อีกครั้ง
สมทบ
จึงจะ
หารือ
ศึกษามาตรการ
เกิด
สินไหมทดแทน
ทุกกรณี
โครงการ
ข้าวนาปี
การผลิต
ที่ได้
น้ำซุป
ที่ซับซ้อน
ที่มีคุณค่า
ที่เหมาะสม
ความรับผิดชอบ
ความทรงจำ
ข้อพิพาท
สิทธิ
หน้าที่
รัฐธรรมนูญ
ต้นฉบับ
บริบท
สำนวน
พยากรณ์
กลางแจ้ง
อาการ
ไม่สบาย
เภสัชกร
ความเป็นธรรม
พื้นฐาน
ไว้ใจ
ผู้เชี่ยวชาญ
ภาพยนตร์
วัดผล
หัวใจ
เข้าถึง
ละเมิด
ลงทุน
หลีกเลี่ยง
แพทย์
ความสงบ
กฎหมาย
สร้างความ
สมอง
ขั้นตอน
เกี่ยวข้อง
ขอคำปรึกษา
ลงนาม
ทำซ้ำ
ความจำ
จินตนาการ
สร้างสรรค์
ผลงาน
ความละเอียดอ่อน
มุมมอง
แกลเลอรี่
ประติมากรรม
ภาพวาด
ยุคสมัย
วินัย
โลกทัศน์
เล่ม
สัตวแพทย์
ฝึกสอน
อารมณ์
จังหวะ
ทำนอง
เครื่องดนตรี
กีตาร์
เปียโน
กลอง
นิสัย
นิยาย
สารคดี
ประเภท
บันเทิง
รู้ตัว
เพื่อ
ข้อตกลง
สัญญา
มนุษย์
อาศัย
หลักฐาน
จับต้อง
เนิ่น
ตรวจ
แหล่ง
สมมติฐาน
ตรวจสอบ
ความคาดหวัง
เหตุผล
ยอมรับ
ติดตาม
รสชาติ
อาย
ไม่ใช่
ใช่
ควรจะ
มีการ
เป็นหัวใจ
อย่างน้อย
สิ่งที่
ตัวเอง
คำ
ถอย
มากที่สุด
ธรรม
อีก
หนึ่ง
ทาง
ลักษณะ
พฤติกรรม
นโยบาย
ที่ดี
ที่ชอบ
ที่ยั่งยืน
ที่ต่อเนื่อง
ที่แข็งแรง
ที่มีประโยชน์
ที่หลากหลาย
ที่ทุกคนทำได้
ที่น่าอภิรมย์
ที่เปลี่ยนแปลงเร็ว
ที่ไม่รู้จัก
ที่มีความสุข
ที่เปลี่ยนแปลงได้ดี
ที่ทุกคนควรปฏิบัติ
ที่ทุกคนเข้าถึงได้
มีความรับผิดชอบ
ดีและจิตใจสงบ
ที่สร้างความทรงจำดีๆ
มีคุณภาพชีวิตที่ดี
ที่ทุกคนควรให้ความสำคัญ
มีความสวยงามและสมดุล
ทำเมนูใหม่ๆ
มีหลากหลายเมนู
ที่เล็กที่สุดในสังคม
ที่หลายองค์กรนำมาใช้
มีเอกลักษณ์เฉพาะตัว
"""
}
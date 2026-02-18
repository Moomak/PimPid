import XCTest
@testable import PimPid

/// ทดสอบว่าไม่แทนที่คำไทยที่ตั้งใจพิมพ์ และไม่แทนที่คำอังกฤษที่ตั้งใจพิมพ์
/// ใช้ NSSpellChecker ของระบบ — รันบน macOS: swift test
final class ConversionValidatorTests: XCTestCase {

    func testThaiToEnglish_RejectConvertedWithDigits() {
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "g0v", direction: .thaiToEnglish, original: "เจอ"))
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "ab1c", direction: .thaiToEnglish, original: "อะไร"))
    }

    func testThaiToEnglish_RejectNonEnglishWords() {
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "xit", direction: .thaiToEnglish, original: "ประ"))
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "gmL", direction: .thaiToEnglish, original: "เทศ"))
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "iyd", direction: .thaiToEnglish, original: "รัก"))
    }

    func testThaiToEnglish_AcceptValidEnglish() {
        // ใช้ original ที่ไม่ใช่คำไทยที่รู้จัก (ข้อความที่เกิดจากพิมพ์ผิดภาษา)
        XCTAssertTrue(ConversionValidator.shouldReplace(converted: "hello", direction: .thaiToEnglish, original: "สำววนำ"))
        XCTAssertTrue(ConversionValidator.shouldReplace(converted: "world", direction: .thaiToEnglish, original: "ฟสวฟก"))
    }

    func testEnglishToThai_RejectWhenOriginalIsValidEnglish() {
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "ะำหะ", direction: .englishToThai, original: "test"))
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "สววฟฟ", direction: .englishToThai, original: "hello"))
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "ฟรสว", direction: .englishToThai, original: "world"))
    }

    /// เมื่อต้นทางไม่ใช่คำอังกฤษที่ถูกต้อง และผลลัพธ์เป็นคำไทยที่รู้จัก → ยอมรับ
    /// เมื่อผลลัพธ์ไม่ใช่คำไทยที่รู้จัก (เช่น ะำหะ จาก tset) → ไม่แทนที่
    func testEnglishToThai_AcceptWhenOriginalIsNotValidEnglish() {
        // ต้นทางมีตัวเลข/ punctuation และแปลงเป็นคำไทยที่รู้จัก → ยอมรับ
        XCTAssertTrue(ConversionValidator.shouldReplace(converted: "วัน", direction: .englishToThai, original: ";yo"))
        // ต้นทางเป็นคำผิด (tset) แต่ผลลัพธ์ ะำหะ ไม่ได้อยู่ในรายการคำไทย → ไม่แทนที่
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "ะำหะ", direction: .englishToThai, original: "tset"))
    }

    func testNone_Reject() {
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "anything", direction: .none, original: "anything"))
    }

    func testThaiToEnglish_RejectWhenOriginalIsInThaiWordList() {
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "xit", direction: .thaiToEnglish, original: "ประ"))
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "gmL", direction: .thaiToEnglish, original: "เทศ"))
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "iyd", direction: .thaiToEnglish, original: "รัก"))
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "ช=j;p", direction: .thaiToEnglish, original: "ช่วย"))
        XCTAssertTrue(ThaiWordList.containsKnownThai("ประเทศ"))
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "xityg", direction: .thaiToEnglish, original: "ประเทศ"))
        XCTAssertTrue(ThaiWordList.containsKnownThai("ครับ"))
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "iyb", direction: .thaiToEnglish, original: "ครับ"))
    }

    func testThaiToEnglish_AcceptWhenConvertedIsValidEnglishEvenIfOriginalInList() {
        XCTAssertTrue(ConversionValidator.shouldReplace(converted: "type", direction: .thaiToEnglish, original: "ะัยำ"))
        XCTAssertTrue(ConversionValidator.shouldReplace(converted: "test", direction: .thaiToEnglish, original: "ะำหะ"))
    }

    func testThaiToEnglish_RejectWhenConvertedHasPunctuation() {
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: ",bh'", direction: .thaiToEnglish, original: "มิ้ง"))
    }

    /// แปลงแล้วไม่ใช่คำ (เช่น ''q จาก งงๆ, py'w'd จาก ยังไงก) — ไม่แทนที่ (convertedLooksLikeGarbageEnglish)
    func testThaiToEnglish_RejectGarbageLikeApostropheQ() {
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "'q", direction: .thaiToEnglish, original: "งงๆ"))
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "''q", direction: .thaiToEnglish, original: "งงๆ"))
    }

    /// ยังไงก → py'w'd ไม่มีความหมาย (มี apostrophe หลายตัว) — ไม่แทนที่
    func testThaiToEnglish_RejectYungNgak_ConvertedPyW_D() {
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "py'w'd", direction: .thaiToEnglish, original: "ยังไงก"))
    }

    /// ยังไงก็ เป็นคำไทยที่รู้จัก — ไม่แปลง
    func testThaiWordList_ContainsYungNgakKo() {
        XCTAssertTrue(ThaiWordList.containsKnownThai("ยังไงก็"))
        XCTAssertTrue(ThaiWordList.containsKnownThai("ยังไง"))
    }

    /// ต้นทางขึ้นต้นด้วยสระไทย (ะ้ำ) แปลงเป็น "the" — ยอมรับ (hasLeadingThaiVowelOrSign)
    func testThaiToEnglish_AcceptShortWhenLeadingThaiVowelOrSign() {
        XCTAssertTrue(ConversionValidator.shouldReplace(converted: "the", direction: .thaiToEnglish, original: "ะ้ำ"))
    }

    /// คำลงท้าย  ๆ (งงๆ) ถือว่าเป็นคำไทยที่รู้จัก — ไม่แปลง
    func testThaiWordList_ContainsKnownThaiWithRepetitionMark() {
        XCTAssertTrue(ThaiWordList.containsKnownThai("งงๆ"))
    }

    /// hasWordWithPrefix: prefix สั้นมาก (1 scalar) → false, prefix ที่เป็นต้นของคำใน list → true
    func testThaiWordList_HasWordWithPrefix() {
        // เก็ เป็น prefix ของ เก็บ (มีใน embedded)
        XCTAssertTrue(ThaiWordList.hasWordWithPrefix("เก็"))
        // 1 scalar ไม่พอ (ต้อง >= 2)
        XCTAssertFalse(ThaiWordList.hasWordWithPrefix("ก"))
        // prefix ที่ไม่มีคำใน list ขึ้นต้นด้วย
        XCTAssertFalse(ThaiWordList.hasWordWithPrefix("zzz"))
    }

    func testEnglishToThai_AcceptWhenOriginalHasDigitsOrPunctuation() {
        XCTAssertTrue(ConversionValidator.shouldReplace(converted: "วัน", direction: .englishToThai, original: ";yo"))
        XCTAssertTrue(ConversionValidator.shouldReplace(converted: "เติม", direction: .englishToThai, original: "g9b,"))
        XCTAssertTrue(ConversionValidator.shouldReplace(converted: "จัน", direction: .englishToThai, original: "0yo"))
    }

    /// ลืมสลับภาษา พิมพ์ megd (ตั้งใจทำเกม) — ต้องแก้เป็น ทำเก ได้ (prefix ของ ทำเกม)
    func testEnglishToThai_AcceptPrefixOfKnownWord_MegdToTamGe() {
        XCTAssertTrue(ConversionValidator.shouldReplace(converted: "ทำเก", direction: .englishToThai, original: "megd"))
    }
}

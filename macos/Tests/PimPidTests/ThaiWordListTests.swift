import XCTest
@testable import PimPid

/// Task 81: Unit test ThaiWordList — embedded words และ containsKnownThai / hasWordWithPrefix
final class ThaiWordListTests: XCTestCase {

    func testEmbeddedWordsAreLoaded() {
        XCTAssertTrue(ThaiWordList.containsKnownThai("ประเทศ"))
        XCTAssertTrue(ThaiWordList.containsKnownThai("ครับ"))
        XCTAssertTrue(ThaiWordList.containsKnownThai("รัก"))
        XCTAssertTrue(ThaiWordList.containsKnownThai("ช่วย"))
        XCTAssertTrue(ThaiWordList.containsKnownThai("เป็น"))
    }

    func testHasWordWithPrefix_Embedded() {
        XCTAssertTrue(ThaiWordList.hasWordWithPrefix("ประ"))
        XCTAssertTrue(ThaiWordList.hasWordWithPrefix("คร"))
        XCTAssertTrue(ThaiWordList.hasWordWithPrefix("เท"))
    }

    func testContainsKnownThai_RejectsUnknown() {
        XCTAssertFalse(ThaiWordList.containsKnownThai("xyzไม่ใช่คำไทย"))
        XCTAssertFalse(ThaiWordList.containsKnownThai("unknownword"))
    }

    func testContainsKnownThai_EmptyOrWhitespace() {
        XCTAssertFalse(ThaiWordList.containsKnownThai(""))
        XCTAssertFalse(ThaiWordList.containsKnownThai("   "))
    }

    func testHasWordWithPrefix_ShortPrefix() {
        // hasWordWithPrefix ต้องการอย่างน้อย 2 scalar
        XCTAssertFalse(ThaiWordList.hasWordWithPrefix("ป"))
    }
}

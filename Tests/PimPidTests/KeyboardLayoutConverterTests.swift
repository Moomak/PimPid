import XCTest
@testable import PimPid

/// ทดสอบการแปลง layout และการตัดสิน dominant language
/// รัน: swift test
final class KeyboardLayoutConverterTests: XCTestCase {

    func testDominantLanguageThai() {
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage("เทศ"), .thaiToEnglish)
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage("รัก"), .thaiToEnglish)
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage("ช่วย"), .thaiToEnglish)
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage("ประ"), .thaiToEnglish)
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage("เจอ"), .thaiToEnglish)
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage("ประเทศ"), .thaiToEnglish)
    }

    func testDominantLanguageEnglish() {
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage("test"), .englishToThai)
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage("hello"), .englishToThai)
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage("world"), .englishToThai)
    }

    func testConvertThaiToEnglishProducesKeyPositions() {
        XCTAssertEqual(KeyboardLayoutConverter.convertThaiToEnglish("เทศ"), "gmL")
        XCTAssertEqual(KeyboardLayoutConverter.convertThaiToEnglish("รัก"), "iyd")
        XCTAssertEqual(KeyboardLayoutConverter.convertThaiToEnglish("ประ"), "xit")
        XCTAssertEqual(KeyboardLayoutConverter.convertThaiToEnglish("เจอ"), "g0v")
    }

    func testConvertEnglishToThaiProducesKeyPositions() {
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai("test"), "ะำหะ")
        let helloThai = KeyboardLayoutConverter.convertEnglishToThai("hello")
        XCTAssertEqual(helloThai.unicodeScalars.count, 5)
        XCTAssertTrue(helloThai.allSatisfy { KeyboardLayoutConverter.isThai($0) })
    }

    func testConvertAutoRespectsDominantLanguage() {
        XCTAssertEqual(KeyboardLayoutConverter.convertAuto("เทศ"), "gmL")
        XCTAssertEqual(KeyboardLayoutConverter.convertAuto("test"), "ะำหะ")
    }

    func testMistypedLayoutConversions() {
        XCTAssertEqual(KeyboardLayoutConverter.convertThaiToEnglish("ะัยำ"), "type")
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai(";yo"), "วัน")
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai("g9b,"), "เติม")
        let zeroYo = KeyboardLayoutConverter.convertEnglishToThai("0yo")
        XCTAssertEqual(zeroYo.unicodeScalars.count, 3)
        XCTAssertTrue(zeroYo.allSatisfy { KeyboardLayoutConverter.isThai($0) })
    }
}

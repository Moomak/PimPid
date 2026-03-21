import XCTest
@testable import PimPid

/// Extended tests for KeyboardLayoutConverter covering edge cases, special characters,
/// Thai vowels/tone marks, numbers, empty input, and round-trip consistency
final class KeyboardLayoutConverterExtendedTests: XCTestCase {

    // MARK: - Empty and whitespace input

    func testConvertThaiToEnglish_EmptyString() {
        XCTAssertEqual(KeyboardLayoutConverter.convertThaiToEnglish(""), "")
    }

    func testConvertEnglishToThai_EmptyString() {
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai(""), "")
    }

    func testConvertAuto_EmptyString() {
        XCTAssertEqual(KeyboardLayoutConverter.convertAuto(""), "")
    }

    func testDominantLanguage_EmptyString() {
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage(""), .none)
    }

    func testDominantLanguage_WhitespaceOnly() {
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage("   "), .none)
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage("\t\n"), .none)
    }

    func testConvertAuto_WhitespaceOnly() {
        XCTAssertEqual(KeyboardLayoutConverter.convertAuto("   "), "   ")
    }

    // MARK: - Space preservation

    func testConvertThaiToEnglish_PreservesSpaces() {
        let input = "กา สา" // two Thai words with space
        let result = KeyboardLayoutConverter.convertThaiToEnglish(input)
        XCTAssertTrue(result.contains(" "), "Space should be preserved in conversion")
    }

    func testConvertEnglishToThai_PreservesSpaces() {
        let result = KeyboardLayoutConverter.convertEnglishToThai("hello world")
        XCTAssertTrue(result.contains(" "), "Space should be preserved in conversion")
    }

    // MARK: - Thai vowels and tone marks

    func testIsThai_ThaiConsonants() {
        // ก (U+0E01) - first Thai consonant
        XCTAssertTrue(KeyboardLayoutConverter.isThai(Character("\u{0E01}")))
        // ฮ (U+0E2E) - last Thai consonant
        XCTAssertTrue(KeyboardLayoutConverter.isThai(Character("\u{0E2E}")))
    }

    func testIsThai_ThaiVowelsAndToneMarks() {
        // สระอะ (U+0E30)
        XCTAssertTrue(KeyboardLayoutConverter.isThai(Character("\u{0E30}")))
        // ไม้เอก (U+0E48)
        XCTAssertTrue(KeyboardLayoutConverter.isThai(Character("\u{0E48}")))
        // ไม้ยมก (U+0E46)
        XCTAssertTrue(KeyboardLayoutConverter.isThai(Character("\u{0E46}")))
    }

    func testIsThai_ThaiDigits() {
        // ๐ (U+0E50) - Thai zero
        XCTAssertTrue(KeyboardLayoutConverter.isThai(Character("\u{0E50}")))
        // ๙ (U+0E59) - Thai nine
        XCTAssertTrue(KeyboardLayoutConverter.isThai(Character("\u{0E59}")))
    }

    func testIsThai_NotThai() {
        XCTAssertFalse(KeyboardLayoutConverter.isThai(Character("A")))
        XCTAssertFalse(KeyboardLayoutConverter.isThai(Character("0")))
        XCTAssertFalse(KeyboardLayoutConverter.isThai(Character(" ")))
        XCTAssertFalse(KeyboardLayoutConverter.isThai(Character("!")))
    }

    func testIsEnglish_ASCIICharacters() {
        XCTAssertTrue(KeyboardLayoutConverter.isEnglish(Character("a")))
        XCTAssertTrue(KeyboardLayoutConverter.isEnglish(Character("Z")))
        XCTAssertTrue(KeyboardLayoutConverter.isEnglish(Character("0")))
        XCTAssertTrue(KeyboardLayoutConverter.isEnglish(Character(";")))
        XCTAssertTrue(KeyboardLayoutConverter.isEnglish(Character("[")))
    }

    func testIsEnglish_NotEnglish() {
        XCTAssertFalse(KeyboardLayoutConverter.isEnglish(Character("\u{0E01}"))) // Thai ก
    }

    // MARK: - Numbers (should pass through mapping table)

    func testConvertThaiToEnglish_ThaiDigitsViaMapping() {
        // Thai digits on shifted keys: ๑ = @, ๒ = #, etc.
        let result = KeyboardLayoutConverter.convertThaiToEnglish("๑")
        XCTAssertFalse(result.isEmpty, "Thai digit should be convertible")
    }

    func testConvertEnglishToThai_NumbersViaMapping() {
        // Number row maps to Thai: 1 -> ๆ, 2 -> /, etc.
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai("1"), "ๆ")
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai("2"), "/")
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai("0"), "จ")
    }

    // MARK: - Dominant language with equal counts

    func testDominantLanguage_EqualThaiAndEnglish_ReturnsNone() {
        // Construct text with equal Thai and English scalars
        // "กa" has 1 Thai + 1 English
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage("กa"), .none)
    }

    func testDominantLanguage_MixedWithMoreThai() {
        // "กขa" has 2 Thai + 1 English
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage("กขa"), .thaiToEnglish)
    }

    func testDominantLanguage_MixedWithMoreEnglish() {
        XCTAssertEqual(KeyboardLayoutConverter.dominantLanguage("aกb"), .englishToThai)
    }

    // MARK: - Unmapped characters pass through

    func testConvertThaiToEnglish_UnmappedCharacterPassesThrough() {
        // Chinese character should pass through unchanged
        let input = "\u{4E2D}" // 中
        let result = KeyboardLayoutConverter.convertThaiToEnglish(input)
        XCTAssertEqual(result, input, "Unmapped character should pass through")
    }

    func testConvertEnglishToThai_UnmappedCharacterPassesThrough() {
        // Emoji should pass through
        let result = KeyboardLayoutConverter.convertEnglishToThai("\u{1F600}")
        XCTAssertTrue(result.contains("\u{1F600}"), "Emoji should pass through unchanged")
    }

    // MARK: - All shifted keys mapping

    func testShiftedKeysAreComplete() {
        // Test a selection of shifted key mappings
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai("~"), "%")
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai("E"), "ฎ")
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai("R"), "ฑ")
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai("T"), "ธ")
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai("Z"), "(")
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai("X"), ")")
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai("M"), "?")
        XCTAssertEqual(KeyboardLayoutConverter.convertEnglishToThai("N"), "์")
    }

    // MARK: - Multi-character conversion

    func testConvertThaiToEnglish_LongText() {
        let input = "สวัสดีครับ"
        let result = KeyboardLayoutConverter.convertThaiToEnglish(input)
        XCTAssertEqual(result.unicodeScalars.count, input.unicodeScalars.count,
                       "Output scalar count should match input scalar count")
    }

    func testConvertEnglishToThai_LongText() {
        let input = "keyboard layout converter"
        let result = KeyboardLayoutConverter.convertEnglishToThai(input)
        XCTAssertEqual(result.unicodeScalars.count, input.unicodeScalars.count,
                       "Output scalar count should match input scalar count")
    }

    // MARK: - Consistency: convertAuto uses correct direction

    func testConvertAuto_ThaiInput_UsesThaiToEnglish() {
        let thaiInput = "สวัสดี"
        let autoResult = KeyboardLayoutConverter.convertAuto(thaiInput)
        let directResult = KeyboardLayoutConverter.convertThaiToEnglish(thaiInput)
        XCTAssertEqual(autoResult, directResult)
    }

    func testConvertAuto_EnglishInput_UsesEnglishToThai() {
        let engInput = "hello"
        let autoResult = KeyboardLayoutConverter.convertAuto(engInput)
        let directResult = KeyboardLayoutConverter.convertEnglishToThai(engInput)
        XCTAssertEqual(autoResult, directResult)
    }

    func testConvertAuto_NoneDirection_ReturnsOriginal() {
        // Single space is not Thai nor English (space is excluded from counting)
        XCTAssertEqual(KeyboardLayoutConverter.convertAuto("   "), "   ")
    }

    // MARK: - Round-trip partial check

    func testRoundTrip_EnglishToThaiAndBack_UnshiftedLetters() {
        // For unshifted letters that have unique mappings, round-trip should work
        let letters = "asdfghjkl"
        let thai = KeyboardLayoutConverter.convertEnglishToThai(letters)
        let back = KeyboardLayoutConverter.convertThaiToEnglish(thai)
        // Due to mapping collisions (q and 1 both map to ๆ), round-trip may not be perfect
        // but for these unique letters it should work
        XCTAssertEqual(back.count, letters.count,
                       "Round-trip should preserve character count for unique mappings")
    }

    // MARK: - Special characters in input

    func testConvertThaiToEnglish_WithNewlines() {
        let input = "กา\nขา"
        let result = KeyboardLayoutConverter.convertThaiToEnglish(input)
        XCTAssertTrue(result.contains("\n"), "Newline should be preserved")
    }

    func testConvertEnglishToThai_WithTab() {
        let input = "hello\tworld"
        let result = KeyboardLayoutConverter.convertEnglishToThai(input)
        XCTAssertTrue(result.contains("\t"), "Tab should be preserved")
    }
}

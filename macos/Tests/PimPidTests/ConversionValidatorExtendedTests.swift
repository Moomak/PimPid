import XCTest
@testable import PimPid

/// Extended tests for ConversionValidator edge cases
final class ConversionValidatorExtendedTests: XCTestCase {

    // MARK: - Empty / whitespace input

    func testShouldReplace_EmptyConverted_ReturnsFalse() {
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "", direction: .thaiToEnglish, original: ""))
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "", direction: .englishToThai, original: ""))
    }

    func testShouldReplace_WhitespaceConverted_ReturnsFalse() {
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "   ", direction: .thaiToEnglish, original: "   "))
    }

    // MARK: - Thai to English: gibberish detection

    func testThaiToEnglish_GibberishNoVowels_ReturnsFalse() {
        // 4+ consonants with no vowels = gibberish
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "dkjf", direction: .thaiToEnglish, original: "กดจฝ"))
    }

    func testThaiToEnglish_RepeatCharacters_ReturnsFalse() {
        // 3+ repeated characters = gibberish
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "aaab", direction: .thaiToEnglish, original: "ฟฟฟิ"))
    }

    func testThaiToEnglish_ShortWordNoVowels_NotGibberish() {
        // Less than 4 letters, no vowels check doesn't apply
        // But still needs to be valid English
        let result = ConversionValidator.shouldReplace(converted: "dr", direction: .thaiToEnglish, original: "กิ")
        // "dr" is only 2 chars, which is <= minSingleWordLength, so rejected
        XCTAssertFalse(result)
    }

    // MARK: - Thai to English: suspicious casing

    func testThaiToEnglish_UpperCaseMidWord_ReturnsFalse() {
        // Uppercase in middle of word (from Thai shifted keys)
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "gdH", direction: .thaiToEnglish, original: "เก็"))
    }

    func testThaiToEnglish_UpperCaseAtStart_Allowed() {
        // Uppercase at start of word is normal
        // "Hello" starts with uppercase -- should pass if it's a valid English word
        XCTAssertTrue(ConversionValidator.shouldReplace(converted: "Hello", direction: .thaiToEnglish, original: "สำววน"))
    }

    func testThaiToEnglish_UpperCaseAfterSpace_Allowed() {
        // "Hello World" -- both start with uppercase
        XCTAssertTrue(ConversionValidator.shouldReplace(converted: "Hello World", direction: .thaiToEnglish, original: "สำววน ฟนิวก"))
    }

    // MARK: - English to Thai: tech terms blocking

    func testEnglishToThai_DefaultTechTerms_Blocked() {
        let techTerms = ["git", "npm", "api", "html", "css", "json", "docker", "redis"]
        for term in techTerms {
            let converted = KeyboardLayoutConverter.convertEnglishToThai(term)
            let result = ConversionValidator.shouldReplace(converted: converted, direction: .englishToThai, original: term)
            XCTAssertFalse(result, "Tech term '\(term)' should not be replaced")
        }
    }

    // MARK: - English to Thai: only numbers/spaces

    func testEnglishToThai_OnlyNumbers_ReturnsFalse() {
        // Number-only input that doesn't match a known Thai word
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "ค", direction: .englishToThai, original: "8"))
    }

    func testEnglishToThai_ShortNumberToKnownThai_ReturnsTrue() {
        // ".["  (2 chars) -> if this maps to a known Thai word like "ใบ", it should be true
        let converted = KeyboardLayoutConverter.convertEnglishToThai(".[")
        if ThaiWordList.containsKnownThai(converted) {
            let result = ConversionValidator.shouldReplace(converted: converted, direction: .englishToThai, original: ".[")
            XCTAssertTrue(result, "Short non-letter input that maps to known Thai word should be accepted")
        }
    }

    // MARK: - English to Thai: valid English original

    func testEnglishToThai_ValidEnglishOriginal_ReturnsFalse() {
        let validEnglish = ["hello", "world", "test", "computer", "language"]
        for word in validEnglish {
            let converted = KeyboardLayoutConverter.convertEnglishToThai(word)
            let result = ConversionValidator.shouldReplace(converted: converted, direction: .englishToThai, original: word)
            XCTAssertFalse(result, "Valid English word '\(word)' should not be replaced with Thai")
        }
    }

    // MARK: - English to Thai: short word that maps to known Thai

    func testEnglishToThai_ShortWordToKnownThai() {
        // "rd" -> "พก" is a known Thai word, and "rd" is <=3 chars
        let converted = KeyboardLayoutConverter.convertEnglishToThai("rd")
        XCTAssertEqual(converted, "พก")
        if ThaiWordList.containsKnownThai("พก") {
            let result = ConversionValidator.shouldReplace(converted: "พก", direction: .englishToThai, original: "rd")
            XCTAssertTrue(result, "Short original that maps to known Thai word should be replaced")
        }
    }

    // MARK: - Thai to English: long valid English word

    func testThaiToEnglish_LongWord_Over50Chars_ReturnsFalse() {
        // Words over 50 characters are rejected
        let longWord = String(repeating: "a", count: 51)
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: longWord, direction: .thaiToEnglish, original: "x"))
    }

    // MARK: - englishKeepAsIs list

    func testEnglishKeepAsIs_AllEntries_Blocked() {
        for word in AutoCorrectionLogic.englishKeepAsIs {
            let converted = KeyboardLayoutConverter.convertEnglishToThai(word)
            let result = ConversionValidator.shouldReplace(converted: converted, direction: .englishToThai, original: word)
            XCTAssertFalse(result, "englishKeepAsIs word '\(word)' should not be replaced")
        }
    }

    // MARK: - Leading Thai vowel/sign

    func testThaiToEnglish_LeadingThaiVowel_AllowsShortWord() {
        // Text starting with Thai vowel (> U+0E2E) is suspicious (likely wrong layout)
        // Shorter words should be allowed when original has leading vowel
        // "เ" (U+0E40) is a leading vowel
        let result = ConversionValidator.shouldReplace(converted: "the", direction: .thaiToEnglish, original: "ะ้ำ")
        XCTAssertTrue(result, "Short valid English word should be accepted when original has leading Thai vowel")
    }

    // MARK: - None direction always returns false

    func testNoneDirection_AlwaysFalse() {
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "hello", direction: .none, original: "hello"))
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "สวัสดี", direction: .none, original: "สวัสดี"))
        XCTAssertFalse(ConversionValidator.shouldReplace(converted: "", direction: .none, original: ""))
    }

    // MARK: - Thai word list: compound words

    func testThaiWordList_CompoundWords() {
        // ไม่เป็น = ไม่ + เป็น (both in word list)
        XCTAssertTrue(ThaiWordList.containsKnownThai("ไม่เป็น"))
        // ไม่เป็นไร should be in the list directly
        XCTAssertTrue(ThaiWordList.containsKnownThai("ไม่เป็นไร"))
    }

    func testThaiWordList_SingleKnownWords() {
        let knownWords = ["ที่", "และ", "หรือ", "แต่", "จะ", "ได้", "ไป", "มา", "ว่า", "ทำ"]
        for word in knownWords {
            XCTAssertTrue(ThaiWordList.containsKnownThai(word), "'\(word)' should be in Thai word list")
        }
    }
}

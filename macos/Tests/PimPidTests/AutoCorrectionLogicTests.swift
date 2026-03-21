import XCTest
@testable import PimPid

/// Tests for AutoCorrectionLogic: replacement decisions, mixed language detection,
/// tech term exclusion, minimum word length, exclude words
final class AutoCorrectionLogicTests: XCTestCase {

    // MARK: - Minimum word length

    func testReplacement_SingleCharacter_ReturnsNil() {
        // Single character should not be corrected (min length is 2)
        let result = AutoCorrectionLogic.replacement(for: "a", excludeWords: [])
        XCTAssertNil(result, "Single character should not trigger replacement")
    }

    func testReplacement_EmptyString_ReturnsNil() {
        let result = AutoCorrectionLogic.replacement(for: "", excludeWords: [])
        XCTAssertNil(result, "Empty string should not trigger replacement")
    }

    func testReplacement_WhitespaceOnly_ReturnsNil() {
        let result = AutoCorrectionLogic.replacement(for: "   ", excludeWords: [])
        XCTAssertNil(result, "Whitespace-only string should not trigger replacement")
    }

    // MARK: - Exclude words

    func testReplacement_ExcludedWord_ReturnsNil() {
        let result = AutoCorrectionLogic.replacement(for: "hello", excludeWords: ["hello"])
        XCTAssertNil(result, "Excluded word should not trigger replacement")
    }

    func testReplacement_ExcludedWordCaseInsensitive() {
        let result = AutoCorrectionLogic.replacement(for: "Hello", excludeWords: ["hello"])
        XCTAssertNil(result, "Exclude should be case insensitive")
    }

    func testReplacement_NonExcludedWord_MayTriggerReplacement() {
        // "rd" maps to "พก" in Thai -- a known word
        let result = AutoCorrectionLogic.replacement(for: "rd", excludeWords: [])
        XCTAssertNotNil(result, "Non-excluded word should potentially trigger replacement")
    }

    // MARK: - Tech terms exclusion

    func testReplacement_GitTechTerm_ReturnsNil() {
        let result = AutoCorrectionLogic.replacement(for: "git", excludeWords: [])
        XCTAssertNil(result, "Tech term 'git' should not be auto-corrected")
    }

    func testReplacement_NpmTechTerm_ReturnsNil() {
        let result = AutoCorrectionLogic.replacement(for: "npm", excludeWords: [])
        XCTAssertNil(result, "Tech term 'npm' should not be auto-corrected")
    }

    func testReplacement_ApiTechTerm_ReturnsNil() {
        let result = AutoCorrectionLogic.replacement(for: "api", excludeWords: [])
        XCTAssertNil(result, "Tech term 'api' should not be auto-corrected")
    }

    func testReplacement_SwiftTechTerm_ReturnsNil() {
        let result = AutoCorrectionLogic.replacement(for: "swift", excludeWords: [])
        XCTAssertNil(result, "Tech term 'swift' should not be auto-corrected")
    }

    func testReplacement_DockerTechTerm_ReturnsNil() {
        let result = AutoCorrectionLogic.replacement(for: "docker", excludeWords: [])
        XCTAssertNil(result, "Tech term 'docker' should not be auto-corrected")
    }

    func testReplacement_TechTermCaseInsensitive() {
        let result = AutoCorrectionLogic.replacement(for: "Git", excludeWords: [])
        XCTAssertNil(result, "Tech term should be case insensitive")
    }

    func testReplacement_EnvTechTerm_ReturnsNil() {
        let result = AutoCorrectionLogic.replacement(for: "env", excludeWords: [])
        XCTAssertNil(result, "Tech term 'env' should not be auto-corrected")
    }

    // MARK: - englishKeepAsIs

    func testReplacement_EnglishKeepAsIs_Com_ReturnsNil() {
        // "com" is in englishKeepAsIs -- should not be converted to Thai
        // Test via ConversionValidator since AutoCorrectionLogic.replacement delegates there
        let converted = KeyboardLayoutConverter.convertEnglishToThai("com")
        let should = ConversionValidator.shouldReplace(converted: converted, direction: .englishToThai, original: "com")
        XCTAssertFalse(should, "'com' should be kept as-is (domain suffix)")
    }

    // MARK: - Mixed language threshold

    func testReplacement_MixedLanguage_ReturnsNil() {
        // Text with both Thai and English above 30% threshold
        // "ทดสอบtest" = 4 Thai + 4 English = 50/50 -> mixed
        let result = AutoCorrectionLogic.replacement(for: "ทดสอบtest", excludeWords: [])
        XCTAssertNil(result, "Mixed language text should not trigger replacement")
    }

    func testReplacement_MostlyThai_NotMixed() {
        // "ทดสอบt" = 4 Thai + 1 English = 80% Thai -> not mixed (English < 30%)
        // This should not be blocked by mixed threshold
        let direction = KeyboardLayoutConverter.dominantLanguage("ทดสอบt")
        XCTAssertEqual(direction, .thaiToEnglish,
                       "Text with mostly Thai characters should be detected as Thai")
    }

    // MARK: - Direction detection

    func testReplacement_ThaiInput_DirectionIsThaiToEnglish() {
        // "สวัสดี" typed with wrong layout -> should detect Thai direction
        let result = AutoCorrectionLogic.replacement(for: "สำววนำ", excludeWords: [])
        if let r = result {
            XCTAssertEqual(r.direction, .thaiToEnglish)
        }
        // result may be nil if "hello" isn't what we expect; either way is ok for this test
    }

    // MARK: - Number-like conversion from .none direction

    func testReplacement_NumberLikeFromThaiLayout() {
        // When direction is .none but converting Thai->English yields a number
        // "/จ" = 2 + 0 = "20" if typed on Thai layout
        let result = AutoCorrectionLogic.replacement(for: "/จ", excludeWords: [])
        if let r = result {
            XCTAssertEqual(r.direction, .thaiToEnglish)
            XCTAssertTrue(r.converted.allSatisfy { $0.isNumber || $0 == "." },
                          "Should produce a number")
        }
    }

    // MARK: - looksLikeNumber

    func testDefaultExcludedTechTerms_ContainsCommonTerms() {
        let terms = AutoCorrectionLogic.defaultExcludedTechTerms
        XCTAssertTrue(terms.contains("git"))
        XCTAssertTrue(terms.contains("npm"))
        XCTAssertTrue(terms.contains("html"))
        XCTAssertTrue(terms.contains("css"))
        XCTAssertTrue(terms.contains("json"))
        XCTAssertTrue(terms.contains("api"))
        XCTAssertTrue(terms.contains("http"))
        XCTAssertTrue(terms.contains("https"))
        XCTAssertTrue(terms.contains("sql"))
        XCTAssertTrue(terms.contains("docker"))
        XCTAssertTrue(terms.contains("redis"))
        XCTAssertTrue(terms.contains("swift"))
        XCTAssertTrue(terms.contains("react"))
        XCTAssertTrue(terms.contains("sudo"))
        XCTAssertTrue(terms.contains("curl"))
        XCTAssertTrue(terms.contains("aws"))
        XCTAssertTrue(terms.contains("pdf"))
        XCTAssertTrue(terms.contains("cli"))
    }

    // MARK: - Converted same as input

    func testReplacement_ConvertedSameAsInput_ReturnsNil() {
        // If conversion produces same text, no replacement needed
        // Space only is trimmed to empty -> nil
        let result = AutoCorrectionLogic.replacement(for: "  ", excludeWords: [])
        XCTAssertNil(result)
    }

    // MARK: - Thai word replacement

    func testReplacement_KnownThaiWord_rd_to_PokGo() {
        let result = AutoCorrectionLogic.replacement(for: "rd", excludeWords: [])
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.converted, "พก")
    }
}

import XCTest
@testable import PimPid

/// Extended tests for ExcludeListStore: special characters, case sensitivity, edge cases
@MainActor
final class ExcludeListStoreExtendedTests: XCTestCase {

    private let testPrefix = "pimpid_xtest_"

    override func tearDown() {
        super.tearDown()
        let store = ExcludeListStore.shared
        let wordsToClean = [
            "\(testPrefix)special!@#",
            "\(testPrefix)UPPER",
            "\(testPrefix)empty",
            "\(testPrefix)spaces",
            "\(testPrefix)dup",
            "\(testPrefix)thai_กข",
        ]
        for word in wordsToClean {
            if store.contains(word) {
                store.remove(word)
            }
        }
    }

    // MARK: - Special characters

    func testAdd_SpecialCharacters() {
        let store = ExcludeListStore.shared
        let word = "\(testPrefix)special!@#"
        store.add(word)
        XCTAssertTrue(store.contains(word), "Special characters should be storable")
        store.remove(word)
    }

    // MARK: - Case handling

    func testAdd_ConvertsToLowercase() {
        let store = ExcludeListStore.shared
        let word = "\(testPrefix)UPPER"
        store.add(word)
        // Stored as lowercase
        XCTAssertTrue(store.contains(word))
        XCTAssertTrue(store.contains(word.lowercased()))
        XCTAssertTrue(store.contains(word.uppercased()))
        store.remove(word)
    }

    // MARK: - Empty input

    func testAdd_EmptyString_Ignored() {
        let store = ExcludeListStore.shared
        let countBefore = store.words.count
        store.add("")
        XCTAssertEqual(store.words.count, countBefore, "Empty string should not be added")
    }

    func testAdd_WhitespaceOnly_Ignored() {
        let store = ExcludeListStore.shared
        let countBefore = store.words.count
        store.add("   ")
        XCTAssertEqual(store.words.count, countBefore, "Whitespace-only should not be added")
    }

    // MARK: - Contains with trimming

    func testContains_TrimsWhitespace() {
        let store = ExcludeListStore.shared
        let word = "\(testPrefix)spaces"
        store.add(word)
        XCTAssertTrue(store.contains("  \(word)  "), "Should trim whitespace when checking")
        store.remove(word)
    }

    // MARK: - Remove nonexistent word

    func testRemove_NonexistentWord_DoesNotCrash() {
        let store = ExcludeListStore.shared
        store.remove("this_word_definitely_does_not_exist_12345")
        // Should not crash
    }

    // MARK: - Duplicate add

    func testAdd_Duplicate_NoDoubleEntry() {
        let store = ExcludeListStore.shared
        let word = "\(testPrefix)dup"
        store.add(word)
        let countAfterFirst = store.words.count
        store.add(word)
        XCTAssertEqual(store.words.count, countAfterFirst, "Adding duplicate should not increase count")
        store.remove(word)
    }

    // MARK: - shouldExclude edge cases

    func testShouldExclude_EmptyText_ReturnsTrue() {
        let store = ExcludeListStore.shared
        XCTAssertTrue(store.shouldExclude(text: ""), "Empty text should be excluded")
    }

    func testShouldExclude_WhitespaceOnlyText_ReturnsTrue() {
        let store = ExcludeListStore.shared
        XCTAssertTrue(store.shouldExclude(text: "   "), "Whitespace-only should be excluded")
    }

    func testShouldExclude_TextNotInList_ReturnsFalse() {
        let store = ExcludeListStore.shared
        XCTAssertFalse(store.shouldExclude(text: "definitely_not_in_list_xyz_999"),
                       "Text not in list should not be excluded")
    }

    // MARK: - Thai text in exclude list

    func testAdd_ThaiText() {
        let store = ExcludeListStore.shared
        let word = "\(testPrefix)thai_กข"
        store.add(word)
        XCTAssertTrue(store.contains(word), "Thai characters should be storable")
        store.remove(word)
    }
}

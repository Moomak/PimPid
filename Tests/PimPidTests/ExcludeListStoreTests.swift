import XCTest
@testable import PimPid

/// ทดสอบ ExcludeListStore — add, remove, contains, shouldExclude
/// ใช้คำขึ้นต้น pimpid_test_ เพื่อลบใน tearDown ไม่กระทบข้อมูลจริง
@MainActor
final class ExcludeListStoreTests: XCTestCase {

    private let testPrefix = "pimpid_test_"

    override func tearDown() {
        super.tearDown()
        let store = ExcludeListStore.shared
        for word in ["\(testPrefix)one", "\(testPrefix)two", "\(testPrefix)a", "\(testPrefix)b"] {
            if store.contains(word) {
                store.remove(word)
            }
        }
    }

    func testAddAndContains() {
        let store = ExcludeListStore.shared
        let word = "\(testPrefix)one"
        store.add(word)
        XCTAssertTrue(store.contains(word))
        XCTAssertTrue(store.contains("  \(word)  "))
        store.remove(word)
        XCTAssertFalse(store.contains(word))
    }

    func testRemove() {
        let store = ExcludeListStore.shared
        let word = "\(testPrefix)two"
        store.add(word)
        XCTAssertTrue(store.contains(word))
        store.remove(word)
        XCTAssertFalse(store.contains(word))
        store.remove(word) // remove again ไม่ crash
    }

    func testShouldExclude_SingleWord() {
        let store = ExcludeListStore.shared
        let word = "\(testPrefix)a"
        store.add(word)
        XCTAssertTrue(store.shouldExclude(text: word))
        XCTAssertTrue(store.shouldExclude(text: "  \(word)  "))
        store.remove(word)
        XCTAssertFalse(store.shouldExclude(text: word))
    }

    func testShouldExclude_AllWordsInList() {
        let store = ExcludeListStore.shared
        store.add("\(testPrefix)a")
        store.add("\(testPrefix)b")
        XCTAssertTrue(store.shouldExclude(text: "\(testPrefix)a \(testPrefix)b"))
        store.remove("\(testPrefix)a")
        store.remove("\(testPrefix)b")
    }

    /// Task 74: วลี (หลายคำ) เพิ่มเป็นรายการเดียว — shouldExclude ต้องรองรับ
    func testShouldExclude_PhraseAsSingleEntry() {
        let store = ExcludeListStore.shared
        let phrase = "\(testPrefix)hello \(testPrefix)world"
        store.add(phrase)
        XCTAssertTrue(store.shouldExclude(text: phrase))
        XCTAssertTrue(store.shouldExclude(text: "  \(phrase)  "))
        store.remove(phrase)
        XCTAssertFalse(store.shouldExclude(text: phrase))
    }
}

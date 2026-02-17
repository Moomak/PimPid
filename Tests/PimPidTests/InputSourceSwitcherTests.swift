import XCTest
@testable import PimPid

/// Task 34: ทดสอบ logic การเลือก layout (selectableSourceID) โดยไม่เรียก TIS จริง
final class InputSourceSwitcherTests: XCTestCase {

    func testSelectableSourceID_Thai_SelectsThaiKedmanee() {
        let ids = ["com.apple.keylayout.US", "com.apple.keylayout.Thai-Kedmanee", "com.apple.keylayout.ABC"]
        let result = InputSourceSwitcher.selectableSourceID(from: ids, target: .thai)
        XCTAssertEqual(result, "com.apple.keylayout.Thai-Kedmanee")
    }

    func testSelectableSourceID_Thai_SelectsFirstThai() {
        let ids = ["com.apple.keylayout.Thai-Patta-Choti", "com.apple.keylayout.Thai-Kedmanee"]
        let result = InputSourceSwitcher.selectableSourceID(from: ids, target: .thai)
        XCTAssertEqual(result, "com.apple.keylayout.Thai-Patta-Choti")
    }

    func testSelectableSourceID_Thai_ContainsThai() {
        let ids = ["com.apple.keylayout.CustomThaiLayout"]
        let result = InputSourceSwitcher.selectableSourceID(from: ids, target: .thai)
        XCTAssertEqual(result, "com.apple.keylayout.CustomThaiLayout")
    }

    func testSelectableSourceID_English_SelectsUS() {
        let ids = ["com.apple.keylayout.Thai", "com.apple.keylayout.US", "com.apple.keylayout.Thai-Kedmanee"]
        let result = InputSourceSwitcher.selectableSourceID(from: ids, target: .english)
        XCTAssertEqual(result, "com.apple.keylayout.US")
    }

    func testSelectableSourceID_English_SelectsABC() {
        let ids = ["com.apple.keylayout.ABC"]
        let result = InputSourceSwitcher.selectableSourceID(from: ids, target: .english)
        XCTAssertEqual(result, "com.apple.keylayout.ABC")
    }

    func testSelectableSourceID_English_SelectsFirstEnglish() {
        let ids = ["com.apple.keylayout.USExtended", "com.apple.keylayout.US"]
        let result = InputSourceSwitcher.selectableSourceID(from: ids, target: .english)
        XCTAssertEqual(result, "com.apple.keylayout.USExtended")
    }

    func testSelectableSourceID_Thai_EmptyList_ReturnsNil() {
        let result = InputSourceSwitcher.selectableSourceID(from: [], target: .thai)
        XCTAssertNil(result)
    }

    func testSelectableSourceID_English_NoMatch_ReturnsNil() {
        let ids = ["com.apple.keylayout.Thai", "com.apple.keylayout.Thai-Kedmanee"]
        let result = InputSourceSwitcher.selectableSourceID(from: ids, target: .english)
        XCTAssertNil(result)
    }
}

import XCTest
@testable import PimPid

/// ทดสอบ ConversionStats — record, reset, undo, clearRecent
@MainActor
final class ConversionStatsTests: XCTestCase {

    func testRecordIncrementsCounts() {
        let stats = ConversionStats.shared
        let totalBefore = stats.totalConversions
        let todayBefore = stats.todayConversions
        stats.recordConversion(from: "test", to: "ะำหะ", direction: .auto)
        XCTAssertEqual(stats.totalConversions, totalBefore + 1)
        XCTAssertEqual(stats.todayConversions, todayBefore + 1)
        XCTAssertEqual(stats.recentConversions.first?.original, "test")
        XCTAssertEqual(stats.recentConversions.first?.converted, "ะำหะ")
    }

    func testClearRecentConversions() {
        let stats = ConversionStats.shared
        stats.recordConversion(from: "a", to: "b", direction: .auto)
        XCTAssertFalse(stats.recentConversions.isEmpty)
        stats.clearRecentConversions()
        XCTAssertTrue(stats.recentConversions.isEmpty)
        XCTAssertGreaterThanOrEqual(stats.totalConversions, 0)
    }

    func testUndoLastConversion() {
        let stats = ConversionStats.shared
        stats.recordConversion(from: "x", to: "y", direction: .thaiToEnglish)
        let countBefore = stats.totalConversions
        let record = stats.undoLastConversion()
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.original, "x")
        XCTAssertEqual(record?.converted, "y")
        XCTAssertEqual(stats.totalConversions, max(0, countBefore - 1))
    }
}

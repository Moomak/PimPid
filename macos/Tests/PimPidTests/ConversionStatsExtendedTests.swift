import XCTest
@testable import PimPid

/// Extended tests for ConversionStats: edge cases, daily counts, export/last7days
@MainActor
final class ConversionStatsExtendedTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        // Clean up by resetting
        ConversionStats.shared.resetAll()
    }

    // MARK: - Record and verify

    func testRecordMultipleConversions() {
        let stats = ConversionStats.shared
        stats.resetAll()

        stats.recordConversion(from: "a", to: "b", direction: .thaiToEnglish)
        stats.recordConversion(from: "c", to: "d", direction: .englishToThai)
        stats.recordConversion(from: "e", to: "f", direction: .auto)

        XCTAssertEqual(stats.totalConversions, 3)
        XCTAssertEqual(stats.todayConversions, 3)
        XCTAssertEqual(stats.recentConversions.count, 3)
    }

    func testRecentConversions_OrderIsMostRecentFirst() {
        let stats = ConversionStats.shared
        stats.resetAll()

        stats.recordConversion(from: "first", to: "1st", direction: .auto)
        stats.recordConversion(from: "second", to: "2nd", direction: .auto)
        stats.recordConversion(from: "third", to: "3rd", direction: .auto)

        XCTAssertEqual(stats.recentConversions.first?.original, "third")
        XCTAssertEqual(stats.recentConversions.last?.original, "first")
    }

    func testRecentConversions_MaxCount() {
        let stats = ConversionStats.shared
        stats.resetAll()

        // Record more than maxRecentCount (10) items
        for i in 0..<15 {
            stats.recordConversion(from: "item\(i)", to: "conv\(i)", direction: .auto)
        }

        XCTAssertEqual(stats.recentConversions.count, 10, "Should keep max 10 recent items")
        XCTAssertEqual(stats.recentConversions.first?.original, "item14")
    }

    // MARK: - Undo

    func testUndo_EmptyList_ReturnsNil() {
        let stats = ConversionStats.shared
        stats.resetAll()

        let record = stats.undoLastConversion()
        XCTAssertNil(record, "Undo on empty list should return nil")
    }

    func testUndo_DecrementsBothCounters() {
        let stats = ConversionStats.shared
        stats.resetAll()

        stats.recordConversion(from: "x", to: "y", direction: .auto)
        stats.recordConversion(from: "a", to: "b", direction: .auto)

        XCTAssertEqual(stats.totalConversions, 2)
        XCTAssertEqual(stats.todayConversions, 2)

        let undone = stats.undoLastConversion()
        XCTAssertNotNil(undone)
        XCTAssertEqual(undone?.original, "a")
        XCTAssertEqual(stats.totalConversions, 1)
        XCTAssertEqual(stats.todayConversions, 1)
    }

    func testUndo_DoesNotGoNegative() {
        let stats = ConversionStats.shared
        stats.resetAll()

        stats.recordConversion(from: "x", to: "y", direction: .auto)
        _ = stats.undoLastConversion()
        _ = stats.undoLastConversion() // should be nil and not decrement

        XCTAssertGreaterThanOrEqual(stats.totalConversions, 0)
        XCTAssertGreaterThanOrEqual(stats.todayConversions, 0)
    }

    // MARK: - Reset

    func testResetAll_ClearsEverything() {
        let stats = ConversionStats.shared
        stats.recordConversion(from: "x", to: "y", direction: .auto)
        stats.resetAll()

        XCTAssertEqual(stats.totalConversions, 0)
        XCTAssertEqual(stats.todayConversions, 0)
        XCTAssertTrue(stats.recentConversions.isEmpty)
        XCTAssertTrue(stats.dailyCounts.isEmpty)
    }

    func testResetToday_OnlyResetsToday() {
        let stats = ConversionStats.shared
        stats.resetAll()

        stats.recordConversion(from: "x", to: "y", direction: .auto)
        stats.recordConversion(from: "a", to: "b", direction: .auto)

        let totalBefore = stats.totalConversions
        stats.resetToday()

        XCTAssertEqual(stats.todayConversions, 0)
        XCTAssertEqual(stats.totalConversions, totalBefore, "Total should not be affected by resetToday")
    }

    func testClearRecentConversions_DoesNotAffectCounters() {
        let stats = ConversionStats.shared
        stats.resetAll()

        stats.recordConversion(from: "x", to: "y", direction: .auto)
        let totalBefore = stats.totalConversions
        let todayBefore = stats.todayConversions

        stats.clearRecentConversions()

        XCTAssertTrue(stats.recentConversions.isEmpty)
        XCTAssertEqual(stats.totalConversions, totalBefore)
        XCTAssertEqual(stats.todayConversions, todayBefore)
    }

    // MARK: - Last 7 days

    func testLast7DaysCounts_Returns7Items() {
        let stats = ConversionStats.shared
        stats.resetAll()

        let days = stats.last7DaysCounts()
        XCTAssertEqual(days.count, 7, "Should return exactly 7 days")
    }

    func testLast7DaysCounts_TodayReflectsCurrentCount() {
        let stats = ConversionStats.shared
        stats.resetAll()

        stats.recordConversion(from: "x", to: "y", direction: .auto)
        stats.recordConversion(from: "a", to: "b", direction: .auto)

        let days = stats.last7DaysCounts()
        let today = days.last
        XCTAssertEqual(today?.count, 2, "Today's count should match todayConversions")
    }

    // MARK: - ConversionRecord

    func testConversionRecord_HasUniqueID() {
        let r1 = ConversionRecord(original: "a", converted: "b", direction: .auto, timestamp: Date())
        let r2 = ConversionRecord(original: "a", converted: "b", direction: .auto, timestamp: Date())
        XCTAssertNotEqual(r1.id, r2.id, "Each record should have a unique ID")
    }

    func testConversionRecord_Codable() {
        let record = ConversionRecord(original: "test", converted: "ะำหะ", direction: .englishToThai, timestamp: Date())
        let encoded = try? JSONEncoder().encode(record)
        XCTAssertNotNil(encoded, "Record should be encodable")

        if let data = encoded {
            let decoded = try? JSONDecoder().decode(ConversionRecord.self, from: data)
            XCTAssertNotNil(decoded, "Record should be decodable")
            XCTAssertEqual(decoded?.original, "test")
            XCTAssertEqual(decoded?.converted, "ะำหะ")
            XCTAssertEqual(decoded?.direction, .englishToThai)
        }
    }

    // MARK: - ConversionDirection

    func testConversionDirection_DisplayNames() {
        XCTAssertFalse(ConversionDirection.thaiToEnglish.displayName.isEmpty)
        XCTAssertFalse(ConversionDirection.englishToThai.displayName.isEmpty)
        XCTAssertFalse(ConversionDirection.auto.displayName.isEmpty)
    }

    func testConversionDirection_Codable() {
        for dir in [ConversionDirection.thaiToEnglish, .englishToThai, .auto] {
            let encoded = try? JSONEncoder().encode(dir)
            XCTAssertNotNil(encoded)
            if let data = encoded {
                let decoded = try? JSONDecoder().decode(ConversionDirection.self, from: data)
                XCTAssertEqual(decoded, dir)
            }
        }
    }
}

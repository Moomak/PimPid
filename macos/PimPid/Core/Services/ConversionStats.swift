import Foundation
import SwiftUI

/// เก็บสถิติการแปลงข้อความ (จำนวนครั้ง, ความแม่นยำ, ประวัติล่าสุด)
@MainActor
final class ConversionStats: ObservableObject {
    static let shared = ConversionStats()

    // MARK: - Published Properties
    @Published private(set) var totalConversions: Int = 0
    @Published private(set) var todayConversions: Int = 0
    @Published private(set) var recentConversions: [ConversionRecord] = []
    /// Task 66: จำนวนการแปลงต่อวัน (key = yyyy-MM-dd) เก็บสูงสุด 30 วัน
    @Published private(set) var dailyCounts: [String: Int] = [:]

    // MARK: - Private Properties
    private let defaults = UserDefaults.standard
    private let maxRecentCount = 10
    private let maxDailyCountsDays = 30
    private var lastResetDate: Date

    // MARK: - Keys
    private enum Keys {
        static let totalConversions = "pimpid.stats.totalConversions"
        static let todayConversions = "pimpid.stats.todayConversions"
        static let lastResetDate = "pimpid.stats.lastResetDate"
        static let recentConversions = "pimpid.stats.recentConversions"
        static let dailyCounts = "pimpid.stats.dailyCounts"
    }

    init() {
        // Load stats from UserDefaults
        self.totalConversions = defaults.integer(forKey: Keys.totalConversions)
        self.todayConversions = defaults.integer(forKey: Keys.todayConversions)

        if let dateData = defaults.object(forKey: Keys.lastResetDate) as? Date {
            self.lastResetDate = dateData
        } else {
            self.lastResetDate = Date()
            defaults.set(lastResetDate, forKey: Keys.lastResetDate)
        }

        // Load recent conversions (จำกัดจำนวนเพื่อไม่ให้ UserDefaults ใหญ่เกิน — task 68)
        if let data = defaults.data(forKey: Keys.recentConversions),
           let decoded = try? JSONDecoder().decode([ConversionRecord].self, from: data) {
            self.recentConversions = Array(decoded.prefix(maxRecentCount))
        }

        if let data = defaults.data(forKey: Keys.dailyCounts),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            dailyCounts = trimDailyCounts(decoded)
        }

        // Reset daily count if it's a new day
        checkAndResetDaily()
    }

    /// Cached DateFormatter for date keys (yyyy-MM-dd) — avoid re-creating on every call
    private static let dateKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = Calendar.current.timeZone
        return f
    }()

    /// สถิติ 7 วันล่าสุด เรียงจากเก่าไปใหม่ (สำหรับกราฟ — task 66). วันนี้ใช้ todayConversions
    func last7DaysCounts() -> [(date: String, count: Int)] {
        let cal = Calendar.current
        let formatter = Self.dateKeyFormatter
        let todayKey = formatter.string(from: Date())
        var result: [(String, Int)] = []
        for offset in (0..<7).reversed() {
            guard let day = cal.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let key = formatter.string(from: day)
            let count = key == todayKey ? todayConversions : (dailyCounts[key] ?? 0)
            result.append((key, count))
        }
        return result
    }

    private static func dateKey(_ date: Date) -> String {
        dateKeyFormatter.string(from: date)
    }

    private func trimDailyCounts(_ dict: [String: Int]) -> [String: Int] {
        let sorted = dict.keys.sorted(by: >)
        guard sorted.count > maxDailyCountsDays else { return dict }
        var out = dict
        for key in sorted.dropFirst(maxDailyCountsDays) { out.removeValue(forKey: key) }
        return out
    }

    /// บันทึกการแปลงครั้งใหม่
    func recordConversion(from original: String, to converted: String, direction: ConversionDirection = .auto) {
        totalConversions += 1
        todayConversions += 1

        let record = ConversionRecord(
            original: original,
            converted: converted,
            direction: direction,
            timestamp: Date()
        )

        // Add to recent conversions (keep only last N — task 68)
        recentConversions.insert(record, at: 0)
        recentConversions = Array(recentConversions.prefix(maxRecentCount))

        save()
    }

    /// ยกเลิกการแปลงล่าสุด (undo)
    func undoLastConversion() -> ConversionRecord? {
        guard !recentConversions.isEmpty else { return nil }
        let record = recentConversions.removeFirst()

        // Decrease counters
        if totalConversions > 0 {
            totalConversions -= 1
        }
        if todayConversions > 0 {
            todayConversions -= 1
        }

        save()
        return record
    }

    /// รีเซ็ตสถิติทั้งหมด
    func resetAll() {
        totalConversions = 0
        todayConversions = 0
        recentConversions = []
        dailyCounts = [:]
        lastResetDate = Date()
        save()
    }

    /// รีเซ็ตสถิติวันนี้
    func resetToday() {
        todayConversions = 0
        lastResetDate = Date()
        save()
    }

    /// ล้างเฉพาะรายการแปลงล่าสุด (ไม่กระทบ total/today)
    func clearRecentConversions() {
        recentConversions = []
        save()
    }

    /// ตรวจสอบว่าต้องรีเซ็ตสถิติรายวันหรือไม่ (task 66: บันทึกวันก่อนเข้า dailyCounts)
    private func checkAndResetDaily() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastResetDate) {
            let previousKey = Self.dateKey(lastResetDate)
            if todayConversions > 0 {
                dailyCounts[previousKey] = todayConversions
                dailyCounts = trimDailyCounts(dailyCounts)
            }
            todayConversions = 0
            lastResetDate = Date()
            defaults.set(lastResetDate, forKey: Keys.lastResetDate)
            defaults.set(0, forKey: Keys.todayConversions)
            if let encoded = try? JSONEncoder().encode(dailyCounts) {
                defaults.set(encoded, forKey: Keys.dailyCounts)
            }
        }
    }

    /// บันทึกลง UserDefaults
    private func save() {
        defaults.set(totalConversions, forKey: Keys.totalConversions)
        defaults.set(todayConversions, forKey: Keys.todayConversions)
        defaults.set(lastResetDate, forKey: Keys.lastResetDate)

        if let encoded = try? JSONEncoder().encode(recentConversions) {
            defaults.set(encoded, forKey: Keys.recentConversions)
        }
        if let encoded = try? JSONEncoder().encode(dailyCounts) {
            defaults.set(encoded, forKey: Keys.dailyCounts)
        }
    }
}

// MARK: - ConversionRecord

struct ConversionRecord: Codable, Identifiable {
    let id: UUID
    let original: String
    let converted: String
    let direction: ConversionDirection
    let timestamp: Date

    init(original: String, converted: String, direction: ConversionDirection, timestamp: Date) {
        self.id = UUID()
        self.original = original
        self.converted = converted
        self.direction = direction
        self.timestamp = timestamp
    }
}

// MARK: - ConversionDirection

enum ConversionDirection: String, Codable {
    case thaiToEnglish = "thai_to_english"
    case englishToThai = "english_to_thai"
    case auto = "auto"

    var displayName: String {
        switch self {
        case .thaiToEnglish: return "ไทย → English"
        case .englishToThai: return "English → ไทย"
        case .auto: return "Auto"
        }
    }

    var emoji: String {
        switch self {
        case .thaiToEnglish: return "🇹🇭→🇬🇧"
        case .englishToThai: return "🇬🇧→🇹🇭"
        case .auto: return "🔄"
        }
    }
}

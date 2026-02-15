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

    // MARK: - Private Properties
    private let defaults = UserDefaults.standard
    private let maxRecentCount = 10
    private var lastResetDate: Date

    // MARK: - Keys
    private enum Keys {
        static let totalConversions = "pimpid.stats.totalConversions"
        static let todayConversions = "pimpid.stats.todayConversions"
        static let lastResetDate = "pimpid.stats.lastResetDate"
        static let recentConversions = "pimpid.stats.recentConversions"
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

        // Load recent conversions
        if let data = defaults.data(forKey: Keys.recentConversions),
           let decoded = try? JSONDecoder().decode([ConversionRecord].self, from: data) {
            self.recentConversions = decoded
        }

        // Reset daily count if it's a new day
        checkAndResetDaily()
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

        // Add to recent conversions (keep only last N)
        recentConversions.insert(record, at: 0)
        if recentConversions.count > maxRecentCount {
            recentConversions = Array(recentConversions.prefix(maxRecentCount))
        }

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
        lastResetDate = Date()
        save()
    }

    /// รีเซ็ตสถิติวันนี้
    func resetToday() {
        todayConversions = 0
        lastResetDate = Date()
        save()
    }

    /// ตรวจสอบว่าต้องรีเซ็ตสถิติรายวันหรือไม่
    private func checkAndResetDaily() {
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastResetDate) {
            todayConversions = 0
            lastResetDate = Date()
            defaults.set(lastResetDate, forKey: Keys.lastResetDate)
            defaults.set(0, forKey: Keys.todayConversions)
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

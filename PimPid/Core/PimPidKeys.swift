import Foundation

/// คีย์สำหรับ UserDefaults ใช้ที่เดียว (ตาม code-organization + data-persistence)
enum PimPidKeys {
    static let enabled = "pimpid.enabled"
    static let excludeWords = "pimpid.excludeWords"
}

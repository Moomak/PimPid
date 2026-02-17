import Foundation

extension Bundle {
    /// เวอร์ชันแอป (CFBundleShortVersionString) สำหรับแสดงใน About / Settings
    var appVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "–"
    }

    /// Build number (CFBundleVersion) สำหรับแสดงใน About
    var buildNumber: String {
        (infoDictionary?["CFBundleVersion"] as? String) ?? "–"
    }
}

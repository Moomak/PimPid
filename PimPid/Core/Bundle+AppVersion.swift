import Foundation

extension Bundle {
    /// เวอร์ชันแอป (CFBundleShortVersionString) สำหรับแสดงใน About / Settings
    var appVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "–"
    }
}

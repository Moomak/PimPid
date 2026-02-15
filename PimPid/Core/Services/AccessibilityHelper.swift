import AppKit
import ApplicationServices
import Foundation

/// ใช้ตรวจสิทธิ์ Accessibility และเปิดหน้า System Settings (สำหรับ Auto-Correct)
enum AccessibilityHelper {
    /// มีสิทธิ์ Accessibility หรือยัง
    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrustedWithOptions([
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false
        ] as CFDictionary)
    }

    /// เปิด System Settings ไปที่หน้า Accessibility
    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

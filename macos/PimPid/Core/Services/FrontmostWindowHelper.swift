import Foundation
import AppKit
import CoreGraphics

/// Task 8: ดึงข้อมูลหน้าต่างที่โฟกัสอยู่ (bundle ID + window number) สำหรับ exclude ต่อ window
enum FrontmostWindowHelper {

    private static let keyWindowNumber = "kCGWindowNumber"
    private static let keyOwnerPID = "kCGWindowOwnerPID"

    /// คืนค่า "bundleID:windowNumber" ของหน้าต่างที่โฟกัสอยู่ (แอป frontmost + หน้าต่างด้านบน)
    /// คืน nil ถ้าหน้าต่างหรือ bundle ID หาไม่ได้
    static func frontmostWindowKey() -> String? {
        guard let front = NSWorkspace.shared.frontmostApplication,
              let bundleID = front.bundleIdentifier else { return nil }
        let pid = front.processIdentifier
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        // ลำดับจาก front ไป back — เอา window แรกที่เป็นของแอป frontmost
        for info in list {
            let ownerPID: Int32? = (info[keyOwnerPID] as? NSNumber)?.int32Value ?? (info[keyOwnerPID] as? Int32)
            guard ownerPID == pid else { continue }
            let num: Int? = (info[keyWindowNumber] as? NSNumber)?.intValue ?? (info[keyWindowNumber] as? Int)
            guard let n = num else { continue }
            return "\(bundleID):\(n)"
        }
        return nil
    }
}

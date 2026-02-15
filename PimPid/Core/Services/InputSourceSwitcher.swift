import AppKit
import Carbon
import Foundation

/// สลับแหล่งป้อนข้อมูล (คีย์บอร์ด) เป็นภาษาไทยหรืออังกฤษ หลังแปลงข้อความ
enum InputSourceSwitcher {
    enum Target {
        case thai
        case english
    }

    private static let thaiSourceIDs = [
        "com.apple.keylayout.Thai",
        "com.apple.keylayout.Thai-Kedmanee",
        "com.apple.keylayout.Thai-Patta-Choti",
    ]
    private static let englishSourceIDs = [
        "com.apple.keylayout.ABC",
        "com.apple.keylayout.US",
        "com.apple.keylayout.USExtended",
    ]

    /// สลับไปคีย์บอร์ดที่ต้องการ — ต้องเรียกจาก main thread (Carbon API)
    /// ถ้าเรียกจาก background thread จะ dispatch ไป main ให้อัตโนมัติ
    static func switchTo(_ target: Target) {
        if Thread.isMainThread {
            performSwitch(target)
        } else {
            DispatchQueue.main.sync {
                performSwitch(target)
            }
        }
    }

    private static func performSwitch(_ target: Target) {
        guard let listRef = TISCreateInputSourceList(nil, true) else { return }
        let nsArray = listRef.takeRetainedValue() as NSArray
        guard let list = nsArray as? [TISInputSource] else { return }

        let layoutList = list.filter { source in
            guard let typeRef = TISGetInputSourceProperty(source, kTISPropertyInputSourceType) else { return false }
            let typeStr = Unmanaged<CFString>.fromOpaque(typeRef).takeUnretainedValue() as String
            let expected = kTISTypeKeyboardLayout as String
            return typeStr == expected
        }

        let sourceID: (TISInputSource) -> String? = { source in
            guard let raw = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return nil }
            return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
        }

        let toSelect: TISInputSource?
        switch target {
        case .thai:
            toSelect = layoutList.first { source in
                guard let sid = sourceID(source) else { return false }
                return thaiSourceIDs.contains { sid.hasPrefix($0) || sid.contains("Thai") }
            }
        case .english:
            toSelect = layoutList.first { source in
                guard let sid = sourceID(source) else { return false }
                return englishSourceIDs.contains { sid.hasPrefix($0) || sid.contains("ABC") || sid.contains("US") }
            }
        }

        if let source = toSelect {
            TISSelectInputSource(source)
        }
    }
}

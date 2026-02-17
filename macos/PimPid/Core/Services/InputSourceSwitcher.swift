import AppKit
import Carbon
import Foundation

/// สลับแหล่งป้อนข้อมูล (คีย์บอร์ด) เป็นภาษาไทยหรืออังกฤษ หลังแปลงข้อความ
/// Task 31: layout นอกรายการในตัว — match ด้วย prefix/contains (Thai, ABC, US) จึงรองรับ layout ที่ผู้ใช้เพิ่ม
/// Task 33: จำ layout ก่อนสลับ เพื่อกลับไป layout เดิมได้
enum InputSourceSwitcher {
    enum Target {
        case thai
        case english
    }

    /// Layout ID ก่อนสลับ (สำหรับ switchBackToPrevious — task 33)
    private static var previousLayoutID: String?

    /// มี layout ก่อนสลับเก็บไว้หรือไม่ (สำหรับแสดงปุ่ม "กลับไป layout เดิม" ใน UI)
    static var hasPreviousLayout: Bool { previousLayoutID != nil }

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

    /// Task 34: จากรายการ source ID คืนค่า ID แรกที่ตรงกับ target — ใช้ใน unit test โดยไม่ต้องเรียก TIS
    static func selectableSourceID(from sourceIDs: [String], target: Target) -> String? {
        switch target {
        case .thai:
            return sourceIDs.first { sid in
                thaiSourceIDs.contains { sid.hasPrefix($0) || sid.contains("Thai") }
            }
        case .english:
            return sourceIDs.first { sid in
                englishSourceIDs.contains { sid.hasPrefix($0) || sid.contains("ABC") || sid.contains("US") }
            }
        }
    }

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
        let ids = layoutList.compactMap { sourceID($0) }
        guard let selectedID = selectableSourceID(from: ids, target: target) else { return }
        let toSelect = layoutList.first { sourceID($0) == selectedID }

        if let source = toSelect {
            previousLayoutID = currentLayoutID()
            TISSelectInputSource(source)
        }
    }

    /// คืนค่า layout ที่เลือกก่อนสลับ (task 33) — เรียกหลัง switchTo เพื่อให้ผู้ใช้กด "กลับไป layout เดิม" ได้
    static func switchBackToPrevious() {
        guard let listRef = TISCreateInputSourceList(nil, true), let pid = previousLayoutID else { return }
        let nsArray = listRef.takeRetainedValue() as NSArray
        guard let list = nsArray as? [TISInputSource] else { return }
        let layoutList = list.filter { source in
            guard let typeRef = TISGetInputSourceProperty(source, kTISPropertyInputSourceType) else { return false }
            let typeStr = Unmanaged<CFString>.fromOpaque(typeRef).takeUnretainedValue() as String
            return typeStr == (kTISTypeKeyboardLayout as String)
        }
        guard let source = layoutList.first(where: { currentLayoutID($0) == pid }) else { return }
        TISSelectInputSource(source)
        previousLayoutID = nil
    }

    private static func currentLayoutID(_ source: TISInputSource? = nil) -> String? {
        if let s = source {
            guard let raw = TISGetInputSourceProperty(s, kTISPropertyInputSourceID) else { return nil }
            return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
        }
        return autoreleasepool {
            guard let ref = TISCopyCurrentKeyboardInputSource() else { return nil }
            let src = ref.takeRetainedValue()
            guard let raw = TISGetInputSourceProperty(src, kTISPropertyInputSourceID) else { return nil }
            return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
        }
    }

    /// ชื่อ layout คีย์บอร์ดที่เลือกอยู่ (สำหรับแสดงใน UI — task 32)
    static func currentLayoutName() -> String? {
        return autoreleasepool {
            guard let ref = TISCopyCurrentKeyboardInputSource() else { return nil }
            let source = ref.takeRetainedValue()
            guard let nameRef = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else { return nil }
            return Unmanaged<CFString>.fromOpaque(nameRef).takeUnretainedValue() as String
        }
    }
}

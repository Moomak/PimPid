# PimPid

โปรแกรมสำหรับ macOS: **เมื่อพิมพ์ผิดภาษา (ไทย/อังกฤษ ตามตำแหน่งปุ่ม) จะแก้แล้วสลับภาษาให้** และมี **ระบบ exclude คำ** ที่ไม่ต้องการให้แปลง

## คุณสมบัติ

- **สลับภาษาข้อความที่เลือก** — เลือกข้อความที่พิมพ์ผิดภาษา (เช่น พิมพ์ไทยแต่ตั้งใจเป็นอังกฤษ) กด **⌘⇧L** จะแปลงตามตำแหน่งปุ่มคีย์บอร์ด (ไทย Kedmanee ↔ QWERTY)
- **Exclude คำ** — กำหนดรายการคำหรือวลีที่ไม่ต้องการให้โปรแกรมแก้ไข (ตั้งค่าได้ใน Settings)
- **เปิด/ปิดการทำงาน** — สลับจากไอคอนในเมนูบาร์

## วิธีใช้

1. เลือกข้อความที่ผิดภาษาในแอปใดก็ได้
2. กด **⌘⇧L** (Command + Shift + L)
3. ข้อความจะถูกแทนที่ด้วยภาษาที่แปลงแล้ว

## การติดตั้ง

### วิธีที่ 1: สร้าง .app ด้วย Xcode (แนะนำ)

1. เปิด Xcode → **File → New → Project** → **macOS → App**
2. Product Name: `PimPid`, Interface: **SwiftUI**, Life Cycle: **SwiftUI App**
3. บันทึกแล้วลบ `ContentView.swift` ที่สร้างให้
4. คลิกขวาที่กลุ่ม PimPid → **Add Files to "PimPid"…** → เลือกโฟลเดอร์ `PimPid` (ใน repo นี้) → **Create groups**, ติ๊ก target PimPid
5. **Signing & Capabilities** → ปิด **App Sandbox** หรือเพิ่ม `PimPid.entitlements` (path: `PimPid/PimPid.entitlements`)
6. Build และ Run (⌘R)

### วิธีที่ 2: รันด้วย Swift Package (ทดสอบ)

จากโฟลเดอร์โปรเจกต์ (ที่มี `Package.swift`):

```bash
swift run PimPid
```

จะได้เมนูบาร์และใช้งานได้ แต่ยังไม่ใช่ .app bundle; สำหรับการติดตั้งถาวรใช้วิธีที่ 1

## สิทธิ์ที่จำเป็น

- **Accessibility** — เพื่อให้ shortcut **⌘⇧L** ทำงานเมื่อแอปอื่นโฟกัสอยู่ และเพื่อจำลอง Copy/Paste
- หลังติดตั้ง: เปิด **System Settings → Privacy & Security → Accessibility** แล้วเพิ่ม **PimPid** และเปิดใช้งาน

## โครงสร้างโปรเจกต์

```
PimPid/
├── PimPidApp.swift                # จุดเข้า + MenuBarExtra + Settings
├── Core/
│   ├── AppState.swift
│   └── Services/
│       ├── KeyboardLayoutConverter.swift   # แมปไทย↔อังกฤษ (Kedmanee/QWERTY)
│       ├── ExcludeListStore.swift          # เก็บคำที่ exclude
│       ├── TextReplacementService.swift    # Copy → แปลง → Paste
│       └── KeyboardShortcutManager.swift   # Global shortcut ⌘⇧L
├── Features/
│   ├── MenuBar/
│   │   └── MenuBarContentView.swift
│   └── Settings/
│       └── SettingsView.swift              # ตั้งค่า + รายการ Exclude
├── PimPid.entitlements
└── README.md
```

## หมายเหตุ

- ใช้การแมปคีย์บอร์ด **ไทย Kedmanee** กับ **US QWERTY** (ตำแหน่งปุ่มเดียวกัน)
- ถ้าแอปใดใช้ shortcut **⌘⇧L** อยู่แล้ว อาจชนกัน — แนะนำให้ปิดการใช้งาน PimPid ชั่วคราวจากเมนูบาร์

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

### วิธีที่ 3: ใช้ .app ที่ build ไว้แล้ว (ไม่ต้อง build เอง)

ใน repo มีโฟลเดอร์ [**release/PimPid.app**](release/) — ดาวน์โหลดแล้วย้ายไป Applications หรือเปิดได้เลย (macOS 14+, Apple Silicon) ดูคำอธิบายใน [release/README.md](release/README.md)

## สิทธิ์ที่จำเป็น

- **Accessibility** — เพื่อให้ shortcut **⌘⇧L** ทำงานเมื่อแอปอื่นโฟกัสอยู่ และเพื่อจำลอง Copy/Paste
- หลังติดตั้ง: เปิด **System Settings → Privacy & Security → Accessibility** แล้วเพิ่ม **PimPid** และเปิดใช้งาน

## โครงสร้างโปรเจกต์

```
PimPid/
├── PimPidApp.swift                     # จุดเข้า + MenuBarExtra + Settings + Onboarding
├── Core/
│   ├── AppState.swift
│   ├── PimPidKeys.swift                # UserDefaults keys
│   └── Services/
│       ├── AutoCorrectionEngine.swift  # CGEventTap + debounce แก้คำอัตโนมัติ
│       ├── KeyboardLayoutConverter.swift
│       ├── ExcludeListStore.swift
│       ├── TextReplacementService.swift
│       ├── TextManipulator.swift       # Backspace + clipboard replace
│       ├── KeyboardShortcutManager.swift # Global shortcut ⌘⇧L
│       ├── InputSourceSwitcher.swift   # สลับคีย์บอร์ดไทย/อังกฤษ
│       ├── ConversionValidator.swift
│       ├── ConversionStats.swift
│       ├── NotificationService.swift
│       ├── PimPidServiceProvider.swift # NSServices menu
│       └── ...
├── Features/
│   ├── MenuBar/
│   ├── Settings/                       # Sidebar: ทั่วไป, Shortcut, Auto-Correct, Exclude, รูปลักษณ์, เกี่ยวกับ
│   ├── Onboarding/
│   └── Feedback/                       # Toast
├── Resources/
│   └── ThaiWords.txt
└── ...
```

## รายการคำไทย (Thai word list)

แอปมี **รายการคำไทย** — ถ้าข้อความที่พิมพ์ตรงกับคำในรายการ **จะไม่ถูกแปลง** เป็นอังกฤษ (ลดการแก้คำผิดแบบ ประ→xit, เจอ→g0v)

- **ไฟล์ [PimPid/Resources/ThaiWords.txt](PimPid/Resources/ThaiWords.txt)** มีคำไทยประมาณ **52,000+ คำ** จาก [wannaphong/thai-wordlist](https://github.com/wannaphong/thai-wordlist) และ [korakot/thainlp](https://github.com/korakot/thainlp) (Apache 2.0 / ใช้ได้อย่างอิสระ)
- แอปโหลดคำจากไฟล์นี้ + คำในตัว (embedded) แล้วรวมกันใช้
- **ต้องการเพิ่มคำ**: เพิ่มใน ThaiWords.txt (บรรทัดละคำ บรรทัดที่ขึ้นต้นด้วย `#` เป็น comment) แล้ว build ใหม่ หรือ copy ไฟล์ไปไว้ใน `PimPid.app/Contents/Resources/ThaiWords.txt` แล้วเปิดแอปใหม่

## การทดสอบ (Testing)

จากโฟลเดอร์โปรเจกต์ รัน unit tests:

```bash
swift test
```

ทดสอบการแปลง layout (KeyboardLayoutConverter) และกฎไม่แทนที่คำที่ตั้งใจพิมพ์ (ConversionValidator) เช่น ไม่แปลง คำไทย "ประ"/"เจอ" เป็น "xit"/"g0v" และไม่แปลงคำอังกฤษ "test" เป็น "ะำหะ"

## หมายเหตุ

- ใช้การแมปคีย์บอร์ด **ไทย Kedmanee** กับ **US QWERTY** (ตำแหน่งปุ่มเดียวกัน)
- ถ้าแอปใดใช้ shortcut **⌘⇧L** อยู่แล้ว อาจชนกัน — แนะนำให้ปิดการใช้งาน PimPid ชั่วคราวจากเมนูบาร์

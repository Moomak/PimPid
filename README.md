# PimPid

โปรแกรมแปลงข้อความที่พิมพ์ผิดภาษา (ไทย Kedmanee ↔ QWERTY) พร้อม Auto-Correct — รองรับทั้ง **macOS** และ **Windows**

## คุณสมบัติ

- **สลับภาษาข้อความที่เลือก** — เลือกข้อความที่พิมพ์ผิดภาษา กดปุ่มลัด แล้วแปลงตามตำแหน่งปุ่มคีย์บอร์ด (ไทย Kedmanee ↔ QWERTY)
- **Auto-Correct** — แก้ไขอัตโนมัติเมื่อพิมพ์ผิดภาษา (real-time)
- **Exclude คำ** — กำหนดรายการคำที่ไม่ต้องการให้แปลง
- **System Tray / Menu Bar** — เปิด/ปิดการทำงานจากไอคอน

## ดาวน์โหลด

ไปที่หน้า [Releases](https://github.com/Moomak/PimPid/releases) เพื่อดาวน์โหลดไฟล์สำหรับระบบของคุณ:

| ระบบ | ไฟล์ | ปุ่มลัด |
|------|------|---------|
| macOS (14+, Apple Silicon) | `PimPid.app.zip` | ⌘⇧L |
| Windows (10/11) | `PimPid-Windows.exe` | Ctrl+Shift+L |

## โครงสร้างโปรเจกต์

```
PimPid/
├── macos/                    # macOS version (Swift + SwiftUI)
│   ├── PimPid/               #   Source code
│   ├── PimPid.xcodeproj/     #   Xcode project
│   ├── Package.swift         #   Swift Package Manager
│   ├── Tests/                #   Unit tests
│   └── build_release.sh      #   Build script
├── windows/                  # Windows version (Electron + TypeScript)
│   ├── src/                  #   Source code
│   ├── package.json          #   Node.js project
│   └── tsconfig.json         #   TypeScript config
└── releases/                 # Pre-built releases
    ├── macos/PimPid.app
    └── windows/
```

---

## macOS

### วิธีใช้

1. เปิดโปรแกรม — ไอคอนจะปรากฏใน Menu Bar
2. เลือกข้อความที่พิมพ์ผิดภาษา กด **⌘⇧L** (Command + Shift + L)
3. ข้อความจะถูกแปลงอัตโนมัติ

### ติดตั้ง

**วิธีที่ 1: ใช้ .app ที่ build ไว้แล้ว** — ดาวน์โหลดจาก [Releases](https://github.com/Moomak/PimPid/releases) หรือในโฟลเดอร์ [releases/macos/](releases/macos/)

**วิธีที่ 2: Build เอง**

```bash
cd macos
swift build -c release
./build_release.sh
```

**วิธีที่ 3: รันจาก source**

```bash
cd macos
swift run PimPid
```

### สิทธิ์ที่จำเป็น

- **Accessibility** — System Settings → Privacy & Security → Accessibility → เพิ่ม PimPid

---

## Windows

### วิธีใช้

1. เปิดโปรแกรม — ไอคอนจะปรากฏใน System Tray
2. เลือกข้อความที่พิมพ์ผิดภาษา กด **Ctrl+Shift+L**
3. ข้อความจะถูกแปลงอัตโนมัติ

### ติดตั้ง

**วิธีที่ 1: ดาวน์โหลด .exe** — ดาวน์โหลดจาก [Releases](https://github.com/Moomak/PimPid/releases)

**วิธีที่ 2: Build เอง**

```bash
cd windows
npm install
npm run dist
```

ไฟล์ .exe จะอยู่ใน `windows/release/`

---

## การทดสอบ

```bash
# macOS
cd macos && swift test

# Windows
cd windows && npm run build
```

## หมายเหตุ

- ใช้การแมปคีย์บอร์ด **ไทย Kedmanee** กับ **US QWERTY** (ตำแหน่งปุ่มเดียวกัน)
- macOS version ใช้ Swift + SwiftUI + Accessibility API
- Windows version ใช้ Electron + TypeScript + PowerShell SendKeys

# PimPid Windows

โปรแกรมแปลงข้อความที่พิมพ์ผิดภาษา (ไทย Kedmanee ↔ QWERTY) สำหรับ Windows

## คุณสมบัติ

- **Convert Selected Text** — เลือกข้อความแล้วกด `Ctrl+Shift+L` เพื่อแปลงภาษา
- **Auto-Correct** — แก้ไขอัตโนมัติเมื่อพิมพ์ผิดภาษา (ต้องติดตั้ง `uiohook-napi`)
- **System Tray** — ไอคอนใน system tray สำหรับเปิด/ปิดการทำงาน

## วิธี Build

### ขั้นตอนที่ 1: ติดตั้ง dependencies

```bash
cd release-windows
npm install
```

### ขั้นตอนที่ 2: ทดสอบ

```bash
npm run start
```

### ขั้นตอนที่ 3: สร้าง .exe

```bash
npm run dist
```

ไฟล์ .exe จะอยู่ใน `release-windows/release/`

## วิธีใช้

1. เปิดโปรแกรม — จะแสดงไอคอนใน System Tray (มุมขวาล่างของหน้าจอ)
2. **เลือกข้อความ** ที่พิมพ์ผิดภาษา แล้วกด **Ctrl+Shift+L**
3. ข้อความจะถูกแปลงอัตโนมัติ (ไทย→อังกฤษ หรือ อังกฤษ→ไทย)

### Auto-Correct

- คลิกขวาที่ไอคอน tray → เลือก "Auto-Correct: OFF" เพื่อเปิด
- ต้องติดตั้ง `uiohook-napi`: `npm install uiohook-napi`
- เมื่อเปิด จะตรวจจับการพิมพ์และแก้ไขอัตโนมัติเมื่อตรวจพบว่าพิมพ์ผิดภาษา

## โครงสร้าง

```
src/
├── main.ts              # Electron main process (tray, shortcut)
├── converter.ts          # Thai ↔ English keyboard mapping
├── auto-correction.ts    # Auto-correction engine (keyboard hook)
├── thai-words.ts         # Thai word list for validation
├── preload.ts            # Preload script
└── icon.png              # Tray icon
```

## Requirements

- Node.js 18+
- Windows 10/11

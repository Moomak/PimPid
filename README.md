# PimPid — Thai ⇄ English Keyboard Converter

พิมพ์ผิดภาษา? กด shortcut แปลงทันที ไม่ต้องลบแล้วพิมพ์ใหม่

PimPid แปลงข้อความที่พิมพ์ผิด layout (ไทย Kedmanee ↔ US QWERTY) ตามตำแหน่งปุ่มคีย์บอร์ด พร้อม Auto-Correct แก้ไขอัตโนมัติขณะพิมพ์ — รองรับทั้ง **macOS** และ **Windows**

---

## ดาวน์โหลด

> **[ดาวน์โหลด PimPid v1.7.0 — Latest Release](https://github.com/Moomak/PimPid/releases/latest)**

| Platform | ไฟล์ | วิธี install |
|----------|------|-------------|
| **macOS** 14+ | `.dmg` | เปิด DMG → ลากไป Applications → Right-click > Open |
| **Windows** 10/11 | `.exe` | Portable — ดับเบิลคลิกรันได้เลย |

---

## วิธีติดตั้ง

### macOS

1. ดาวน์โหลด **`.dmg`** จาก [Releases](https://github.com/Moomak/PimPid/releases/latest)
2. เปิด DMG → ลาก **PimPid** ไปไว้ใน **Applications**
3. เปิด PimPid — **ครั้งแรก** macOS จะถาม:

   > **Right-click** ที่ PimPid.app → เลือก **Open** → กด **Open**
   >
   > หรือไปที่ System Settings → Privacy & Security → กด **Open Anyway**

4. อนุญาต **Accessibility** เมื่อระบบถาม (จำเป็นสำหรับการแปลงข้อความ)

> ต้องทำขั้นตอน 3 **แค่ครั้งเดียว** — ครั้งต่อไปเปิดได้ปกติ

### Windows

1. ดาวน์โหลด **`.exe`** จาก [Releases](https://github.com/Moomak/PimPid/releases/latest)
2. รันไฟล์ได้เลย — ไม่ต้อง install
3. PimPid จะอยู่ใน System Tray (มุมขวาล่าง)

---

## วิธีใช้งาน

### แปลงข้อความด้วย Shortcut
1. **เลือก** ข้อความที่พิมพ์ผิดภาษา
2. กด **⌘⇧L** (macOS) หรือ **Ctrl+Shift+L** (Windows)
3. ข้อความแปลงทันที (shortcut เปลี่ยนได้ใน Settings)

### Auto-Correct (แก้ไขอัตโนมัติ)
เปิดจาก menu bar / tray → **Auto-Correct: ON** → พิมพ์ผิดภาษา PimPid แก้ให้ทันที

---

## คุณสมบัติ

| คุณสมบัติ | macOS | Windows |
|-----------|:-----:|:-------:|
| แปลงข้อความที่เลือก (Shortcut) | ✅ | ✅ |
| Auto-Correct ขณะพิมพ์ | ✅ | ✅ |
| Custom Shortcut | ✅ | ✅ |
| Statistics + Recent Conversions | ✅ | ✅ |
| Exclude Words | ✅ | ✅ |
| Appearance (Theme / Font Size) | ✅ | ✅ |
| Onboarding | ✅ | ✅ |
| Toast Notification | ✅ | ✅ |
| Floating Convert Button | — | ✅ |
| Export CSV | ✅ | ✅ |
| App/Window Exclusion | ✅ | — |
| i18n (ไทย / English) | ✅ | ✅ |

---

## Troubleshooting

<details>
<summary><b>macOS: "PimPid is damaged and can't be opened"</b></summary>

เกิดจาก Gatekeeper บล็อกแอป — แก้โดย:

**วิธี A** (แนะนำ): Right-click ที่ PimPid.app → Open → Open

**วิธี B**: รันใน Terminal:
```bash
xattr -cr /Applications/PimPid.app
```
</details>

<details>
<summary><b>macOS: ขอ Accessibility permission</b></summary>

PimPid ต้องการ Accessibility เพื่ออ่าน/แปลง/วางข้อความ + Auto-Correct

ไปที่: **System Settings → Privacy & Security → Accessibility** → เปิดสวิตช์ PimPid
</details>

<details>
<summary><b>macOS: Auto-Correct ไม่ทำงาน</b></summary>

1. ตรวจ Accessibility permission เปิดแล้ว
2. ตรวจ Auto-Correct เปิดอยู่ (menu bar)
3. ลอง toggle ปิด/เปิดใหม่
</details>

<details>
<summary><b>Windows: Ctrl+Shift+L ไม่ทำงาน</b></summary>

1. ตรวจว่า PimPid ทำงานอยู่ (icon ใน System Tray)
2. Shortcut อาจชนกับโปรแกรมอื่น → เปลี่ยนได้ใน Settings
3. บางโปรแกรม (เกม, IDE) อาจดักจับ keyboard ก่อน
</details>

---

## Build จาก Source

```bash
# macOS
cd macos && swift build -c release && ./build_release.sh

# Windows
cd windows && npm install && npm run build && npm run dist

# Tests
cd macos && swift test          # 189 tests
cd windows && npm test          # 96 tests
```

---

## หมายเหตุ

- แมปคีย์บอร์ด **ไทย Kedmanee** ↔ **US QWERTY** ตามตำแหน่งปุ่ม
- macOS: Swift + SwiftUI + CGEventTap
- Windows: Electron + TypeScript
- ทำงาน **offline ทั้งหมด** — ไม่ส่งข้อมูลออก

## License

MIT

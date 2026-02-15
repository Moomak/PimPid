# PimPid App Icon

ไอคอนเป็นรูป **คีย์บอร์ด** + **สัญลักษณ์สลับภาษา (↔)** พื้นหลัง gradient เทา วงกลมสีน้ำเงินด้านหลังลูกศร

## สร้างใหม่

```bash
cd PimPid/Icon
./build_icon.sh
```

จะได้ `PimPid.icns` สำหรับใส่ในแอป (หรือ copy ไปที่ `release/PimPid.app/Contents/Resources/` แล้วตั้ง `CFBundleIconFile` ใน Info.plist)

## ไฟล์

- `GenerateIcon.swift` — สคริปต์วาดไอคอน 1024×1024 (AppKit)
- `build_icon.sh` — เรียก Swift แล้วใช้ `sips` + `iconutil` สร้าง `.icns`
- `AppIcon.iconset/` — ชุด PNG หลายขนาด (สร้างโดย build_icon.sh)
- `PimPid.icns` — ไฟล์ไอคอนสำหรับ macOS (สร้างโดย build_icon.sh)

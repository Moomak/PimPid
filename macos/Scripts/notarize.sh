#!/usr/bin/env bash
# Task 87: Notarization script สำหรับ Apple notarize (แจกจ่ายนอก Mac App Store)
# ใช้: ./Scripts/notarize.sh [path/to/PimPid.app]
# ต้องมี Apple ID (APPLE_ID, APPLE_APP_SPECIFIC_PASSWORD) หรือใช้ notarytool ที่ login แล้ว
# ก่อนรัน: 1) build release: ./build_release.sh  2) สร้าง zip: ditto -c -k --sequesterRsrc --keepParent release/PimPid.app PimPid.zip

set -e
APP_PATH="${1:-release/PimPid.app}"
ZIP_PATH="${APP_PATH%.app}.zip"

if [[ ! -d "$APP_PATH" ]]; then
  echo "ไม่พบแอป: $APP_PATH" >&2
  echo "ใช้: $0 [path/to/PimPid.app]" >&2
  exit 1
fi

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "สร้าง zip..."
  ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
fi

echo "ส่งไป notarize (ใช้ xcrun notarytool)..."
echo "ถ้ายังไม่ login: xcrun notarytool store-credentials --apple-id YOUR_APPLE_ID --team-id TEAM_ID --password APP_SPECIFIC_PASSWORD"
SUBMIT_OUT=$(xcrun notarytool submit "$ZIP_PATH" --wait 2>&1) || true
if echo "$SUBMIT_OUT" | grep -q "status: Accepted"; then
  echo "✅ Notarization สำเร็จ"
  xcrun stapler staple "$APP_PATH"
  echo "✅ Stapled to $APP_PATH"
else
  echo "$SUBMIT_OUT"
  echo "❌ Notarization ล้มเหลว — ตรวจสอบ Apple ID / app-specific password / entitlements"
  exit 1
fi

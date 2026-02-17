#!/bin/bash
# สร้าง App Icon (คีย์บอร์ด + สัญลักษณ์สลับภาษา) เป็น .icns
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$DIR/AppIcon.iconset"
mkdir -p "$OUT"
cd "$DIR"
export ICON_OUT="$OUT"
swift GenerateIcon.swift
# ใช้ 1024 เป็นต้นแบบ สร้างทุกขนาดที่ iconset ต้องการ
SIZE=1024
for s in 16 32 128 256 512; do
  sips -z $s $s "$OUT/icon_1024.png" --out "$OUT/icon_${s}x${s}.png"
done
# @2x = ขนาด 2 เท่า
sips -z 32 32 "$OUT/icon_1024.png" --out "$OUT/icon_16x16@2x.png"
sips -z 64 64 "$OUT/icon_1024.png" --out "$OUT/icon_32x32@2x.png"
sips -z 256 256 "$OUT/icon_1024.png" --out "$OUT/icon_128x128@2x.png"
sips -z 512 512 "$OUT/icon_1024.png" --out "$OUT/icon_256x256@2x.png"
cp "$OUT/icon_1024.png" "$OUT/icon_512x512@2x.png"
iconutil -c icns "$OUT" -o "$DIR/PimPid.icns"
echo "Created: $DIR/PimPid.icns"

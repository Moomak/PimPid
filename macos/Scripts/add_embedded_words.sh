#!/usr/bin/env bash
# Task 91: สคริปต์เพิ่มคำใน EmbeddedThaiWords จากไฟล์
# ใช้: ./Scripts/add_embedded_words.sh <ไฟล์.txt>
# ไฟล์ควรเป็นบรรทัดละคำ (และหรือบรรทัดว่าง/ขึ้นต้นด้วย # จะข้าม)
# พิมพ์ผลลัพธ์เป็นบรรทัดที่สามารถ copy ไปวางใน PimPid/Core/Services/ThaiWordList.swift
# ภายใน embeddedString (ก่อน """ สุดท้าย)

set -e
FILE="${1:?ใช้: $0 <path/to/words.txt>}"
if [[ ! -f "$FILE" ]]; then
  echo "ไม่พบไฟล์: $FILE" >&2
  exit 1
fi
echo "# เพิ่มบรรทัดด้านล่างใน EmbeddedThaiWords.embeddedString (เรียงตามตัวอักษรหรือตามที่ต้องการ):"
echo "# เปิด PimPid/Core/Services/ThaiWordList.swift แล้ววางก่อน """ ที่ปิด embeddedString"
echo ""
while IFS= read -r line || [[ -n "$line" ]]; do
  line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  printf '%s\n' "$line"
done < "$FILE"

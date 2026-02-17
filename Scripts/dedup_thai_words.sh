#!/usr/bin/env bash
# Task 21: ค้นหาและลบคำซ้ำใน ThaiWords / รายการคำ
# ใช้: ./Scripts/dedup_thai_words.sh [ไฟล์.txt]
# ถ้าไม่ระบุไฟล์ อ่านจาก stdin (บรรทัดละคำ)
# พิมพ์ผลลัพธ์เรียงและไม่ซ้ำ (บรรทัดที่ซ้ำจะเหลือแค่ครั้งเดียว)

set -e
if [[ -n "$1" ]]; then
  [[ ! -f "$1" ]] && { echo "ไม่พบไฟล์: $1" >&2; exit 1; }
  exec < "$1"
fi
sort -u

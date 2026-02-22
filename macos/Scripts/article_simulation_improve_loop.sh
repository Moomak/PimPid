#!/usr/bin/env bash
# วนรัน article simulation test แล้วเพิ่มคำจาก failure-words.txt (คำสั้นที่ปลอดภัย)
# ถ้า passed ลดลงจะ revert การเพิ่มคำในรอบนั้น
# ใช้: PIMPID_FAILURES_DIR=/tmp ./Scripts/article_simulation_improve_loop.sh [จำนวนรอบ เช่น 50]
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
FAILURES_DIR="${PIMPID_FAILURES_DIR:-/tmp}"
ROUNDS="${1:-50}"
SWIFT_FILE="$ROOT/macos/PimPid/Core/Services/ThaiWordList.swift"
TS_FILE="$ROOT/windows/src/thai-words.ts"

run_test() {
  (cd "$ROOT/macos" && PIMPID_FAILURES_DIR="$FAILURES_DIR" swift test --filter ArticleSimulationTests.testArticleSimulationAllArticles 2>&1) >/dev/null
  awk -F= '/^passed=/ { print $2 }' "$FAILURES_DIR/summary.txt"
}

# คำที่ขึ้นต้นแบบนี้มักเป็น segment พังจาก tokenizer — ไม่เพิ่ม
skip_prefix() {
  local w="$1"
  case "$w" in
    ต์*|ษ*|รียม*|ดตาม*|ดติดตาม*|ยความ*|์*) return 0 ;;  # skip
    *) return 1 ;;
  esac
}

# ความยาวเหมาะสม และเป็นคำที่ดูปลอดภัย (ไม่ยาวเกิน)
ok_length() {
  local w="$1"
  local n="${#w}"
  (( n >= 2 && n <= 20 ))
}

already_in_swift() {
  grep -qF "$1" "$SWIFT_FILE"
}

add_word_swift() {
  local word="$1"
  local line
  line=$(grep -n '^"""$' "$SWIFT_FILE" | head -1 | cut -d: -f1)
  sed -i '' "${line}i\\
$word
" "$SWIFT_FILE"
}

add_word_ts() {
  local word="$1"
  # ใส่ก่อนบรรทัด ];
  sed -i '' '/^];$/i\
  "'"$word"'",
' "$TS_FILE"
}

echo "เริ่มวนรอบ (สูงสุด $ROUNDS รอบ), PIMPID_FAILURES_DIR=$FAILURES_DIR"
prev_passed=$(run_test)
echo "Baseline passed: $prev_passed"
added=0
round=0

while (( round < ROUNDS )); do
  (( round++ ))
  [[ ! -f "$FAILURES_DIR/failure-words.txt" ]] && echo "ไม่มี $FAILURES_DIR/failure-words.txt" && break
  chosen=""
  while IFS= read -r w || [[ -n "$w" ]]; do
    w=$(printf '%s' "$w" | tr -d '\r\n')
    [[ -z "$w" ]] && continue
    skip_prefix "$w" && continue
    ok_length "$w" || continue
    already_in_swift "$w" && continue
    chosen="$w"
    break
  done < "$FAILURES_DIR/failure-words.txt"

  if [[ -z "$chosen" ]]; then
    echo "รอบ $round: ไม่มีคำที่เหมาะสมให้เพิ่มแล้ว"
    break
  fi

  cp "$SWIFT_FILE" "$SWIFT_FILE.bak"
  cp "$TS_FILE" "$TS_FILE.bak"
  add_word_swift "$chosen"
  add_word_ts "$chosen"
  new_passed=$(run_test)
  if (( new_passed < prev_passed )); then
    echo "รอบ $round: revert '$chosen' (passed $prev_passed -> $new_passed)"
    mv "$SWIFT_FILE.bak" "$SWIFT_FILE"
    mv "$TS_FILE.bak" "$TS_FILE"
  else
    rm -f "$SWIFT_FILE.bak" "$TS_FILE.bak"
    (( added++ ))
    prev_passed=$new_passed
    echo "รอบ $round: +'$chosen' -> passed=$new_passed (สะสม +$added คำ)"
  fi
done

echo "เสร็จ: passed=$prev_passed, เพิ่มคำไป $added คำ"

/**
 * รายการคำไทยที่ถือว่าเป็นคำที่ตั้งใจพิมพ์ — ไม่แปลงเป็นอังกฤษ
 * Port จาก ThaiWordList.swift
 */

const embeddedWords: string[] = [
  "ประเทศ", "เทศ", "รัก", "ช่วย", "ประ", "เจอ", "ครับ", "ค่ะ",
  "เป็น", "อยู่", "ที่", "และ", "หรือ", "แต่", "จะ", "ได้",
  "ไว้", "ไป", "มา", "ว่า", "นี้", "นั้น", "อะไร", "ทำ",
  "มาก", "น้อย", "มิ้ง", "ดี", "ไม่", "มี", "ให้", "กับ",
  "ใน", "บน", "ขึ้น", "ลง", "ใหญ่", "เล็ก", "ใหม่", "เก่า",
  "คน", "งาน", "วัน", "คืน", "ปี", "เรา", "เขา", "เธอ",
  "ฉัน", "ผม", "คุณ", "ใคร", "ยังไง", "ยังไงก็", "อย่างไร",
  "เพราะ", "เนื่องจาก", "ก่อน", "หลัง", "ระหว่าง", "เกี่ยวกับ",
  "ตาม", "ต่อ", "โดย", "จาก", "ถึง", "จน", "ตั้งแต่", "เกือบ",
  "ค่อนข้าง", "คิด", "รู้", "เห็น", "กิน", "ดื่ม", "นอน",
  "ทำงาน", "เรียน", "สอน", "ดู", "ฟัง", "อ่าน", "เขียน", "พูด",
  "เปิด", "ปิด", "สูง", "ต่ำ", "ยาว", "สั้น", "เร็ว", "ช้า",
  "ดีกว่า", "แย่", "ถูก", "ผิด", "จริง", "เท็จ",
  "อย่างไรก็ตาม", "ก่อนอื่น", "สุดท้าย", "อย่างน้อย", "อย่างมาก",
  "แม้ว่า", "ถ้า", "หาก", "ถึงแม้", "เพราะว่า",
  "นั่น", "โน่น", "นี่", "ครับผม", "ขอบคุณ", "ขอโทษ",
  "ไม่เป็นไร", "ได้เลย", "คะ", "จ้ะ", "จ้า", "นะ",
  "นะครับ", "นะคะ", "ใช่", "ไม่ใช่", "อาจ", "ต้อง",
  "ควร", "อยาก", "ต้องการ", "ชอบ", "เกลียด", "กลัว",
  "ดีใจ", "เสียใจ", "รู้สึก", "บางที", "บางครั้ง", "มัก",
  "กำลัง", "เคย", "เพิ่ง", "ยัง", "เกือบจะ", "เพียง",
  "แค่", "มากมาย", "ดีมาก", "แย่มาก", "สวย", "ใหญ่โต",
  "เร็วมาก", "ช้ามาก", "หนัก", "เบา", "หนา", "บาง",
  "กว้าง", "แคบ", "ลึก", "ตื้น", "เต็ม", "ว่าง",
  "เปล่า", "ง่าย", "ยาก", "ร้อน", "หนาว", "สุข",
  "เศร้า", "เสร็จ", "เสรี", "เสริม", "สนุก", "น่าเบื่อ",
  "น่าสนใจ", "ปลอดภัย", "อันตราย", "สะอาด", "สกปรก",
  "สว่าง", "มืด", "เงียบ", "ดัง", "แข็ง", "นุ่ม",
  "เรียบ", "เปียก", "แห้ง", "หวาน", "ขม", "เค็ม",
  "จืด", "เผ็ด", "เย็น", "อุ่น",
];

const wordSet: Set<string> = new Set(embeddedWords);

/** ไม้ยมก (ๆ) — ถ้าต่อท้ายคำ ให้ถือว่าเป็นคำเดียวกัน (งงๆ = งง) */
const THAI_REPETITION_MARK = "\u0E46";

/** ตรวจว่าเป็นคำไทยที่รู้จัก (รองรับคำติดกันไม่มีเว้นวรรค เช่น ไม่เป็น) */
export function containsKnownThai(text: string): boolean {
  const trimmed = text.trim();
  if (!trimmed) return false;

  const tokens = trimmed.split(/\s+/).filter((t) => t.length > 0);
  if (tokens.length === 0) return false;

  return tokens.every((token) => {
    if (wordSet.has(token)) return true;
    if (token.endsWith(THAI_REPETITION_MARK)) {
      const base = token.slice(0, -THAI_REPETITION_MARK.length);
      if (base && wordSet.has(base)) return true;
    }
    // Thai word segmentation: greedy longest-match
    if (canDecomposeIntoKnownWords(token)) return true;
    return false;
  });
}

/** แยกข้อความไทยที่ไม่มีเว้นวรรคเป็นคำที่รู้จัก (dynamic programming, min word len = 2) */
function canDecomposeIntoKnownWords(text: string): boolean {
  const chars = [...text];
  const n = chars.length;
  const minWordLen = 2;
  if (n < minWordLen * 2) return false; // ต้องแยกเป็น 2+ คำ แต่ละคำ >= 2 ตัว

  const maxWordLen = Math.min(n, 20);

  const dp = new Array<boolean>(n + 1).fill(false);
  dp[0] = true;

  for (let i = minWordLen; i <= n; i++) {
    for (let j = i - minWordLen; j >= 0; j--) {
      if (!dp[j]) continue;
      if (i - j > maxWordLen) break;
      if (wordSet.has(chars.slice(j, i).join(""))) {
        dp[i] = true;
        break;
      }
    }
  }

  if (!dp[n]) return false;

  // ต้องมี split point ระหว่างทาง (ไม่ใช่ match ทั้งก้อน)
  for (let mid = minWordLen; mid <= n - minWordLen; mid++) {
    if (dp[mid]) {
      if (decomposeAll(chars.slice(mid), minWordLen, maxWordLen)) {
        return true;
      }
    }
  }
  return false;
}

function decomposeAll(chars: string[], minLen: number, maxLen: number): boolean {
  const n = chars.length;
  if (n < minLen) return false;
  const dp = new Array<boolean>(n + 1).fill(false);
  dp[0] = true;
  for (let i = minLen; i <= n; i++) {
    for (let j = i - minLen; j >= 0; j--) {
      if (!dp[j]) continue;
      if (i - j > maxLen) break;
      if (wordSet.has(chars.slice(j, i).join(""))) {
        dp[i] = true;
        break;
      }
    }
  }
  return dp[n];
}

/** ตรวจว่ามีคำไทยที่ขึ้นต้นด้วย prefix นี้ */
export function hasWordWithPrefix(prefix: string): boolean {
  const p = prefix.trim();
  if ([...p].length < 2) return false;
  for (const word of wordSet) {
    if (word.startsWith(p)) return true;
  }
  return false;
}

/** ตรวจว่าเป็น Thai character (U+0E01–U+0E5B) */
export function isThaiCodePoint(code: number): boolean {
  return code >= 0x0e01 && code <= 0x0e5b;
}

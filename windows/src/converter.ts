/**
 * KeyboardLayoutConverter — แปลงข้อความระหว่างภาษาไทย (Kedmanee) กับอังกฤษ (QWERTY) ตามตำแหน่งปุ่ม
 * Port จาก Swift version ใน PimPid macOS
 */

export enum ConversionDirection {
  ThaiToEnglish = "thaiToEnglish",
  EnglishToThai = "englishToThai",
  None = "none",
}

// Unshifted keys: English key → Thai character
const englishToThaiUnshifted: Record<string, string> = {
  // Number row
  "`": "ๅ", "1": "ๆ", "2": "/", "3": "-", "4": "ภ", "5": "ถ",
  "6": "ุ", "7": "ึ", "8": "ค", "9": "ต", "0": "จ", "-": "ข", "=": "ช",
  // Top row (QWERTY)
  q: "ๆ", w: "ไ", e: "ำ", r: "พ", t: "ะ", y: "ั",
  u: "ี", i: "ร", o: "น", p: "ย", "[": "บ", "]": "ล", "\\": "ฃ",
  // Home row (ASDF)
  a: "ฟ", s: "ห", d: "ก", f: "ด", g: "เ", h: "้",
  j: "่", k: "า", l: "ส", ";": "ว", "'": "ง",
  // Bottom row (ZXCV)
  z: "ผ", x: "ป", c: "แ", v: "อ", b: "ิ", n: "ื",
  m: "ท", ",": "ม", ".": "ใ", "/": "ฝ",
  // Space
  " ": " ",
};

// Shifted keys: English key → Thai character
const englishToThaiShifted: Record<string, string> = {
  // Number row (shifted)
  "~": "%", "!": "+", "@": "๑", "#": "๒", $: "๓", "%": "๔",
  "^": "ู", "&": "฿", "*": "๕", "(": "๖", ")": "๗", _: "๘", "+": "๙",
  // Top row (shifted)
  Q: "๐", W: '"', E: "ฎ", R: "ฑ", T: "ธ", Y: "ํ",
  U: "๊", I: "ณ", O: "ฯ", P: "ญ", "{": "ฐ", "}": ",", "|": "ฅ",
  // Home row (shifted)
  A: "ฤ", S: "ฆ", D: "ฏ", F: "โ", G: "ฌ", H: "็",
  J: "๋", K: "ษ", L: "ศ", ":": "ซ", '"': ".",
  // Bottom row (shifted)
  Z: "(", X: ")", C: "ฉ", V: "ฮ", B: "ฺ", N: "์",
  M: "?", "<": "ฒ", ">": "ฬ", "?": "ฦ",
};

// Combined English → Thai
const englishToThai: Record<string, string> = {
  ...englishToThaiUnshifted,
  ...englishToThaiShifted,
};

// Thai → English (inverted)
const thaiToEnglish: Record<string, string> = {};
for (const [eng, thai] of Object.entries(englishToThai)) {
  thaiToEnglish[thai] = eng;
}

/** ตรวจว่าเป็น Unicode Thai (U+0E01–U+0E5B) */
function isThaiChar(code: number): boolean {
  return code >= 0x0e01 && code <= 0x0e5b;
}

/** ตรวจว่าเป็น ASCII */
function isAsciiChar(code: number): boolean {
  return code >= 0 && code <= 127;
}

/** ตรวจภาษาหลักของข้อความ */
export function dominantLanguage(text: string): ConversionDirection {
  const trimmed = text.trim();
  if (!trimmed) return ConversionDirection.None;

  let thaiCount = 0;
  let engCount = 0;

  for (const char of trimmed) {
    const code = char.codePointAt(0) ?? 0;
    if (isThaiChar(code)) {
      thaiCount++;
    } else if (isAsciiChar(code) && char !== " ") {
      engCount++;
    }
  }

  if (thaiCount > engCount) return ConversionDirection.ThaiToEnglish;
  if (engCount > thaiCount) return ConversionDirection.EnglishToThai;
  return ConversionDirection.None;
}

/** แปลงไทย → อังกฤษ ตามตำแหน่งปุ่ม */
export function convertThaiToEnglish(text: string): string {
  let result = "";
  for (const char of text) {
    result += thaiToEnglish[char] ?? char;
  }
  return result;
}

/** แปลงอังกฤษ → ไทย ตามตำแหน่งปุ่ม */
export function convertEnglishToThai(text: string): string {
  let result = "";
  for (const char of text) {
    result += englishToThai[char] ?? char;
  }
  return result;
}

/** แปลงอัตโนมัติตามภาษาที่ตรวจพบ */
export function convertAuto(text: string): string {
  const direction = dominantLanguage(text);
  switch (direction) {
    case ConversionDirection.ThaiToEnglish:
      return convertThaiToEnglish(text);
    case ConversionDirection.EnglishToThai:
      return convertEnglishToThai(text);
    default:
      return text;
  }
}

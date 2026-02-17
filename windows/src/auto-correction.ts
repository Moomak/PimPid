/**
 * AutoCorrectionEngine — แก้ไขอัตโนมัติเมื่อพิมพ์ผิดภาษา (Thai ↔ English)
 * ใช้ uiohook-napi สำหรับ global keyboard hook บน Windows
 *
 * Flow:
 * 1. ฟัง keydown events ทั่วระบบ
 * 2. สะสมตัวอักษรใน word buffer
 * 3. เมื่อหยุดพิมพ์ (debounce) หรือพบ word boundary → ตรวจคำ
 * 4. ถ้าพิมพ์ผิดภาษา → ลบคำเดิม + paste คำที่แปลงแล้ว
 */

import { clipboard, Notification } from "electron";
import { exec } from "child_process";
import {
  convertAuto,
  convertThaiToEnglish,
  convertEnglishToThai,
  dominantLanguage,
  ConversionDirection,
} from "./converter";
import { containsKnownThai, hasWordWithPrefix } from "./thai-words";

// uiohook-napi keycodes (libuiohook cross-platform codes)
// These are scan-code based, same across OS
const VC_ESCAPE = 0x0001;
const VC_BACKSPACE = 0x000e;
const VC_TAB = 0x000f;
const VC_ENTER = 0x001c;
const VC_SPACE = 0x0039;

// Arrow keys
const VC_LEFT = 0xe04b;
const VC_RIGHT = 0xe04d;
const VC_UP = 0xe048;
const VC_DOWN = 0xe050;
const VC_HOME = 0xe047;
const VC_END = 0xe04f;
const VC_PAGE_UP = 0xe049;
const VC_PAGE_DOWN = 0xe051;

// Navigation keys that clear the buffer
const NAVIGATION_KEYS = new Set([
  VC_LEFT,
  VC_RIGHT,
  VC_UP,
  VC_DOWN,
  VC_ESCAPE,
  VC_ENTER,
  VC_TAB,
  VC_HOME,
  VC_END,
  VC_PAGE_UP,
  VC_PAGE_DOWN,
]);

// uiohook keycode → QWERTY character mapping [unshifted, shifted]
const KEYCODE_TO_CHAR: Record<number, [string, string]> = {
  // Number row
  0x0029: ["`", "~"],
  0x0002: ["1", "!"],
  0x0003: ["2", "@"],
  0x0004: ["3", "#"],
  0x0005: ["4", "$"],
  0x0006: ["5", "%"],
  0x0007: ["6", "^"],
  0x0008: ["7", "&"],
  0x0009: ["8", "*"],
  0x000a: ["9", "("],
  0x000b: ["0", ")"],
  0x000c: ["-", "_"],
  0x000d: ["=", "+"],
  // Top row (QWERTY)
  0x0010: ["q", "Q"],
  0x0011: ["w", "W"],
  0x0012: ["e", "E"],
  0x0013: ["r", "R"],
  0x0014: ["t", "T"],
  0x0015: ["y", "Y"],
  0x0016: ["u", "U"],
  0x0017: ["i", "I"],
  0x0018: ["o", "O"],
  0x0019: ["p", "P"],
  0x001a: ["[", "{"],
  0x001b: ["]", "}"],
  0x002b: ["\\", "|"],
  // Home row (ASDF)
  0x001e: ["a", "A"],
  0x001f: ["s", "S"],
  0x0020: ["d", "D"],
  0x0021: ["f", "F"],
  0x0022: ["g", "G"],
  0x0023: ["h", "H"],
  0x0024: ["j", "J"],
  0x0025: ["k", "K"],
  0x0026: ["l", "L"],
  0x0027: [";", ":"],
  0x0028: ["'", '"'],
  // Bottom row (ZXCV)
  0x002c: ["z", "Z"],
  0x002d: ["x", "X"],
  0x002e: ["c", "C"],
  0x002f: ["v", "V"],
  0x0030: ["b", "B"],
  0x0031: ["n", "N"],
  0x0032: ["m", "M"],
  0x0033: [",", "<"],
  0x0034: [".", ">"],
  0x0035: ["/", "?"],
  // Space
  [VC_SPACE]: [" ", " "],
};

// Thai Kedmanee mapping (same physical key → Thai character)
// We use the converter's mapping, so we track QWERTY chars and know
// what the Thai equivalent would be

interface AutoCorrectionConfig {
  debounceMs: number;
  minBufferLength: number;
  enabled: boolean;
  onCorrection?: (original: string, converted: string) => void;
}

let config: AutoCorrectionConfig = {
  debounceMs: 300,
  minBufferLength: 3,
  enabled: false,
};

let wordBuffer = "";
let debounceTimer: ReturnType<typeof setTimeout> | null = null;
let isProcessing = false;
let uiohookInstance: any = null;

/**
 * เริ่ม auto-correction engine
 * ใช้ uiohook-napi ฟัง global keyboard events
 */
export function startAutoCorrection(
  overrideConfig?: Partial<AutoCorrectionConfig>
): void {
  if (config.enabled) return;

  if (overrideConfig) {
    config = { ...config, ...overrideConfig };
  }
  config.enabled = true;

  try {
    // Dynamic import to handle case where uiohook-napi is not installed
    const { uIOhook, UiohookKey } = require("uiohook-napi");
    uiohookInstance = uIOhook;

    uIOhook.on("keydown", (event: any) => {
      handleKeyDown(event);
    });

    uIOhook.start();
    console.log("Auto-correction engine started");
  } catch (err: any) {
    console.error(
      "Failed to start auto-correction (uiohook-napi not available):",
      err.message
    );
    console.log(
      "Auto-correction requires uiohook-napi. Install with: npm install uiohook-napi"
    );
    config.enabled = false;
  }
}

/** หยุด auto-correction engine */
export function stopAutoCorrection(): void {
  if (!config.enabled) return;
  config.enabled = false;

  if (uiohookInstance) {
    try {
      uiohookInstance.stop();
    } catch {
      // ignore
    }
    uiohookInstance = null;
  }

  clearBuffer();
  console.log("Auto-correction engine stopped");
}

export function isAutoCorrectRunning(): boolean {
  return config.enabled;
}

function handleKeyDown(event: any): void {
  if (isProcessing) return;

  const keycode: number = event.keycode;
  const shiftKey: boolean = event.shiftKey ?? false;
  const ctrlKey: boolean = event.ctrlKey ?? false;
  const altKey: boolean = event.altKey ?? false;
  const metaKey: boolean = event.metaKey ?? false;

  // Modifier keys held (Ctrl, Alt, Meta) → clear buffer
  if (ctrlKey || altKey || metaKey) {
    clearBuffer();
    return;
  }

  // Navigation keys → clear buffer
  if (NAVIGATION_KEYS.has(keycode)) {
    clearBuffer();
    return;
  }

  // Backspace → shrink buffer
  if (keycode === VC_BACKSPACE) {
    if (wordBuffer.length > 0) {
      wordBuffer = wordBuffer.slice(0, -1);
    }
    cancelDebounce();
    return;
  }

  // Space → word boundary, trigger check immediately
  if (keycode === VC_SPACE) {
    if (wordBuffer.length >= config.minBufferLength) {
      triggerCorrection();
    } else {
      clearBuffer();
    }
    return;
  }

  // Map keycode to QWERTY character
  const mapping = KEYCODE_TO_CHAR[keycode];
  if (!mapping) return;

  const char = shiftKey ? mapping[1] : mapping[0];
  wordBuffer += char;

  // Limit buffer size
  if (wordBuffer.length > 64) {
    wordBuffer = wordBuffer.slice(-64);
  }

  // Schedule debounce
  scheduleDebounce();
}

function clearBuffer(): void {
  wordBuffer = "";
  cancelDebounce();
}

function cancelDebounce(): void {
  if (debounceTimer) {
    clearTimeout(debounceTimer);
    debounceTimer = null;
  }
}

function scheduleDebounce(): void {
  cancelDebounce();

  if (wordBuffer.length < config.minBufferLength) return;

  debounceTimer = setTimeout(() => {
    triggerCorrection();
  }, config.debounceMs);
}

function triggerCorrection(): void {
  cancelDebounce();

  const word = wordBuffer.trim();
  if (!word || word.length < config.minBufferLength) {
    clearBuffer();
    return;
  }

  // The word buffer contains QWERTY characters (physical key positions).
  // Since the user might be typing with Thai layout active, the QWERTY chars
  // represent the physical keys pressed. We need to check both directions:
  //
  // Case 1: User has Thai layout active but meant to type English
  //   → The OS produced Thai chars, but we captured QWERTY physical keys
  //   → The QWERTY text IS what they meant to type
  //   → We need to check: does the Thai equivalent of these keys look like
  //     intentional Thai? If NOT, the user probably meant to type these QWERTY chars
  //
  // Case 2: User has English layout active but meant to type Thai
  //   → The OS produced English chars
  //   → We captured the same QWERTY chars
  //   → Convert QWERTY → Thai and check if it makes sense as Thai
  //
  // Since we capture physical key positions (QWERTY), we actually have the
  // English text. We convert to Thai using our mapping and check both ways.

  const asEnglish = word;
  const asThai = convertEnglishToThai(word);

  const replacement = checkReplacement(asEnglish, asThai);
  if (!replacement) {
    clearBuffer();
    return;
  }

  // Perform replacement
  isProcessing = true;
  const deleteCount = [...word].length;
  wordBuffer = "";

  performReplacement(deleteCount, replacement.converted)
    .then(() => {
      if (config.onCorrection) {
        config.onCorrection(replacement.original, replacement.converted);
      }
      showCorrectionNotification(replacement.original, replacement.converted);
    })
    .catch((err) => {
      console.error("Auto-correction replacement failed:", err);
    })
    .finally(() => {
      isProcessing = false;
    });
}

interface ReplacementResult {
  original: string;
  converted: string;
  direction: ConversionDirection;
}

function checkReplacement(
  asEnglish: string,
  asThai: string
): ReplacementResult | null {
  // Check if the Thai interpretation is a known Thai word
  // If it is, the user probably meant to type Thai → don't correct
  if (containsKnownThai(asThai)) {
    return null;
  }

  // Check if Thai text is a prefix of a known word (user still typing)
  if (hasWordWithPrefix(asThai)) {
    return null;
  }

  // Check direction: is the QWERTY text valid English?
  // If it looks like English characters were typed but they map to Thai → correct to Thai
  // If Thai characters were typed but they map to English → correct to English
  const direction = dominantLanguage(asThai);

  if (direction === ConversionDirection.ThaiToEnglish) {
    // The Thai interpretation looks like Thai → convert to English
    // But we already have the English (QWERTY). This means the user
    // typed with English layout and the keys happen to map to Thai-looking text.
    // This case is less common for auto-correction.
    return null;
  }

  if (direction === ConversionDirection.EnglishToThai) {
    // The QWERTY text looks English, meaning user typed with English layout
    // but the Thai conversion looks valid → user meant to type Thai
    if (containsKnownThai(asThai)) {
      return {
        original: asEnglish,
        converted: asThai,
        direction: ConversionDirection.EnglishToThai,
      };
    }
  }

  // Also check: the user typed QWERTY that looks like nonsense English
  // but converting to Thai gives a known word
  const thaiConverted = convertEnglishToThai(asEnglish);
  if (containsKnownThai(thaiConverted) && !looksLikeValidEnglish(asEnglish)) {
    return {
      original: asEnglish,
      converted: thaiConverted,
      direction: ConversionDirection.EnglishToThai,
    };
  }

  // Check reverse: user typed with Thai layout but meant English
  // In this case, we captured QWERTY keys, but the OS produced Thai.
  // The Thai text doesn't make sense → convert back to English QWERTY
  const englishFromThai = convertThaiToEnglish(asThai);
  if (
    looksLikeValidEnglish(englishFromThai) &&
    !containsKnownThai(asThai) &&
    !hasWordWithPrefix(asThai)
  ) {
    return {
      original: asThai,
      converted: englishFromThai,
      direction: ConversionDirection.ThaiToEnglish,
    };
  }

  return null;
}

/** ตรวจว่าข้อความดูเหมือนคำอังกฤษที่ถูกต้อง (heuristic) */
function looksLikeValidEnglish(text: string): boolean {
  const trimmed = text.trim().toLowerCase();
  if (!trimmed) return false;
  // Must be all letters
  if (!/^[a-z]+$/.test(trimmed)) return false;
  // Must have vowels (a, e, i, o, u)
  if (!/[aeiou]/.test(trimmed)) return false;
  // Must be at least 2 chars
  if (trimmed.length < 2) return false;
  // Check against a small common English words list
  return COMMON_ENGLISH.has(trimmed) || trimmed.length >= 4;
}

// Common English words for basic validation
const COMMON_ENGLISH = new Set([
  "the",
  "be",
  "to",
  "of",
  "and",
  "a",
  "in",
  "that",
  "have",
  "i",
  "it",
  "for",
  "not",
  "on",
  "with",
  "he",
  "as",
  "you",
  "do",
  "at",
  "this",
  "but",
  "his",
  "by",
  "from",
  "they",
  "we",
  "say",
  "her",
  "she",
  "or",
  "an",
  "will",
  "my",
  "one",
  "all",
  "would",
  "there",
  "their",
  "what",
  "so",
  "up",
  "out",
  "if",
  "about",
  "who",
  "get",
  "which",
  "go",
  "me",
  "when",
  "make",
  "can",
  "like",
  "time",
  "no",
  "just",
  "him",
  "know",
  "take",
  "come",
  "could",
  "than",
  "look",
  "use",
  "find",
  "here",
  "thing",
  "many",
  "well",
  "also",
  "now",
  "new",
  "way",
  "may",
  "then",
  "how",
  "its",
  "see",
  "did",
  "been",
  "has",
  "are",
  "was",
  "were",
  "had",
  "is",
  "am",
  "let",
  "put",
  "set",
  "run",
  "got",
  "yes",
  "code",
  "file",
  "test",
  "help",
  "home",
  "work",
  "good",
  "back",
  "right",
  "left",
  "open",
  "close",
  "save",
  "edit",
  "view",
  "next",
  "last",
  "name",
  "type",
  "data",
  "list",
  "text",
  "more",
  "some",
  "very",
  "much",
  "still",
  "over",
  "after",
  "only",
  "even",
  "such",
  "most",
  "into",
  "other",
  "your",
  "them",
  "these",
  "those",
]);

/**
 * ลบคำเดิมแล้ว paste คำที่แปลงแล้ว
 * ใช้ PowerShell SendKeys บน Windows
 */
async function performReplacement(
  deleteCount: number,
  newText: string
): Promise<void> {
  // Save current clipboard
  const savedClipboard = clipboard.readText();

  // Write converted text to clipboard
  clipboard.writeText(newText);

  // Build SendKeys command: backspaces + Ctrl+V
  const bsCount = Math.min(deleteCount, 50);
  const sendKeysArg = `{BS ${bsCount}}^v`;

  await runPowerShell(
    `Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait('${sendKeysArg}')`
  );

  // Restore clipboard after delay
  setTimeout(() => {
    clipboard.writeText(savedClipboard);
  }, 500);
}

function runPowerShell(script: string): Promise<void> {
  return new Promise((resolve, reject) => {
    exec(
      `powershell -NoProfile -Command "${script}"`,
      { timeout: 5000 },
      (error) => {
        if (error) {
          reject(error);
        } else {
          resolve();
        }
      }
    );
  });
}

function showCorrectionNotification(
  original: string,
  converted: string
): void {
  if (Notification.isSupported()) {
    const notification = new Notification({
      title: "PimPid Auto-Correct",
      body: `${original} → ${converted}`,
      silent: true,
    });
    notification.show();
  }
}

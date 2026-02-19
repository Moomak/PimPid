/**
 * AutoCorrectionEngine — แก้ไขอัตโนมัติเมื่อพิมพ์ผิดภาษา (Thai ↔ English)
 * ใช้ uiohook-napi สำหรับ global keyboard hook บน Windows
 *
 * Flow:
 * 1. ฟัง keydown events ทั่วระบบ
 * 2. สะสมตัวอักษรใน word buffer
 * 3. เมื่อหยุดพิมพ์ (debounce) หรือพบ word boundary → ตรวจคำ
 * 4. ถ้าพิมพ์ผิดภาษา → ลบคำเดิม + paste คำที่แปลงแล้ว
 *
 * Memory fixes:
 * - Notification ถูก track และ close ก่อนสร้างอันใหม่ (ป้องกัน leak)
 * - Clipboard restore timer ถูก track และ clear ก่อนตั้งใหม่ (ป้องกัน timer pile-up)
 * - isProcessing มี safety timeout 4วิ (ป้องกัน permanent lock)
 * - Rate limiting: ห้ามแก้ไขถี่กว่า 500ms (ป้องกัน powershell pile-up)
 * - PowerShell ใช้ -WindowStyle Hidden เพื่อไม่สร้าง visible window ทุกครั้ง
 */

import { clipboard, Notification } from "electron";
import { exec } from "child_process";
import {
  convertEnglishToThai,
  convertThaiToEnglish,
  ConversionDirection,
} from "./converter";
import { containsKnownThai, hasWordWithPrefix } from "./thai-words";

// ─── uiohook-napi keycodes ────────────────────────────────────────────────────
const VC_ESCAPE    = 0x0001;
const VC_BACKSPACE = 0x000e;
const VC_TAB       = 0x000f;
const VC_ENTER     = 0x001c;
const VC_SPACE     = 0x0039;
const VC_LEFT      = 0xe04b;
const VC_RIGHT     = 0xe04d;
const VC_UP        = 0xe048;
const VC_DOWN      = 0xe050;
const VC_HOME      = 0xe047;
const VC_END       = 0xe04f;
const VC_PAGE_UP   = 0xe049;
const VC_PAGE_DOWN = 0xe051;

const NAVIGATION_KEYS = new Set([
  VC_LEFT, VC_RIGHT, VC_UP, VC_DOWN, VC_ESCAPE, VC_ENTER,
  VC_TAB, VC_HOME, VC_END, VC_PAGE_UP, VC_PAGE_DOWN,
]);

const MAX_BUFFER_LENGTH = 50;
const MAX_DELETE_COUNT = 50;
const THAI_LAYOUT_IDS = new Set(["041E"]);
const KEYBOARD_LAYOUT_CACHE_MS = 800;

// uiohook keycode → QWERTY character mapping [unshifted, shifted]
const KEYCODE_TO_CHAR: Record<number, [string, string]> = {
  0x0029: ["`", "~"], 0x0002: ["1", "!"], 0x0003: ["2", "@"], 0x0004: ["3", "#"],
  0x0005: ["4", "$"], 0x0006: ["5", "%"], 0x0007: ["6", "^"], 0x0008: ["7", "&"],
  0x0009: ["8", "*"], 0x000a: ["9", "("], 0x000b: ["0", ")"], 0x000c: ["-", "_"],
  0x000d: ["=", "+"],
  0x0010: ["q", "Q"], 0x0011: ["w", "W"], 0x0012: ["e", "E"], 0x0013: ["r", "R"],
  0x0014: ["t", "T"], 0x0015: ["y", "Y"], 0x0016: ["u", "U"], 0x0017: ["i", "I"],
  0x0018: ["o", "O"], 0x0019: ["p", "P"], 0x001a: ["[", "{"], 0x001b: ["]", "}"],
  0x002b: ["\\", "|"],
  0x001e: ["a", "A"], 0x001f: ["s", "S"], 0x0020: ["d", "D"], 0x0021: ["f", "F"],
  0x0022: ["g", "G"], 0x0023: ["h", "H"], 0x0024: ["j", "J"], 0x0025: ["k", "K"],
  0x0026: ["l", "L"], 0x0027: [";", ":"], 0x0028: ["'", '"'],
  0x002c: ["z", "Z"], 0x002d: ["x", "X"], 0x002e: ["c", "C"], 0x002f: ["v", "V"],
  0x0030: ["b", "B"], 0x0031: ["n", "N"], 0x0032: ["m", "M"],
  0x0033: [",", "<"], 0x0034: [".", ">"], 0x0035: ["/", "?"],
  [VC_SPACE]: [" ", " "],
};

export interface AutoCorrectionConfig {
  debounceMs: number;
  minBufferLength: number;
  enabled: boolean;
  excludeWords?: string[];
  onCorrection?: (original: string, converted: string) => void;
}

interface KeyDownEvent {
  keycode: number;
  shiftKey?: boolean;
  ctrlKey?: boolean;
  altKey?: boolean;
  metaKey?: boolean;
}

interface UiohookLike {
  on: (event: "keydown", listener: (event: KeyDownEvent) => void) => void;
  off?: (event: "keydown", listener: (event: KeyDownEvent) => void) => void;
  removeListener?: (event: "keydown", listener: (event: KeyDownEvent) => void) => void;
  start: () => void;
  stop: () => void;
}

let config: AutoCorrectionConfig = {
  debounceMs: 300,
  minBufferLength: 3,
  enabled: false,
  excludeWords: [],
};

let wordBuffer = "";
let debounceTimer: ReturnType<typeof setTimeout> | null = null;
let isProcessing = false;
let isProcessingTimer: ReturnType<typeof setTimeout> | null = null; // safety timeout
let lastCorrectionTime = 0;                                          // rate limiting
let uiohookInstance: UiohookLike | null = null;

// ─── Notification tracking ────────────────────────────────────────────────────
let lastNotification: Notification | null = null;
let lastNotificationTimer: ReturnType<typeof setTimeout> | null = null;

// ─── Clipboard restore timer tracking ────────────────────────────────────────
let clipboardRestoreTimer: ReturnType<typeof setTimeout> | null = null;
let keyboardLayoutCache: { isThai: boolean; timestamp: number } | null = null;

// ─── Public API ───────────────────────────────────────────────────────────────

export function startAutoCorrection(
  overrideConfig?: Partial<AutoCorrectionConfig>
): void {
  if (config.enabled) return;

  if (overrideConfig) {
    config = { ...config, ...overrideConfig };
  }
  config.enabled = true;

  try {
    const { uIOhook } = require("uiohook-napi") as { uIOhook: UiohookLike };
    uiohookInstance = uIOhook;
    detachKeydownListener(uIOhook);
    uIOhook.on("keydown", handleKeyDown);
    uIOhook.start();
    console.log("[PimPid] Auto-correction engine started");
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("[PimPid] Failed to start auto-correction (uiohook-napi not available):", msg);
    config.enabled = false;
  }
}

export function stopAutoCorrection(): void {
  if (!config.enabled) return;
  config.enabled = false;

  if (uiohookInstance) {
    try {
      detachKeydownListener(uiohookInstance);
      uiohookInstance.stop();
    } catch { /* ignore */ }
    uiohookInstance = null;
  }

  clearBuffer();
  clearProcessingLock();

  // Cancel any pending clipboard restore
  if (clipboardRestoreTimer) {
    clearTimeout(clipboardRestoreTimer);
    clipboardRestoreTimer = null;
  }
  keyboardLayoutCache = null;

  if (lastNotificationTimer) {
    clearTimeout(lastNotificationTimer);
    lastNotificationTimer = null;
  }
  if (lastNotification) {
    try { lastNotification.close(); } catch { /* ignore */ }
    lastNotification = null;
  }

  console.log("[PimPid] Auto-correction engine stopped");
}

export function isAutoCorrectRunning(): boolean {
  return config.enabled;
}

/** Update config without restarting the engine */
export function updateAutoCorrectConfig(
  updates: Partial<Pick<AutoCorrectionConfig, "debounceMs" | "minBufferLength">>
): void {
  config = { ...config, ...updates };
}

/** Update exclude words list live */
export function setExcludeWords(words: string[]): void {
  config.excludeWords = words;
}

// ─── Key handler ──────────────────────────────────────────────────────────────

function handleKeyDown(event: {
  keycode: number;
  shiftKey?: boolean;
  ctrlKey?: boolean;
  altKey?: boolean;
  metaKey?: boolean;
}): void {
  if (isProcessing) return;

  const { keycode, shiftKey = false, ctrlKey = false, altKey = false, metaKey = false } = event;

  // Modifier combos → clear buffer (user doing shortcuts, not typing)
  if (ctrlKey || altKey || metaKey) {
    clearBuffer();
    return;
  }

  if (NAVIGATION_KEYS.has(keycode)) {
    clearBuffer();
    return;
  }

  if (keycode === VC_BACKSPACE) {
    if (wordBuffer.length > 0) wordBuffer = wordBuffer.slice(0, -1);
    cancelDebounce();
    return;
  }

  if (keycode === VC_SPACE) {
    if (wordBuffer.length >= config.minBufferLength) {
      triggerCorrection();
    } else {
      clearBuffer();
    }
    return;
  }

  const mapping = KEYCODE_TO_CHAR[keycode];
  if (!mapping) return;

  wordBuffer += shiftKey ? mapping[1] : mapping[0];

  // Keep buffer bounded so backspace replacement always matches captured length.
  if (wordBuffer.length > MAX_BUFFER_LENGTH) wordBuffer = wordBuffer.slice(-MAX_BUFFER_LENGTH);

  scheduleDebounce();
}

// ─── Buffer management ────────────────────────────────────────────────────────

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
  debounceTimer = setTimeout(triggerCorrection, config.debounceMs);
}

// ─── Rate limit + processing lock ─────────────────────────────────────────────

function setProcessingLock(): void {
  isProcessing = true;
  // Safety timeout: always release lock after 4s regardless
  if (isProcessingTimer) clearTimeout(isProcessingTimer);
  isProcessingTimer = setTimeout(() => {
    if (isProcessing) {
      console.warn("[PimPid] isProcessing safety timeout triggered — resetting");
      isProcessing = false;
    }
    isProcessingTimer = null;
  }, 4000);
}

function clearProcessingLock(): void {
  isProcessing = false;
  if (isProcessingTimer) {
    clearTimeout(isProcessingTimer);
    isProcessingTimer = null;
  }
}

// ─── Correction logic ─────────────────────────────────────────────────────────

function triggerCorrection(): void {
  void triggerCorrectionAsync();
}

async function triggerCorrectionAsync(): Promise<void> {
  cancelDebounce();

  const word = wordBuffer.trim();
  if (!word || word.length < config.minBufferLength) {
    clearBuffer();
    return;
  }

  // Rate limit: skip if corrected too recently (prevents powershell pile-up)
  const now = Date.now();
  if (now - lastCorrectionTime < 500) {
    clearBuffer();
    return;
  }

  // Check exclude words
  const excludeWords = config.excludeWords ?? [];
  const asThai = convertEnglishToThai(word);
  if (excludeWords.some((w) => w.toLowerCase() === word.toLowerCase()
    || w.toLowerCase() === asThai.toLowerCase())) {
    clearBuffer();
    return;
  }

  const replacement = checkReplacement(word, asThai);
  if (!replacement) {
    clearBuffer();
    return;
  }

  // Release captured word immediately so newly typed characters are tracked independently.
  wordBuffer = "";

  if (
    replacement.direction === ConversionDirection.ThaiToEnglish &&
    replacement.converted === word &&
    replacement.original !== word
  ) {
    const isThaiLayout = await isThaiKeyboardLayoutActive();
    // User already continued typing; skip stale correction to avoid deleting newer text.
    if (wordBuffer.length > 0) return;
    if (!isThaiLayout) {
      return;
    }
  }

  lastCorrectionTime = now;
  setProcessingLock();
  const deleteCount = Math.min([...word].length, MAX_DELETE_COUNT);

  performReplacement(deleteCount, replacement.converted)
    .then(() => {
      config.onCorrection?.(replacement.original, replacement.converted);
      showCorrectionNotification(replacement.original, replacement.converted);
    })
    .catch((err: unknown) => {
      const msg = err instanceof Error ? err.message : String(err);
      console.error("[PimPid] Auto-correction replacement failed:", msg);
    })
    .finally(() => {
      clearProcessingLock();
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
  // If Thai interpretation is a known Thai word → user meant to type Thai, skip
  if (containsKnownThai(asThai)) return null;
  // Skip when user typed Thai and it's a prefix of a word (กำลังพิมพ์อยู่)
  if (hasWordWithPrefix(asThai) && typedTextContainsThai(asEnglish)) return null;

  // Check: QWERTY maps to invalid Thai, but Thai→English gives valid English (หรือผลเป็น prefix ของคำ เช่น megd→ทำเก)
  const thaiConverted = asThai;
  const thaiConvertedValid =
    containsKnownThai(thaiConverted) || hasWordWithPrefix(thaiConverted);
  if (thaiConvertedValid && !looksLikeValidEnglish(asEnglish)) {
    return {
      original: asEnglish,
      converted: thaiConverted,
      direction: ConversionDirection.EnglishToThai,
    };
  }

  // Check: typed with Thai layout but meant English
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

/** ตรวจว่าข้อความที่พิมพ์มีตัวอักษรไทย (ใช้ตัดว่าเป็นคำที่กำลังพิมพ์ไทยอยู่หรือพิมพ์อังกฤษผิด layout) */
function typedTextContainsThai(text: string): boolean {
  return /[\u0E01-\u0E5B]/.test(text);
}

function looksLikeValidEnglish(text: string): boolean {
  const trimmed = text.trim().toLowerCase();
  if (!trimmed || !/^[a-z]+$/.test(trimmed)) return false;
  if (!/[aeiou]/.test(trimmed)) return false;
  if (trimmed.length < 2) return false;
  return COMMON_ENGLISH.has(trimmed) || trimmed.length >= 4;
}

const COMMON_ENGLISH = new Set([
  "the","be","to","of","and","a","in","that","have","i","it","for","not","on",
  "with","he","as","you","do","at","this","but","his","by","from","they","we",
  "say","her","she","or","an","will","my","one","all","would","there","their",
  "what","so","up","out","if","about","who","get","which","go","me","when",
  "make","can","like","time","no","just","him","know","take","come","could",
  "than","look","use","find","here","thing","many","well","also","now","new",
  "way","may","then","how","its","see","did","been","has","are","was","were",
  "had","is","am","let","put","set","run","got","yes","code","file","test",
  "help","home","work","good","back","right","left","open","close","save",
  "edit","view","next","last","name","type","data","list","text","more","some",
  "very","much","still","over","after","only","even","such","most","into",
  "other","your","them","these","those",
]);

// ─── Replacement execution ────────────────────────────────────────────────────

async function performReplacement(
  deleteCount: number,
  newText: string
): Promise<void> {
  const savedClipboard = clipboard.readText();
  clipboard.writeText(newText);

  const bsCount = Math.min(deleteCount, MAX_DELETE_COUNT);
  const sendKeysArg = `{BS ${bsCount}}^v`;

  await runPowerShell(
    `Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait('${sendKeysArg}')`
  );

  // Restore clipboard after delay — track timer to prevent multiple pending restores
  if (clipboardRestoreTimer) clearTimeout(clipboardRestoreTimer);
  clipboardRestoreTimer = setTimeout(() => {
    clipboard.writeText(savedClipboard);
    clipboardRestoreTimer = null;
  }, 600);
}

function runPowerShell(script: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const encoded = Buffer.from(script, "utf16le").toString("base64");
    exec(
      `powershell -NoProfile -WindowStyle Hidden -EncodedCommand ${encoded}`,
      { timeout: 5000 },
      (error) => {
        if (error) reject(error);
        else resolve();
      }
    );
  });
}

// ─── Notification (with leak prevention) ─────────────────────────────────────

function showCorrectionNotification(
  original: string,
  converted: string
): void {
  if (!Notification.isSupported()) return;

  // Close previous notification before showing new one
  if (lastNotification) {
    try { lastNotification.close(); } catch { /* ignore */ }
    lastNotification = null;
  }
  if (lastNotificationTimer) {
    clearTimeout(lastNotificationTimer);
    lastNotificationTimer = null;
  }

  const n = new Notification({
    title: "PimPid Auto-Correct",
    body: `${original} → ${converted}`,
    silent: true,
  });
  n.show();
  lastNotification = n;

  // Auto-clear reference after notification expires
  lastNotificationTimer = setTimeout(() => {
    if (lastNotification === n) lastNotification = null;
    lastNotificationTimer = null;
  }, 5000);
}

async function isThaiKeyboardLayoutActive(): Promise<boolean> {
  const now = Date.now();
  if (keyboardLayoutCache && now - keyboardLayoutCache.timestamp < KEYBOARD_LAYOUT_CACHE_MS) {
    return keyboardLayoutCache.isThai;
  }

  try {
    const langId = await readForegroundKeyboardLangId();
    const isThai = THAI_LAYOUT_IDS.has(langId);
    keyboardLayoutCache = { isThai, timestamp: now };
    return isThai;
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.warn("[PimPid] Failed to read keyboard layout:", msg);
    return false;
  }
}

function readForegroundKeyboardLangId(): Promise<string> {
  const script = [
    "$sig = @'",
    "using System;",
    "using System.Runtime.InteropServices;",
    "public static class PimPidLayoutReader {",
    "  [DllImport(\"user32.dll\")] public static extern IntPtr GetForegroundWindow();",
    "  [DllImport(\"user32.dll\")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr lpdwProcessId);",
    "  [DllImport(\"user32.dll\")] public static extern IntPtr GetKeyboardLayout(uint idThread);",
    "}",
    "'@;",
    "Add-Type -TypeDefinition $sig -ErrorAction SilentlyContinue | Out-Null;",
    "$hwnd = [PimPidLayoutReader]::GetForegroundWindow();",
    "$tid = [PimPidLayoutReader]::GetWindowThreadProcessId($hwnd, [IntPtr]::Zero);",
    "$hkl = [PimPidLayoutReader]::GetKeyboardLayout($tid);",
    "$lang = $hkl.ToInt64() -band 0xFFFF;",
    "\"{0:X4}\" -f $lang",
  ].join(" ");

  return new Promise((resolve, reject) => {
    const encoded = Buffer.from(script, "utf16le").toString("base64");
    exec(
      `powershell -NoProfile -WindowStyle Hidden -EncodedCommand ${encoded}`,
      { timeout: 1500, maxBuffer: 16 * 1024 },
      (error, stdout) => {
        if (error) {
          reject(error);
          return;
        }
        const langId = String(stdout ?? "").trim().toUpperCase();
        if (!/^[0-9A-F]{4}$/.test(langId)) {
          reject(new Error(`Unexpected keyboard layout output: "${langId}"`));
          return;
        }
        resolve(langId);
      }
    );
  });
}

function detachKeydownListener(hook: UiohookLike): void {
  if (typeof hook.off === "function") {
    hook.off("keydown", handleKeyDown);
    return;
  }
  if (typeof hook.removeListener === "function") {
    hook.removeListener("keydown", handleKeyDown);
  }
}

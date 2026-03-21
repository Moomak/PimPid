/**
 * Simple persistent store — saves settings to JSON in userData directory.
 * No external dependencies, works in Electron main process.
 */

import { app } from "electron";
import * as fs from "fs";
import * as path from "path";

export interface ConversionRecord {
  from: string;
  to: string;
  timestamp: number;
  direction: string;
}

export interface ConversionStats {
  daily: Record<string, number>;
  total: number;
}

export interface StoreData {
  language: "th" | "en";
  isEnabled: boolean;
  autoCorrectEnabled: boolean;
  autoCorrectDebounceMs: number;
  autoCorrectMinChars: number;
  excludeWords: string[];
  shortcut: string;
  hasCompletedOnboarding: boolean;
  showFloatButton: boolean;
  theme: "auto" | "light" | "dark";
  fontSize: "small" | "medium" | "large" | "xl";
  conversionStats: ConversionStats;
  recentConversions: ConversionRecord[];
}

const DEFAULTS: StoreData = {
  language: "th",
  isEnabled: false,
  autoCorrectEnabled: false,
  autoCorrectDebounceMs: 300,
  autoCorrectMinChars: 3,
  excludeWords: [],
  shortcut: "CommandOrControl+Shift+L",
  hasCompletedOnboarding: false,
  showFloatButton: false,
  theme: "auto",
  fontSize: "medium",
  conversionStats: { daily: {}, total: 0 },
  recentConversions: [],
};

function getStorePath(): string {
  return path.join(app.getPath("userData"), "pimpid-settings.json");
}

function loadFromDisk(): StoreData {
  try {
    const raw = fs.readFileSync(getStorePath(), "utf-8");
    const parsed = JSON.parse(raw) as Partial<StoreData>;
    return { ...DEFAULTS, ...parsed };
  } catch {
    return { ...DEFAULTS };
  }
}

function saveToDiskImmediate(data: StoreData): void {
  try {
    const dir = path.dirname(getStorePath());
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(getStorePath(), JSON.stringify(data, null, 2), "utf-8");
  } catch (err) {
    console.error("[store] Failed to save settings:", err);
  }
}

// Debounced disk write to avoid excessive I/O when multiple store.set() calls
// happen in rapid succession (e.g. recordConversion writes stats + recentConversions).
const SAVE_DEBOUNCE_MS = 500;
let _saveTimer: ReturnType<typeof setTimeout> | null = null;
let _savePending = false;

function scheduleSave(): void {
  _savePending = true;
  if (_saveTimer) return; // already scheduled
  _saveTimer = setTimeout(() => {
    _saveTimer = null;
    if (_savePending) {
      _savePending = false;
      saveToDiskImmediate(_data);
    }
  }, SAVE_DEBOUNCE_MS);
}

/** Flush any pending debounced write immediately (call before app quit). */
export function flushStore(): void {
  if (_saveTimer) {
    clearTimeout(_saveTimer);
    _saveTimer = null;
  }
  if (_savePending) {
    _savePending = false;
    saveToDiskImmediate(_data);
  }
}

let _data: StoreData = DEFAULTS; // Will be initialized after app.ready

/** Must be called after app is ready (so userData path is available) */
export function initStore(): void {
  _data = loadFromDisk();
}

export const store = {
  get<K extends keyof StoreData>(key: K): StoreData[K] {
    return _data[key];
  },

  set<K extends keyof StoreData>(key: K, value: StoreData[K]): void {
    _data[key] = value;
    scheduleSave();
  },

  getAll(): StoreData {
    return { ..._data };
  },
};

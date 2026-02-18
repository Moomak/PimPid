/**
 * Simple persistent store — saves settings to JSON in userData directory.
 * No external dependencies, works in Electron main process.
 */

import { app } from "electron";
import * as fs from "fs";
import * as path from "path";

export interface StoreData {
  language: "th" | "en";
  isEnabled: boolean;
  autoCorrectEnabled: boolean;
  autoCorrectDebounceMs: number;
  autoCorrectMinChars: number;
  excludeWords: string[];
  shortcut: string;
}

const DEFAULTS: StoreData = {
  language: "th",
  isEnabled: true,
  autoCorrectEnabled: false,
  autoCorrectDebounceMs: 300,
  autoCorrectMinChars: 3,
  excludeWords: [],
  shortcut: "CommandOrControl+Shift+L",
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

function saveToDisk(data: StoreData): void {
  try {
    const dir = path.dirname(getStorePath());
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(getStorePath(), JSON.stringify(data, null, 2), "utf-8");
  } catch (err) {
    console.error("[store] Failed to save settings:", err);
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
    saveToDisk(_data);
  },

  getAll(): StoreData {
    return { ..._data };
  },
};

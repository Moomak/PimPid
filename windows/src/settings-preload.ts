/**
 * Preload script for Settings BrowserWindow
 * Bridges renderer ↔ main process via contextBridge (contextIsolation: true)
 */

import { contextBridge, ipcRenderer } from "electron";
import type { StoreData } from "./store";

export interface ElectronAPI {
  getSettings: () => Promise<StoreData>;
  setSetting: <K extends keyof StoreData>(key: K, value: StoreData[K]) => Promise<void>;
  onSettingsChanged: (callback: (settings: StoreData) => void) => void;
  getLang: () => Promise<string>;
  changeShortcut: (shortcut: string) => Promise<{ success: boolean; error?: string }>;
  getStats: () => Promise<{ conversionStats: { daily: Record<string, number>; total: number }; recentConversions: Array<{ from: string; to: string; timestamp: number; direction: string }> }>;
  clearStats: () => Promise<{ success: boolean }>;
  exportStats: () => Promise<{ success: boolean; error?: string }>;
}

contextBridge.exposeInMainWorld("electronAPI", {
  getSettings: (): Promise<StoreData> =>
    ipcRenderer.invoke("settings:get"),

  setSetting: <K extends keyof StoreData>(key: K, value: StoreData[K]): Promise<void> =>
    ipcRenderer.invoke("settings:set", key, value),

  onSettingsChanged: (callback: (settings: StoreData) => void): void => {
    ipcRenderer.on("settings:updated", (_event, settings: StoreData) => {
      callback(settings);
    });
  },

  getLang: (): Promise<string> =>
    ipcRenderer.invoke("settings:getLang"),

  changeShortcut: (shortcut: string): Promise<{ success: boolean; error?: string }> =>
    ipcRenderer.invoke("shortcut:change", shortcut),

  getStats: () =>
    ipcRenderer.invoke("stats:get"),

  clearStats: () =>
    ipcRenderer.invoke("stats:clear"),

  exportStats: () =>
    ipcRenderer.invoke("stats:export"),
} satisfies ElectronAPI);

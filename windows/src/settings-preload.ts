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
} satisfies ElectronAPI);

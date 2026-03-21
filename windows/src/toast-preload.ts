/**
 * Preload script for Toast BrowserWindow
 * Receives toast data from main process via IPC
 */

import { contextBridge, ipcRenderer } from "electron";

export interface ToastData {
  directionLabel: string;
  original: string;
  converted: string;
  theme: "auto" | "light" | "dark";
}

contextBridge.exposeInMainWorld("toastAPI", {
  onToastData: (callback: (data: ToastData) => void): void => {
    ipcRenderer.on("toast:data", (_event, data: ToastData) => {
      callback(data);
    });
  },
});

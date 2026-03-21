/**
 * Preload script for Float Button BrowserWindow
 * Bridges renderer <-> main process for drag, convert, close
 */

import { contextBridge, ipcRenderer } from "electron";

contextBridge.exposeInMainWorld("floatAPI", {
  convert: (): void => {
    ipcRenderer.send("float:convert");
  },

  close: (): void => {
    ipcRenderer.send("float:close");
  },

  dragMove: (dx: number, dy: number): void => {
    ipcRenderer.send("float:drag-move", dx, dy);
  },
});

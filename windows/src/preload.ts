// Preload script สำหรับ main window (ถ้ามีในอนาคต)
// Settings window ใช้ settings-preload.ts แทน

import { contextBridge } from "electron";

contextBridge.exposeInMainWorld("pimpid", {
  version: "1.6.2",
});

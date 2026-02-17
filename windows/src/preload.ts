// Preload script — currently minimal since PimPid Windows is a tray-only app
// with no renderer window. This file exists for future use if a settings UI is added.

import { contextBridge } from "electron";

contextBridge.exposeInMainWorld("pimpid", {
  version: "1.5.10",
});

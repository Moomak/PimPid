import {
  app,
  Tray,
  Menu,
  globalShortcut,
  clipboard,
  nativeImage,
  Notification,
} from "electron";
import * as path from "path";
import { convertAuto, dominantLanguage, ConversionDirection } from "./converter";
import {
  startAutoCorrection,
  stopAutoCorrection,
  isAutoCorrectRunning,
} from "./auto-correction";

let tray: Tray | null = null;
let isEnabled = true;
let autoCorrectEnabled = false;

function createTray(): void {
  const iconPath = path.join(__dirname, "..", "src", "icon.png");

  let trayIcon: Electron.NativeImage;
  try {
    trayIcon = nativeImage.createFromPath(iconPath);
    if (trayIcon.isEmpty()) {
      trayIcon = createDefaultIcon();
    }
  } catch {
    trayIcon = createDefaultIcon();
  }

  tray = new Tray(trayIcon.resize({ width: 16, height: 16 }));
  tray.setToolTip("PimPid — Thai ⇄ English Converter");
  updateTrayMenu();
}

function createDefaultIcon(): Electron.NativeImage {
  const size = 16;
  const canvas = Buffer.alloc(size * size * 4);
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const i = (y * size + x) * 4;
      const cx = x - size / 2;
      const cy = y - size / 2;
      const inCircle = cx * cx + cy * cy < (size / 2 - 1) * (size / 2 - 1);
      canvas[i] = inCircle ? 66 : 0;
      canvas[i + 1] = inCircle ? 133 : 0;
      canvas[i + 2] = inCircle ? 244 : 0;
      canvas[i + 3] = inCircle ? 255 : 0;
    }
  }
  return nativeImage.createFromBuffer(canvas, { width: size, height: size });
}

function toggleAutoCorrect(): void {
  if (autoCorrectEnabled) {
    stopAutoCorrection();
    autoCorrectEnabled = false;
  } else {
    startAutoCorrection({
      enabled: true,
      debounceMs: 300,
      minBufferLength: 3,
      onCorrection: (original, converted) => {
        console.log(`Auto-corrected: ${original} → ${converted}`);
      },
    });
    autoCorrectEnabled = isAutoCorrectRunning();
  }
  updateTrayMenu();
}

function updateTrayMenu(): void {
  if (!tray) return;

  const contextMenu = Menu.buildFromTemplate([
    {
      label: "PimPid — Thai ⇄ English",
      enabled: false,
    },
    { type: "separator" },
    {
      label: isEnabled ? "✅ เปิดใช้งาน" : "⬜ เปิดใช้งาน",
      click: () => {
        isEnabled = !isEnabled;
        if (!isEnabled && autoCorrectEnabled) {
          stopAutoCorrection();
          autoCorrectEnabled = false;
        }
        updateTrayMenu();
      },
    },
    {
      label: autoCorrectEnabled
        ? "⚡ Auto-Correct: ON"
        : "⚡ Auto-Correct: OFF",
      click: () => {
        toggleAutoCorrect();
      },
      enabled: isEnabled,
    },
    { type: "separator" },
    {
      label: "Convert Selected Text (Ctrl+Shift+L)",
      click: () => {
        convertSelectedText();
      },
      enabled: isEnabled,
    },
    { type: "separator" },
    {
      label: "Quit PimPid",
      click: () => {
        app.quit();
      },
    },
  ]);

  tray.setContextMenu(contextMenu);
}

async function convertSelectedText(): Promise<void> {
  if (!isEnabled) return;

  const savedClipboard = clipboard.readText();
  clipboard.writeText("");

  await simulateCopy();
  await sleep(200);

  const selectedText = clipboard.readText();

  if (!selectedText || selectedText.trim() === "") {
    clipboard.writeText(savedClipboard);
    return;
  }

  const converted = convertAuto(selectedText);

  if (converted === selectedText) {
    clipboard.writeText(savedClipboard);
    return;
  }

  clipboard.writeText(converted);
  await simulatePaste();

  await sleep(500);
  clipboard.writeText(savedClipboard);

  const direction = dominantLanguage(selectedText);
  const dirLabel =
    direction === ConversionDirection.ThaiToEnglish
      ? "ไทย → English"
      : "English → ไทย";
  showNotification(dirLabel, `${selectedText} → ${converted}`);
}

function simulateCopy(): Promise<void> {
  return simulateKeyCombo("c");
}

function simulatePaste(): Promise<void> {
  return simulateKeyCombo("v");
}

function simulateKeyCombo(key: string): Promise<void> {
  return new Promise((resolve) => {
    const { exec } = require("child_process");
    const psScript =
      key === "c"
        ? `Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait("^c")`
        : `Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait("^v")`;

    exec(
      `powershell -NoProfile -Command "${psScript}"`,
      (error: Error | null) => {
        if (error) {
          console.error(`Failed to simulate Ctrl+${key}:`, error.message);
        }
        resolve();
      }
    );
  });
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function showNotification(title: string, body: string): void {
  if (Notification.isSupported()) {
    const notification = new Notification({
      title,
      body,
      silent: true,
    });
    notification.show();
  }
}

// App lifecycle
app.whenReady().then(() => {
  createTray();

  const registered = globalShortcut.register(
    "CommandOrControl+Shift+L",
    () => {
      convertSelectedText();
    }
  );

  if (!registered) {
    console.error("Failed to register global shortcut Ctrl+Shift+L");
  }

  console.log(
    "PimPid Windows started — Ctrl+Shift+L to convert selected text"
  );
});

app.on("will-quit", () => {
  globalShortcut.unregisterAll();
  if (autoCorrectEnabled) {
    stopAutoCorrection();
  }
});

app.on("window-all-closed", () => {
  // Prevent app from quitting when all windows are closed (tray app)
});

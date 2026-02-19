import {
  app,
  Tray,
  Menu,
  BrowserWindow,
  globalShortcut,
  clipboard,
  nativeImage,
  Notification,
  ipcMain,
} from "electron";
import * as path from "path";
import { convertAuto, dominantLanguage, ConversionDirection } from "./converter";
import {
  startAutoCorrection,
  stopAutoCorrection,
  isAutoCorrectRunning,
  updateAutoCorrectConfig,
  setExcludeWords,
} from "./auto-correction";
import { initStore, store } from "./store";
import { setLang, getLang, t } from "./i18n";

let tray: Tray | null = null;
let settingsWin: BrowserWindow | null = null;

// ─── Notification tracking (prevent leak) ─────────────────────────────────────
let lastNotification: Notification | null = null;
let lastNotificationTimer: ReturnType<typeof setTimeout> | null = null;

function showNotification(title: string, body: string): void {
  if (!Notification.isSupported()) return;
  if (lastNotification) {
    try { lastNotification.close(); } catch { /* ignore */ }
    lastNotification = null;
  }
  if (lastNotificationTimer) {
    clearTimeout(lastNotificationTimer);
    lastNotificationTimer = null;
  }
  const n = new Notification({ title, body, silent: true });
  n.show();
  lastNotification = n;
  // Auto-clear reference after it should have expired
  lastNotificationTimer = setTimeout(() => {
    if (lastNotification === n) lastNotification = null;
    lastNotificationTimer = null;
  }, 5000);
}

// ─── Tray icon ────────────────────────────────────────────────────────────────
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

function createTray(): void {
  const iconPath = path.join(__dirname, "..", "src", "icon.png");
  let trayIcon: Electron.NativeImage;
  try {
    trayIcon = nativeImage.createFromPath(iconPath);
    if (trayIcon.isEmpty()) trayIcon = createDefaultIcon();
  } catch {
    trayIcon = createDefaultIcon();
  }

  tray = new Tray(trayIcon.resize({ width: 16, height: 16 }));
  tray.setToolTip(t("tray.tooltip"));
  updateTrayMenu();
}

function setAutoCorrectMasterEnabled(enabled: boolean): void {
  if (enabled) {
    if (!isAutoCorrectRunning()) {
      startAutoCorrection({
        enabled: true,
        debounceMs: store.get("autoCorrectDebounceMs"),
        minBufferLength: store.get("autoCorrectMinChars"),
        excludeWords: store.get("excludeWords"),
        onCorrection: (original, converted) => {
          console.log(`[PimPid] Auto-corrected: ${original} → ${converted}`);
        },
      });
    }

    const running = isAutoCorrectRunning();
    store.set("autoCorrectEnabled", running);
    store.set("isEnabled", running);
    return;
  }

  if (isAutoCorrectRunning()) {
    stopAutoCorrection();
  }
  store.set("autoCorrectEnabled", false);
  store.set("isEnabled", false);
}

// ─── Tray menu (i18n-aware) ───────────────────────────────────────────────────
function updateTrayMenu(): void {
  if (!tray) return;

  const autoCorrectEnabled = store.get("autoCorrectEnabled");

  const contextMenu = Menu.buildFromTemplate([
    {
      label: t("tray.title"),
      enabled: false,
    },
    { type: "separator" },
    {
      label: autoCorrectEnabled
        ? t("menu.autocorrect.on")
        : t("menu.autocorrect.off"),
      click: toggleAutoCorrect,
    },
    { type: "separator" },
    {
      label: t("menu.convert"),
      click: () => convertSelectedText(),
      enabled: autoCorrectEnabled,
    },
    { type: "separator" },
    {
      label: t("menu.settings"),
      click: openSettings,
    },
    {
      label: t("menu.quit"),
      click: () => app.quit(),
    },
  ]);

  tray.setContextMenu(contextMenu);
  tray.setToolTip(t("tray.tooltip"));
}

// ─── Auto-correct toggle ──────────────────────────────────────────────────────
function toggleAutoCorrect(): void {
  setAutoCorrectMasterEnabled(!store.get("autoCorrectEnabled"));
  updateTrayMenu();
  broadcastSettings();
}

// ─── Convert selected text ────────────────────────────────────────────────────
async function convertSelectedText(): Promise<void> {
  if (!store.get("autoCorrectEnabled")) return;

  const savedClipboard = clipboard.readText();
  clipboard.writeText("");

  await simulateKeyCombo("c");
  await sleep(200);

  const selectedText = clipboard.readText();

  if (!selectedText || selectedText.trim() === "") {
    clipboard.writeText(savedClipboard);
    return;
  }

  // Check exclude words
  const excludeWords = store.get("excludeWords");
  const lower = selectedText.trim().toLowerCase();
  if (excludeWords.some((w) => w.toLowerCase() === lower)) {
    clipboard.writeText(savedClipboard);
    return;
  }

  const converted = convertAuto(selectedText);

  if (converted === selectedText) {
    clipboard.writeText(savedClipboard);
    return;
  }

  clipboard.writeText(converted);
  await simulateKeyCombo("v");

  await sleep(400);
  clipboard.writeText(savedClipboard);

  const direction = dominantLanguage(selectedText);
  const dirLabel =
    direction === ConversionDirection.ThaiToEnglish
      ? t("notify.converted.th_to_en")
      : t("notify.converted.en_to_th");
  showNotification(dirLabel, `${selectedText} → ${converted}`);
}

// ─── Key simulation (PowerShell) ─────────────────────────────────────────────
function simulateKeyCombo(key: string): Promise<void> {
  return new Promise((resolve) => {
    const { exec } = require("child_process");
    const psScript =
      key === "c"
        ? `Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait("^c")`
        : `Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait("^v")`;
    const encoded = Buffer.from(psScript, "utf16le").toString("base64");

    exec(
      `powershell -NoProfile -WindowStyle Hidden -EncodedCommand ${encoded}`,
      { timeout: 5000 },
      (error: Error | null) => {
        if (error) console.error(`[PimPid] SendKeys ${key} failed:`, error.message);
        resolve();
      }
    );
  });
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// ─── Settings window ──────────────────────────────────────────────────────────
function openSettings(): void {
  if (settingsWin && !settingsWin.isDestroyed()) {
    settingsWin.focus();
    return;
  }

  settingsWin = new BrowserWindow({
    width: 480,
    height: 540,
    resizable: false,
    minimizable: false,
    maximizable: false,
    title: t("settings.title"),
    webPreferences: {
      preload: path.join(__dirname, "settings-preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
    },
    show: false,
  });

  settingsWin.setMenuBarVisibility(false);
  settingsWin.loadFile(path.join(__dirname, "..", "src", "settings.html"));

  settingsWin.once("ready-to-show", () => {
    settingsWin?.show();
  });

  settingsWin.on("closed", () => {
    settingsWin = null;
  });
}

/** Push latest settings to open settings window */
function broadcastSettings(): void {
  if (settingsWin && !settingsWin.isDestroyed()) {
    settingsWin.webContents.send("settings:updated", store.getAll());
  }
}

// ─── IPC handlers ─────────────────────────────────────────────────────────────
function setupIPC(): void {
  ipcMain.handle("settings:get", () => store.getAll());

  ipcMain.handle("settings:getLang", () => getLang());

  ipcMain.handle(
    "settings:set",
    (_event, key: string, value: unknown) => {
      // Validate key is a known store key to prevent prototype pollution
      const VALID_KEYS = new Set([
        "language", "isEnabled", "autoCorrectEnabled",
        "autoCorrectDebounceMs", "autoCorrectMinChars", "excludeWords", "shortcut",
      ]);
      if (!VALID_KEYS.has(key)) return;

      // Side effects
      switch (key) {
        case "language":
          if (value === "th" || value === "en") {
            store.set("language", value);
            setLang(value);
            updateTrayMenu();
          }
          break;

        case "isEnabled":
        case "autoCorrectEnabled":
          setAutoCorrectMasterEnabled(Boolean(value));
          updateTrayMenu();
          break;

        case "autoCorrectDebounceMs":
          store.set("autoCorrectDebounceMs", value as number);
          updateAutoCorrectConfig({ debounceMs: value as number });
          break;

        case "autoCorrectMinChars":
          store.set("autoCorrectMinChars", value as number);
          updateAutoCorrectConfig({ minBufferLength: value as number });
          break;

        case "excludeWords":
          store.set("excludeWords", value as string[]);
          setExcludeWords(value as string[]);
          break;

        case "shortcut":
          store.set("shortcut", value as string);
          break;
      }

      broadcastSettings();
    }
  );
}

// ─── App lifecycle ────────────────────────────────────────────────────────────
app.whenReady().then(() => {
  initStore();

  // Keep legacy isEnabled in sync with the single Auto-Correct toggle.
  store.set("isEnabled", store.get("autoCorrectEnabled"));

  // Apply persisted language
  const lang = store.get("language");
  setLang(lang);

  setupIPC();
  createTray();

  // Register global shortcut
  const shortcut = store.get("shortcut");
  const registered = globalShortcut.register(shortcut, () => {
    convertSelectedText();
  });
  if (!registered) {
    console.error(`[PimPid] Failed to register shortcut: ${shortcut}`);
  }

  // Restore auto-correct if it was enabled.
  if (store.get("autoCorrectEnabled")) {
    setAutoCorrectMasterEnabled(true);
    updateTrayMenu();
  }

  console.log("[PimPid] Started — shortcut:", shortcut);
});

app.on("will-quit", () => {
  globalShortcut.unregisterAll();
  if (isAutoCorrectRunning()) {
    stopAutoCorrection();
  }
  if (lastNotificationTimer) {
    clearTimeout(lastNotificationTimer);
    lastNotificationTimer = null;
  }
  if (lastNotification) {
    try { lastNotification.close(); } catch { /* ignore */ }
    lastNotification = null;
  }
});

// Prevent quit when settings window closes (tray-only app)
app.on("window-all-closed", () => { /* keep running */ });

import {
  app,
  Tray,
  Menu,
  BrowserWindow,
  globalShortcut,
  clipboard,
  nativeImage,
  ipcMain,
  screen,
  dialog,
} from "electron";
import * as path from "path";
import { convertAuto, dominantLanguage, ConversionDirection } from "./converter";
import {
  startAutoCorrection,
  stopAutoCorrection,
  isAutoCorrectRunning,
  isAutoCorrectProcessing,
  updateAutoCorrectConfig,
  setExcludeWords,
} from "./auto-correction";
import { initStore, store, flushStore } from "./store";
import type { ConversionRecord } from "./store";
import { setLang, getLang, t } from "./i18n";

import * as fs from "fs";

let tray: Tray | null = null;
let settingsWin: BrowserWindow | null = null;
let onboardingWin: BrowserWindow | null = null;
let floatWin: BrowserWindow | null = null;
let toastWin: BrowserWindow | null = null;
let toastTimer: ReturnType<typeof setTimeout> | null = null;

// ─── Toast notification (in-app) ──────────────────────────────────────────────
// Reuse toast window to avoid create/destroy overhead on every notification.
let toastReady = false;

function createToastWindow(): void {
  const display = screen.getPrimaryDisplay();
  const { width: screenW, height: screenH } = display.workAreaSize;
  const toastW = 340;
  const toastH = 88;
  const margin = 16;

  toastWin = new BrowserWindow({
    width: toastW,
    height: toastH,
    x: screenW - toastW - margin,
    y: screenH - toastH - margin,
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    skipTaskbar: true,
    focusable: false,
    resizable: false,
    show: false,
    webPreferences: {
      preload: path.join(__dirname, "toast-preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  toastWin.setMenuBarVisibility(false);
  toastWin.loadFile(path.join(__dirname, "..", "src", "toast.html"));

  toastWin.on("closed", () => {
    toastWin = null;
    toastReady = false;
  });
}

function showToast(directionLabel: string, original: string, converted: string): void {
  // Cancel any pending hide timer
  if (toastTimer) {
    clearTimeout(toastTimer);
    toastTimer = null;
  }

  // Create toast window lazily if it doesn't exist yet
  if (!toastWin || toastWin.isDestroyed()) {
    toastReady = false;
    createToastWindow();
  }

  const sendData = () => {
    if (!toastWin || toastWin.isDestroyed()) return;
    // Recalculate position for current display (handles monitor changes)
    const display = screen.getPrimaryDisplay();
    const { width: sw, height: sh } = display.workAreaSize;
    const toastW = 340;
    const toastH = 88;
    const margin = 16;
    toastWin.setBounds({
      x: sw - toastW - margin,
      y: sh - toastH - margin,
      width: toastW,
      height: toastH,
    });

    toastWin.webContents.send("toast:data", {
      directionLabel,
      original,
      converted,
      theme: store.get("theme"),
    });
    toastWin.showInactive();

    // Auto-hide after 4 seconds (toast has 3s display + fade animation)
    toastTimer = setTimeout(() => {
      if (toastWin && !toastWin.isDestroyed()) {
        toastWin.hide();
      }
      toastTimer = null;
    }, 4000);
  };

  if (toastReady) {
    sendData();
  } else if (toastWin && !toastWin.isDestroyed()) {
    // Wait for ready-to-show on first creation
    toastWin.once("ready-to-show", () => {
      toastReady = true;
      sendData();
    });
  }
}

/** Legacy wrapper — keeps call sites unchanged */
function showNotification(title: string, body: string): void {
  // Parse "original → converted" from body
  const parts = body.split(" \u2192 ");
  const original = parts[0] || body;
  const converted = parts[1] || "";
  showToast(title, original, converted);
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

// ─── Statistics recording ─────────────────────────────────────────────────────
function recordConversion(from: string, to: string, direction: string): void {
  // Update daily stats
  const stats = store.get("conversionStats");
  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const daily = { ...stats.daily };
  daily[today] = (daily[today] || 0) + 1;

  // Prune daily entries older than 90 days to prevent unbounded growth
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 90);
  const cutoffStr = cutoff.toISOString().slice(0, 10);
  for (const dateKey of Object.keys(daily)) {
    if (dateKey < cutoffStr) delete daily[dateKey];
  }

  store.set("conversionStats", { daily, total: stats.total + 1 });

  // Update recent conversions (keep last 20)
  const recent = [...store.get("recentConversions")];
  const record: ConversionRecord = {
    from: from.length > 80 ? from.slice(0, 80) + "..." : from,
    to: to.length > 80 ? to.slice(0, 80) + "..." : to,
    timestamp: Date.now(),
    direction,
  };
  recent.unshift(record);
  if (recent.length > 20) recent.length = 20;
  store.set("recentConversions", recent);
}

// ─── Convert selected text ────────────────────────────────────────────────────
let isConvertingSelectedText = false;

async function convertSelectedText(): Promise<void> {
  if (!store.get("autoCorrectEnabled")) return;
  // Guard against concurrent execution — prevents clipboard corruption when shortcut
  // is pressed rapidly or auto-correction fires simultaneously.
  if (isConvertingSelectedText) return;
  // Wait if auto-correction is mid-replacement (it uses the clipboard too)
  if (isAutoCorrectProcessing()) return;
  isConvertingSelectedText = true;

  try {
    const savedClipboard = clipboard.readText();
    clipboard.writeText("");

    await simulateKeyCombo("c");
    await sleep(200);

    const selectedText = clipboard.readText();

    if (!selectedText || selectedText.trim() === "") {
      clipboard.writeText(savedClipboard);
      return;
    }

    // Guard against extremely large selections (>100KB) to prevent conversion timeout
    if (selectedText.length > 100_000) {
      console.warn("[PimPid] Selected text too large to convert:", selectedText.length, "chars");
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

    // Record conversion stats
    recordConversion(
      selectedText,
      converted,
      direction === ConversionDirection.ThaiToEnglish ? "th_to_en" : "en_to_th"
    );
  } finally {
    isConvertingSelectedText = false;
  }
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

/** Escape a value for CSV (wrap in quotes if it contains comma, quote, or newline) */
function csvEscape(value: string): string {
  if (value.includes(",") || value.includes('"') || value.includes("\n")) {
    return '"' + value.replace(/"/g, '""') + '"';
  }
  return value;
}

// ─── Shortcut management ─────────────────────────────────────────────────────
function registerShortcut(shortcut: string): boolean {
  try {
    globalShortcut.unregisterAll();
    const registered = globalShortcut.register(shortcut, () => {
      convertSelectedText();
    });
    if (registered) {
      console.log(`[PimPid] Shortcut registered: ${shortcut}`);
    } else {
      console.error(`[PimPid] Failed to register shortcut: ${shortcut}`);
    }
    return registered;
  } catch (err) {
    console.error(`[PimPid] Error registering shortcut:`, err);
    return false;
  }
}

// ─── Onboarding window ──────────────────────────────────────────────────────
function openOnboarding(): void {
  if (onboardingWin && !onboardingWin.isDestroyed()) {
    onboardingWin.focus();
    return;
  }

  onboardingWin = new BrowserWindow({
    width: 520,
    height: 460,
    resizable: false,
    minimizable: false,
    maximizable: false,
    title: t("onboarding.title"),
    webPreferences: {
      preload: path.join(__dirname, "onboarding-preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
    show: false,
  });

  onboardingWin.setMenuBarVisibility(false);
  onboardingWin.loadFile(path.join(__dirname, "..", "src", "onboarding.html"));

  onboardingWin.once("ready-to-show", () => {
    onboardingWin?.show();
  });

  onboardingWin.on("closed", () => {
    onboardingWin = null;
  });
}

// ─── Float button ─────────────────────────────────────────────────────────────
function openFloatButton(): void {
  if (floatWin && !floatWin.isDestroyed()) {
    floatWin.focus();
    return;
  }

  const display = screen.getPrimaryDisplay();
  const { width: screenW, height: screenH } = display.workAreaSize;
  const btnSize = 60; // slightly larger than 48 to give padding for the close button
  const margin = 24;

  floatWin = new BrowserWindow({
    width: btnSize,
    height: btnSize,
    x: screenW - btnSize - margin,
    y: Math.round(screenH / 2),
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    skipTaskbar: true,
    resizable: false,
    hasShadow: false,
    show: false,
    webPreferences: {
      preload: path.join(__dirname, "float-preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  floatWin.setMenuBarVisibility(false);
  floatWin.loadFile(path.join(__dirname, "..", "src", "float-button.html"));

  floatWin.once("ready-to-show", () => {
    floatWin?.show();
  });

  floatWin.on("closed", () => {
    floatWin = null;
  });
}

function closeFloatButton(): void {
  if (floatWin && !floatWin.isDestroyed()) {
    floatWin.close();
  }
  floatWin = null;
  // Update store; broadcastSettings is handled by the caller (settings:set or float:close IPC)
  store.set("showFloatButton", false);
}

// ─── Settings window ──────────────────────────────────────────────────────────
function openSettings(): void {
  if (settingsWin && !settingsWin.isDestroyed()) {
    settingsWin.focus();
    return;
  }

  settingsWin = new BrowserWindow({
    width: 520,
    height: 580,
    resizable: false,
    minimizable: false,
    maximizable: false,
    title: t("settings.title"),
    webPreferences: {
      preload: path.join(__dirname, "settings-preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
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
        "theme", "fontSize", "showFloatButton",
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

        case "autoCorrectDebounceMs": {
          const debounce = Number(value);
          if (!Number.isFinite(debounce)) break;
          const clampedDebounce = Math.max(0, Math.min(1000, Math.round(debounce)));
          store.set("autoCorrectDebounceMs", clampedDebounce);
          updateAutoCorrectConfig({ debounceMs: clampedDebounce });
          break;
        }

        case "autoCorrectMinChars": {
          const minChars = Number(value);
          if (!Number.isFinite(minChars)) break;
          const clampedMinChars = Math.max(1, Math.min(10, Math.round(minChars)));
          store.set("autoCorrectMinChars", clampedMinChars);
          updateAutoCorrectConfig({ minBufferLength: clampedMinChars });
          break;
        }

        case "excludeWords": {
          if (!Array.isArray(value)) break;
          const words = value.filter((v): v is string => typeof v === "string");
          store.set("excludeWords", words);
          setExcludeWords(words);
          break;
        }

        case "shortcut":
          if (typeof value !== "string" || !value) break;
          store.set("shortcut", value);
          break;

        case "theme":
          if (value === "auto" || value === "light" || value === "dark") {
            store.set("theme", value);
          }
          break;

        case "fontSize":
          if (value === "small" || value === "medium" || value === "large" || value === "xl") {
            store.set("fontSize", value);
          }
          break;

        case "showFloatButton":
          store.set("showFloatButton", Boolean(value));
          if (value) {
            openFloatButton();
          } else {
            closeFloatButton();
          }
          break;
      }

      broadcastSettings();
    }
  );

  // Shortcut change IPC
  ipcMain.handle("shortcut:change", (_event, newShortcut: string) => {
    // Validate shortcut format (must contain modifier + key)
    if (typeof newShortcut !== "string" || newShortcut.length === 0) {
      return { success: false, error: "Invalid shortcut" };
    }

    const parts = newShortcut.split("+");
    if (parts.length < 2) {
      return { success: false, error: "Shortcut must include a modifier key" };
    }

    const success = registerShortcut(newShortcut);
    if (success) {
      store.set("shortcut", newShortcut);
      broadcastSettings();
      return { success: true };
    }
    // Restore old shortcut on failure
    const oldShortcut = store.get("shortcut");
    registerShortcut(oldShortcut);
    return { success: false, error: "Could not register shortcut" };
  });

  // Stats IPC
  ipcMain.handle("stats:get", () => {
    return {
      conversionStats: store.get("conversionStats"),
      recentConversions: store.get("recentConversions"),
    };
  });

  ipcMain.handle("stats:clear", () => {
    store.set("conversionStats", { daily: {}, total: 0 });
    store.set("recentConversions", []);
    return { success: true };
  });

  // Onboarding IPC
  ipcMain.handle("onboarding:complete", () => {
    store.set("hasCompletedOnboarding", true);
    if (onboardingWin && !onboardingWin.isDestroyed()) {
      onboardingWin.close();
    }
  });

  ipcMain.handle("onboarding:getLang", () => getLang());

  // ─── Float button IPC ─────────────────────────────────────────────────────
  ipcMain.on("float:convert", () => {
    convertSelectedText();
  });

  ipcMain.on("float:close", () => {
    closeFloatButton();
    broadcastSettings();
  });

  ipcMain.on("float:drag-move", (_event, dx: number, dy: number) => {
    if (!floatWin || floatWin.isDestroyed()) return;
    // Validate inputs are finite numbers
    if (typeof dx !== "number" || typeof dy !== "number") return;
    if (!Number.isFinite(dx) || !Number.isFinite(dy)) return;
    const [x, y] = floatWin.getPosition();
    floatWin.setPosition(x + Math.round(dx), y + Math.round(dy));
  });

  // ─── Export stats CSV ─────────────────────────────────────────────────────
  ipcMain.handle("stats:export", async () => {
    const recentConversions = store.get("recentConversions");
    if (!recentConversions.length) {
      return { success: false, error: "empty" };
    }

    const result = await dialog.showSaveDialog({
      defaultPath: `pimpid-stats-${new Date().toISOString().slice(0, 10)}.csv`,
      filters: [
        { name: "CSV Files", extensions: ["csv"] },
      ],
    });

    if (result.canceled || !result.filePath) {
      return { success: false, error: "canceled" };
    }

    // Build CSV content with BOM for Excel compatibility
    const bom = "\uFEFF";
    const header = "timestamp,original,converted,direction";
    const rows = recentConversions.map((r) => {
      const ts = new Date(r.timestamp).toISOString();
      const from = csvEscape(r.from);
      const to = csvEscape(r.to);
      const dir = r.direction;
      return `${ts},${from},${to},${dir}`;
    });

    const csv = bom + header + "\n" + rows.join("\n") + "\n";

    try {
      fs.writeFileSync(result.filePath, csv, "utf-8");
      return { success: true };
    } catch (err) {
      console.error("[PimPid] Export CSV failed:", err);
      return { success: false, error: "write_failed" };
    }
  });
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
  registerShortcut(shortcut);

  // Restore auto-correct if it was enabled.
  if (store.get("autoCorrectEnabled")) {
    setAutoCorrectMasterEnabled(true);
    updateTrayMenu();
  }

  // Restore float button if it was enabled
  if (store.get("showFloatButton")) {
    openFloatButton();
  }

  // Show onboarding for first-time users
  if (!store.get("hasCompletedOnboarding")) {
    openOnboarding();
  }

  console.log("[PimPid] Started — shortcut:", shortcut);
});

app.on("will-quit", () => {
  globalShortcut.unregisterAll();
  if (isAutoCorrectRunning()) {
    stopAutoCorrection();
  }
  if (toastTimer) {
    clearTimeout(toastTimer);
    toastTimer = null;
  }
  // Destroy all windows on quit
  for (const win of [toastWin, floatWin, settingsWin, onboardingWin]) {
    if (win && !win.isDestroyed()) {
      try { win.close(); } catch { /* ignore */ }
    }
  }
  toastWin = null;
  floatWin = null;
  settingsWin = null;
  onboardingWin = null;
  // Flush any pending debounced store writes before exit
  flushStore();
});

// Prevent quit when settings window closes (tray-only app)
app.on("window-all-closed", () => { /* keep running */ });

// ─── Global error handlers ──────────────────────────────────────────────────
// Prevent unhandled errors from crashing the app silently
process.on("uncaughtException", (error) => {
  console.error("[PimPid] Uncaught exception:", error);
});

process.on("unhandledRejection", (reason) => {
  console.error("[PimPid] Unhandled promise rejection:", reason);
});

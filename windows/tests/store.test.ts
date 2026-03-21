/**
 * Tests for store.ts — persistent settings store
 * We mock Electron's app module and fs to test in isolation.
 */
import { describe, it, expect, beforeEach, vi } from "vitest";
import * as fs from "fs";
import * as path from "path";

// Mock electron app module
vi.mock("electron", () => ({
  app: {
    getPath: (name: string) => {
      if (name === "userData") return "/tmp/pimpid-test-" + process.pid;
      return "/tmp";
    },
  },
}));

// Import after mocking
import { initStore, store, flushStore } from "../src/store";
import type { StoreData } from "../src/store";

const testDir = "/tmp/pimpid-test-" + process.pid;
const testFile = path.join(testDir, "pimpid-settings.json");

beforeEach(() => {
  // Clean up test file
  try {
    fs.unlinkSync(testFile);
  } catch { /* ignore if not exists */ }
  try {
    fs.rmdirSync(testDir);
  } catch { /* ignore */ }

  // Reinitialize store (loads defaults since file doesn't exist)
  initStore();
});

describe("store initialization", () => {
  it("loads default values when no settings file exists", () => {
    const all = store.getAll();
    expect(all.language).toBe("th");
    expect(all.isEnabled).toBe(false);
    expect(all.autoCorrectEnabled).toBe(false);
    expect(all.autoCorrectDebounceMs).toBe(300);
    expect(all.autoCorrectMinChars).toBe(3);
    expect(all.excludeWords).toEqual([]);
    expect(all.shortcut).toBe("CommandOrControl+Shift+L");
    expect(all.hasCompletedOnboarding).toBe(false);
    expect(all.showFloatButton).toBe(false);
    expect(all.theme).toBe("auto");
    expect(all.fontSize).toBe("medium");
    expect(all.conversionStats).toEqual({ daily: {}, total: 0 });
    expect(all.recentConversions).toEqual([]);
  });
});

describe("store.get", () => {
  it("returns default value for each key", () => {
    expect(store.get("language")).toBe("th");
    expect(store.get("isEnabled")).toBe(false);
    expect(store.get("theme")).toBe("auto");
    expect(store.get("fontSize")).toBe("medium");
  });
});

describe("store.set", () => {
  it("updates a value and persists to disk", () => {
    store.set("language", "en");
    expect(store.get("language")).toBe("en");

    // Flush debounced write before checking disk
    flushStore();

    // Check file was written
    expect(fs.existsSync(testFile)).toBe(true);
    const raw = JSON.parse(fs.readFileSync(testFile, "utf-8"));
    expect(raw.language).toBe("en");
  });

  it("updates boolean values", () => {
    store.set("isEnabled", true);
    expect(store.get("isEnabled")).toBe(true);
  });

  it("updates array values", () => {
    store.set("excludeWords", ["test", "hello"]);
    expect(store.get("excludeWords")).toEqual(["test", "hello"]);
  });

  it("updates complex object values", () => {
    store.set("conversionStats", { daily: { "2024-01-01": 5 }, total: 5 });
    expect(store.get("conversionStats")).toEqual({ daily: { "2024-01-01": 5 }, total: 5 });
  });
});

describe("store.getAll", () => {
  it("returns a shallow copy (not the internal reference)", () => {
    const all1 = store.getAll();
    const all2 = store.getAll();
    expect(all1).toEqual(all2);
    expect(all1).not.toBe(all2); // different object references
  });

  it("reflects latest changes", () => {
    store.set("theme", "dark");
    store.set("fontSize", "xl");
    const all = store.getAll();
    expect(all.theme).toBe("dark");
    expect(all.fontSize).toBe("xl");
  });
});

describe("store persistence", () => {
  it("loads previously saved values after reinit", () => {
    store.set("language", "en");
    store.set("theme", "dark");

    // Flush debounced write before reinit (simulates app shutdown flush)
    flushStore();

    // Reinitialize (simulates app restart)
    initStore();

    expect(store.get("language")).toBe("en");
    expect(store.get("theme")).toBe("dark");
  });

  it("merges saved data with defaults for new keys", () => {
    // Write a partial settings file (simulating old version)
    const dir = path.dirname(testFile);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(testFile, JSON.stringify({ language: "en" }), "utf-8");

    initStore();

    // Saved value preserved
    expect(store.get("language")).toBe("en");
    // New keys get defaults
    expect(store.get("theme")).toBe("auto");
    expect(store.get("fontSize")).toBe("medium");
  });

  it("handles corrupted JSON file gracefully", () => {
    const dir = path.dirname(testFile);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(testFile, "not json{{{", "utf-8");

    // Should not throw, should use defaults
    initStore();
    expect(store.get("language")).toBe("th");
  });
});

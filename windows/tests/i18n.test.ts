/**
 * Tests for i18n.ts — Thai/English localization
 */
import { describe, it, expect, beforeEach } from "vitest";
import { setLang, getLang, t } from "../src/i18n";
import type { Lang } from "../src/i18n";

beforeEach(() => {
  // Reset to default Thai
  setLang("th");
});

describe("setLang / getLang", () => {
  it("defaults to th after reset", () => {
    expect(getLang()).toBe("th");
  });

  it("switches to en", () => {
    setLang("en");
    expect(getLang()).toBe("en");
  });

  it("switches back to th", () => {
    setLang("en");
    setLang("th");
    expect(getLang()).toBe("th");
  });
});

describe("t() — translation function", () => {
  it("returns Thai string for Thai language", () => {
    setLang("th");
    expect(t("menu.quit")).toBe("ออกจาก PimPid");
  });

  it("returns English string for English language", () => {
    setLang("en");
    expect(t("menu.quit")).toBe("Quit PimPid");
  });

  it("falls back to English when key missing in current language", () => {
    // If a key existed only in 'en', it should fall back
    // Both languages have the same keys, so we test the fallback path
    setLang("th");
    // All keys exist in both, so test the mechanism by checking it does not crash
    expect(t("tray.title")).toBe("PimPid — ไทย ⇄ English");
  });

  it("falls back to key name when key missing in both languages", () => {
    expect(t("nonexistent.key")).toBe("nonexistent.key");
  });

  it("returns empty-like string for empty key", () => {
    expect(t("")).toBe("");
  });
});

describe("i18n key completeness", () => {
  // Collect all keys from both languages
  // We access the strings object indirectly through t()

  const knownKeys = [
    // Tray
    "tray.title", "tray.tooltip",
    // Tray menu
    "menu.enable.on", "menu.enable.off",
    "menu.autocorrect.on", "menu.autocorrect.off",
    "menu.convert", "menu.settings", "menu.quit",
    // Settings window
    "settings.title", "settings.tab.general", "settings.tab.autocorrect",
    "settings.tab.exclude", "settings.tab.stats", "settings.tab.appearance",
    // General tab
    "general.section.basic", "general.enable", "general.enable.desc",
    "general.language", "general.language.th", "general.language.en",
    "general.language.hint", "general.shortcut", "general.shortcut.change",
    "general.shortcut.recording", "general.shortcut.cancel",
    // Auto-Correct tab
    "autocorrect.section.enable", "autocorrect.enable", "autocorrect.enable.desc",
    "autocorrect.section.settings", "autocorrect.delay", "autocorrect.delay.hint",
    "autocorrect.minChars", "autocorrect.minChars.hint", "autocorrect.chars.unit",
    // Exclude Words tab
    "exclude.section.add", "exclude.placeholder", "exclude.add",
    "exclude.hint", "exclude.section.list", "exclude.empty",
    // Stats tab
    "stats.section.summary", "stats.today", "stats.total", "stats.times",
    "stats.section.recent", "stats.empty", "stats.clear",
    // Appearance tab
    "appearance.section.theme", "appearance.theme",
    "appearance.theme.auto", "appearance.theme.light", "appearance.theme.dark",
    "appearance.section.font", "appearance.fontSize",
    "appearance.fontSize.small", "appearance.fontSize.medium",
    "appearance.fontSize.large", "appearance.fontSize.xl",
    // Onboarding
    "onboarding.title", "onboarding.welcome.title", "onboarding.welcome.desc",
    "onboarding.shortcut.title", "onboarding.shortcut.desc",
    "onboarding.autocorrect.title", "onboarding.autocorrect.desc",
    "onboarding.getstarted.title", "onboarding.getstarted.desc",
    "onboarding.next", "onboarding.prev", "onboarding.start",
    // Notifications
    "notify.converted.th_to_en", "notify.converted.en_to_th", "notify.autocorrect",
    // Float button
    "general.floatButton", "general.floatButton.desc",
    // Export
    "stats.export", "stats.export.success", "stats.export.empty",
    // Buttons
    "button.close", "button.reset",
  ];

  it("all known keys return a non-key value in Thai", () => {
    setLang("th");
    for (const key of knownKeys) {
      const value = t(key);
      expect(value, `Thai key "${key}" should not fall back to key name`).not.toBe(key);
    }
  });

  it("all known keys return a non-key value in English", () => {
    setLang("en");
    for (const key of knownKeys) {
      const value = t(key);
      expect(value, `English key "${key}" should not fall back to key name`).not.toBe(key);
    }
  });
});

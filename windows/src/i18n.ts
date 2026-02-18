/**
 * i18n — Thai / English localization for PimPid Windows
 * Default language: Thai (th)
 * Mirrors macOS Localizable.strings keys
 */

export type Lang = "th" | "en";

const strings: Record<Lang, Record<string, string>> = {
  th: {
    // Tray
    "tray.title": "PimPid — ไทย ⇄ English",
    "tray.tooltip": "PimPid — ตัวแปลงภาษาไทย ⇄ อังกฤษ",

    // Tray menu
    "menu.enable.on": "✅ เปิดใช้งาน",
    "menu.enable.off": "⬜ เปิดใช้งาน",
    "menu.autocorrect.on": "⚡ Auto-Correct: เปิด",
    "menu.autocorrect.off": "⚡ Auto-Correct: ปิด",
    "menu.convert": "แปลงข้อความที่เลือก (Ctrl+Shift+L)",
    "menu.settings": "ตั้งค่า…",
    "menu.quit": "ออกจาก PimPid",

    // Settings window
    "settings.title": "ตั้งค่า PimPid",
    "settings.tab.general": "ทั่วไป",
    "settings.tab.autocorrect": "Auto-Correct",
    "settings.tab.exclude": "Exclude คำ",

    // General tab
    "general.section.basic": "การทำงานพื้นฐาน",
    "general.enable": "เปิดใช้งาน PimPid",
    "general.enable.desc": "เมื่อเปิดใช้งาน PimPid จะทำงานในเบื้องหลังและพร้อมแปลงข้อความ",
    "general.language": "ภาษาที่แสดง",
    "general.language.th": "ภาษาไทย",
    "general.language.en": "English",
    "general.language.hint": "เปิดแอปใหม่เพื่อให้ภาษาเปลี่ยน",
    "general.shortcut": "Shortcut ปัจจุบัน",

    // Auto-Correct tab
    "autocorrect.section.enable": "การเปิดใช้งาน",
    "autocorrect.enable": "เปิดใช้งาน Auto-Correct",
    "autocorrect.enable.desc": "แก้ไขข้อความอัตโนมัติทันทีที่พิมพ์ผิดภาษา",
    "autocorrect.section.settings": "ตั้งค่าการแก้ไข",
    "autocorrect.delay": "ความล่าช้า (ms)",
    "autocorrect.delay.hint": "เวลารอก่อนแก้ไขอัตโนมัติ (0–1000 ms, 0 = ใช้ค่าเริ่มต้น 300 ms)",
    "autocorrect.minChars": "จำนวนตัวอักษรขั้นต่ำ",
    "autocorrect.minChars.hint": "ต้องพิมพ์อย่างน้อยกี่ตัวอักษรก่อนจะเริ่มแก้ไขอัตโนมัติ",
    "autocorrect.chars.unit": "ตัว",

    // Exclude Words tab
    "exclude.section.add": "เพิ่มคำ",
    "exclude.placeholder": "คำที่ไม่ต้องการให้แปลง",
    "exclude.add": "เพิ่ม",
    "exclude.hint": "ป้อนคำที่ไม่ต้องการให้ PimPid แปลง เช่น ชื่อ, แบรนด์, คำศัพท์เฉพาะ",
    "exclude.section.list": "รายการ Exclude",
    "exclude.empty": "ยังไม่มีคำที่ exclude",

    // Notifications
    "notify.converted.th_to_en": "ไทย → English",
    "notify.converted.en_to_th": "English → ไทย",
    "notify.autocorrect": "PimPid แก้ไขอัตโนมัติ",

    // Buttons
    "button.close": "ปิด",
    "button.reset": "รีเซ็ตค่าเริ่มต้น",
  },

  en: {
    // Tray
    "tray.title": "PimPid — Thai ⇄ English",
    "tray.tooltip": "PimPid — Thai ⇄ English Converter",

    // Tray menu
    "menu.enable.on": "✅ Enabled",
    "menu.enable.off": "⬜ Enabled",
    "menu.autocorrect.on": "⚡ Auto-Correct: ON",
    "menu.autocorrect.off": "⚡ Auto-Correct: OFF",
    "menu.convert": "Convert Selected Text (Ctrl+Shift+L)",
    "menu.settings": "Settings…",
    "menu.quit": "Quit PimPid",

    // Settings window
    "settings.title": "PimPid Settings",
    "settings.tab.general": "General",
    "settings.tab.autocorrect": "Auto-Correct",
    "settings.tab.exclude": "Exclude Words",

    // General tab
    "general.section.basic": "Basic Operation",
    "general.enable": "Enable PimPid",
    "general.enable.desc": "When enabled, PimPid runs in the background and is ready to convert text",
    "general.language": "Display language",
    "general.language.th": "ภาษาไทย (Thai)",
    "general.language.en": "English",
    "general.language.hint": "Relaunch the app to apply the new language",
    "general.shortcut": "Current shortcut",

    // Auto-Correct tab
    "autocorrect.section.enable": "Enable",
    "autocorrect.enable": "Enable Auto-Correct",
    "autocorrect.enable.desc": "Automatically correct text when typing in the wrong language",
    "autocorrect.section.settings": "Correction Settings",
    "autocorrect.delay": "Delay (ms)",
    "autocorrect.delay.hint": "Wait time before auto-correcting (0–1000 ms, 0 = default 300 ms)",
    "autocorrect.minChars": "Minimum characters",
    "autocorrect.minChars.hint": "Minimum characters to type before auto-correction starts",
    "autocorrect.chars.unit": "chars",

    // Exclude Words tab
    "exclude.section.add": "Add Word",
    "exclude.placeholder": "Word to exclude from conversion",
    "exclude.add": "Add",
    "exclude.hint": "Enter words you don't want PimPid to convert (e.g. names, brands, jargon)",
    "exclude.section.list": "Exclude List",
    "exclude.empty": "No excluded words yet",

    // Notifications
    "notify.converted.th_to_en": "Thai → English",
    "notify.converted.en_to_th": "English → Thai",
    "notify.autocorrect": "PimPid Auto-Correct",

    // Buttons
    "button.close": "Close",
    "button.reset": "Reset to defaults",
  },
};

let currentLang: Lang = "th";

export function setLang(lang: Lang): void {
  currentLang = lang;
}

export function getLang(): Lang {
  return currentLang;
}

/** Returns translated string. Falls back to English, then key name. */
export function t(key: string): string {
  return strings[currentLang][key] ?? strings["en"][key] ?? key;
}

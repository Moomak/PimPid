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
    "settings.tab.stats": "สถิติ",
    "settings.tab.appearance": "รูปลักษณ์",

    // General tab
    "general.section.basic": "การทำงานพื้นฐาน",
    "general.enable": "เปิดใช้งาน PimPid",
    "general.enable.desc": "เมื่อเปิดใช้งาน PimPid จะทำงานในเบื้องหลังและพร้อมแปลงข้อความ",
    "general.language": "ภาษาที่แสดง",
    "general.language.th": "ภาษาไทย",
    "general.language.en": "English",
    "general.language.hint": "ภาษาจะเปลี่ยนทันที",
    "general.shortcut": "Shortcut ปัจจุบัน",
    "general.shortcut.change": "เปลี่ยน",
    "general.shortcut.recording": "กดคีย์ลัดที่ต้องการ...",
    "general.shortcut.cancel": "ยกเลิก",

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

    // Stats tab
    "stats.section.summary": "สรุป",
    "stats.today": "วันนี้",
    "stats.total": "ทั้งหมด",
    "stats.times": "ครั้ง",
    "stats.section.recent": "แปลงล่าสุด",
    "stats.empty": "ยังไม่มีประวัติการแปลง",
    "stats.clear": "ล้างประวัติ",

    // Appearance tab
    "appearance.section.theme": "ธีม",
    "appearance.theme": "ธีม",
    "appearance.theme.auto": "ตามระบบ",
    "appearance.theme.light": "สว่าง",
    "appearance.theme.dark": "มืด",
    "appearance.section.font": "ขนาดตัวอักษร",
    "appearance.fontSize": "ขนาดตัวอักษร",
    "appearance.fontSize.small": "เล็ก",
    "appearance.fontSize.medium": "กลาง",
    "appearance.fontSize.large": "ใหญ่",
    "appearance.fontSize.xl": "ใหญ่พิเศษ",

    // Onboarding
    "onboarding.title": "ยินดีต้อนรับสู่ PimPid",
    "onboarding.welcome.title": "ยินดีต้อนรับสู่ PimPid",
    "onboarding.welcome.desc": "ตัวช่วยแปลงข้อความเมื่อพิมพ์ผิดภาษา ไทย ⇄ English อัตโนมัติ",
    "onboarding.shortcut.title": "คีย์ลัดแปลงข้อความ",
    "onboarding.shortcut.desc": "เลือกข้อความแล้วกด Ctrl+Shift+L เพื่อแปลงภาษาทันที",
    "onboarding.autocorrect.title": "แก้ไขอัตโนมัติ",
    "onboarding.autocorrect.desc": "เปิด Auto-Correct เพื่อให้ PimPid แก้ไขข้อความที่พิมพ์ผิดภาษาทันทีที่พิมพ์",
    "onboarding.getstarted.title": "พร้อมใช้งาน!",
    "onboarding.getstarted.desc": "PimPid จะทำงานในถาดระบบ (System Tray) เริ่มต้นใช้งานได้เลย",
    "onboarding.next": "ถัดไป",
    "onboarding.prev": "ก่อนหน้า",
    "onboarding.start": "เริ่มใช้งาน",
    "onboarding.skip": "ข้าม",

    // Notifications
    "notify.converted.th_to_en": "ไทย → English",
    "notify.converted.en_to_th": "English → ไทย",
    "notify.autocorrect": "PimPid แก้ไขอัตโนมัติ",

    // Float button
    "general.floatButton": "แสดงปุ่มลอย",
    "general.floatButton.desc": "แสดงปุ่มลอยบนหน้าจอสำหรับแปลงข้อความโดยไม่ต้องใช้คีย์ลัด",

    // Export
    "stats.export": "ส่งออก CSV",
    "stats.export.success": "ส่งออกสำเร็จ",
    "stats.export.empty": "ไม่มีข้อมูลให้ส่งออก",

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
    "settings.tab.stats": "Statistics",
    "settings.tab.appearance": "Appearance",

    // General tab
    "general.section.basic": "Basic Operation",
    "general.enable": "Enable PimPid",
    "general.enable.desc": "When enabled, PimPid runs in the background and is ready to convert text",
    "general.language": "Display language",
    "general.language.th": "ภาษาไทย (Thai)",
    "general.language.en": "English",
    "general.language.hint": "Language changes immediately",
    "general.shortcut": "Current shortcut",
    "general.shortcut.change": "Change",
    "general.shortcut.recording": "Press desired shortcut...",
    "general.shortcut.cancel": "Cancel",

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

    // Stats tab
    "stats.section.summary": "Summary",
    "stats.today": "Today",
    "stats.total": "Total",
    "stats.times": "times",
    "stats.section.recent": "Recent Conversions",
    "stats.empty": "No conversion history yet",
    "stats.clear": "Clear history",

    // Appearance tab
    "appearance.section.theme": "Theme",
    "appearance.theme": "Theme",
    "appearance.theme.auto": "Auto",
    "appearance.theme.light": "Light",
    "appearance.theme.dark": "Dark",
    "appearance.section.font": "Font Size",
    "appearance.fontSize": "Font size",
    "appearance.fontSize.small": "Small",
    "appearance.fontSize.medium": "Medium",
    "appearance.fontSize.large": "Large",
    "appearance.fontSize.xl": "Extra Large",

    // Onboarding
    "onboarding.title": "Welcome to PimPid",
    "onboarding.welcome.title": "Welcome to PimPid",
    "onboarding.welcome.desc": "Automatically convert text when you type in the wrong keyboard layout. Thai ⇄ English.",
    "onboarding.shortcut.title": "Quick Convert Shortcut",
    "onboarding.shortcut.desc": "Select text and press Ctrl+Shift+L to instantly convert between Thai and English.",
    "onboarding.autocorrect.title": "Auto-Correct",
    "onboarding.autocorrect.desc": "Enable Auto-Correct to let PimPid automatically fix text typed in the wrong language as you type.",
    "onboarding.getstarted.title": "Ready to Go!",
    "onboarding.getstarted.desc": "PimPid runs in the System Tray. Start using it right away!",
    "onboarding.next": "Next",
    "onboarding.prev": "Back",
    "onboarding.start": "Get Started",
    "onboarding.skip": "Skip",

    // Notifications
    "notify.converted.th_to_en": "Thai → English",
    "notify.converted.en_to_th": "English → Thai",
    "notify.autocorrect": "PimPid Auto-Correct",

    // Float button
    "general.floatButton": "Show float button",
    "general.floatButton.desc": "Show a floating button on screen to convert text without using a shortcut",

    // Export
    "stats.export": "Export CSV",
    "stats.export.success": "Export successful",
    "stats.export.empty": "No data to export",

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

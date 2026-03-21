// ─── Types from preload ───────────────────────────────────────────────────────
/** @type {{ getSettings: () => Promise<any>, setSetting: (k: string, v: any) => Promise<void>, onSettingsChanged: (cb: (s:any)=>void)=>void, getLang: ()=>Promise<string>, changeShortcut: (s: string) => Promise<any>, getStats: () => Promise<any>, clearStats: () => Promise<any>, exportStats: () => Promise<any> }} */
const api = window.electronAPI;

// ─── i18n strings (subset needed by renderer) ─────────────────────────────────
const STRINGS = {
  th: {
    title: 'PimPid',
    tabGeneral: '\u0E17\u0E31\u0E48\u0E27\u0E44\u0E1B', tabAC: 'Auto-Correct', tabExclude: 'Exclude \u0E04\u0E33',
    tabStats: '\u0E2A\u0E16\u0E34\u0E15\u0E34', tabAppearance: '\u0E23\u0E39\u0E1B\u0E25\u0E31\u0E01\u0E29\u0E13\u0E4C',
    sectionBasic: '\u0E01\u0E32\u0E23\u0E17\u0E33\u0E07\u0E32\u0E19\u0E1E\u0E37\u0E49\u0E19\u0E10\u0E32\u0E19', lblEnable: '\u0E40\u0E1B\u0E34\u0E14\u0E43\u0E0A\u0E49\u0E07\u0E32\u0E19 PimPid',
    lblEnableDesc: '\u0E40\u0E21\u0E37\u0E48\u0E2D\u0E40\u0E1B\u0E34\u0E14\u0E43\u0E0A\u0E49\u0E07\u0E32\u0E19 PimPid \u0E08\u0E30\u0E17\u0E33\u0E07\u0E32\u0E19\u0E43\u0E19\u0E40\u0E1A\u0E37\u0E49\u0E2D\u0E07\u0E2B\u0E25\u0E31\u0E07\u0E41\u0E25\u0E30\u0E1E\u0E23\u0E49\u0E2D\u0E21\u0E41\u0E1B\u0E25\u0E07\u0E02\u0E49\u0E2D\u0E04\u0E27\u0E32\u0E21',
    lblLanguage: '\u0E20\u0E32\u0E29\u0E32\u0E17\u0E35\u0E48\u0E41\u0E2A\u0E14\u0E07', lblLangHint: '\u0E20\u0E32\u0E29\u0E32\u0E08\u0E30\u0E40\u0E1B\u0E25\u0E35\u0E48\u0E22\u0E19\u0E17\u0E31\u0E19\u0E17\u0E35',
    lblShortcut: 'Shortcut \u0E1B\u0E31\u0E08\u0E08\u0E38\u0E1A\u0E31\u0E19', btnChangeShortcut: '\u0E40\u0E1B\u0E25\u0E35\u0E48\u0E22\u0E19',
    shortcutRecording: '\u0E01\u0E14\u0E04\u0E35\u0E22\u0E4C\u0E25\u0E31\u0E14\u0E17\u0E35\u0E48\u0E15\u0E49\u0E2D\u0E07\u0E01\u0E32\u0E23...', shortcutCancel: '\u0E22\u0E01\u0E40\u0E25\u0E34\u0E01',
    optTh: '\u0E20\u0E32\u0E29\u0E32\u0E44\u0E17\u0E22', optEn: 'English',
    sectionACEnable: '\u0E01\u0E32\u0E23\u0E40\u0E1B\u0E34\u0E14\u0E43\u0E0A\u0E49\u0E07\u0E32\u0E19', lblACEnable: '\u0E40\u0E1B\u0E34\u0E14\u0E43\u0E0A\u0E49\u0E07\u0E32\u0E19 Auto-Correct',
    lblACDesc: '\u0E41\u0E01\u0E49\u0E44\u0E02\u0E02\u0E49\u0E2D\u0E04\u0E27\u0E32\u0E21\u0E2D\u0E31\u0E15\u0E42\u0E19\u0E21\u0E31\u0E15\u0E34\u0E17\u0E31\u0E19\u0E17\u0E35\u0E17\u0E35\u0E48\u0E1E\u0E34\u0E21\u0E1E\u0E4C\u0E1C\u0E34\u0E14\u0E20\u0E32\u0E29\u0E32',
    sectionACSettings: '\u0E15\u0E31\u0E49\u0E07\u0E04\u0E48\u0E32\u0E01\u0E32\u0E23\u0E41\u0E01\u0E49\u0E44\u0E02', lblDelay: '\u0E04\u0E27\u0E32\u0E21\u0E25\u0E48\u0E32\u0E0A\u0E49\u0E32 (ms)',
    lblDelayHint: '\u0E40\u0E27\u0E25\u0E32\u0E23\u0E2D\u0E01\u0E48\u0E2D\u0E19\u0E41\u0E01\u0E49\u0E44\u0E02\u0E2D\u0E31\u0E15\u0E42\u0E19\u0E21\u0E31\u0E15\u0E34 (0\u20131000 ms, 0 = \u0E43\u0E0A\u0E49\u0E04\u0E48\u0E32\u0E40\u0E23\u0E34\u0E48\u0E21\u0E15\u0E49\u0E19 300 ms)',
    lblMinChars: '\u0E08\u0E33\u0E19\u0E27\u0E19\u0E15\u0E31\u0E27\u0E2D\u0E31\u0E01\u0E29\u0E23\u0E02\u0E31\u0E49\u0E19\u0E15\u0E48\u0E33', lblMinCharsHint: '\u0E15\u0E49\u0E2D\u0E07\u0E1E\u0E34\u0E21\u0E1E\u0E4C\u0E2D\u0E22\u0E48\u0E32\u0E07\u0E19\u0E49\u0E2D\u0E22\u0E01\u0E35\u0E48\u0E15\u0E31\u0E27\u0E2D\u0E31\u0E01\u0E29\u0E23\u0E01\u0E48\u0E2D\u0E19\u0E08\u0E30\u0E40\u0E23\u0E34\u0E48\u0E21\u0E41\u0E01\u0E49\u0E44\u0E02\u0E2D\u0E31\u0E15\u0E42\u0E19\u0E21\u0E31\u0E15\u0E34',
    sectionExAdd: '\u0E40\u0E1E\u0E34\u0E48\u0E21\u0E04\u0E33', placeholder: '\u0E04\u0E33\u0E17\u0E35\u0E48\u0E44\u0E21\u0E48\u0E15\u0E49\u0E2D\u0E07\u0E01\u0E32\u0E23\u0E43\u0E2B\u0E49\u0E41\u0E1B\u0E25\u0E07', btnAdd: '\u0E40\u0E1E\u0E34\u0E48\u0E21',
    exHint: '\u0E1B\u0E49\u0E2D\u0E19\u0E04\u0E33\u0E17\u0E35\u0E48\u0E44\u0E21\u0E48\u0E15\u0E49\u0E2D\u0E07\u0E01\u0E32\u0E23\u0E43\u0E2B\u0E49 PimPid \u0E41\u0E1B\u0E25\u0E07 \u0E40\u0E0A\u0E48\u0E19 \u0E0A\u0E37\u0E48\u0E2D, \u0E41\u0E1A\u0E23\u0E19\u0E14\u0E4C, \u0E04\u0E33\u0E28\u0E31\u0E1E\u0E17\u0E4C\u0E40\u0E09\u0E1E\u0E32\u0E30',
    sectionExList: '\u0E23\u0E32\u0E22\u0E01\u0E32\u0E23 Exclude', exEmpty: '\u0E22\u0E31\u0E07\u0E44\u0E21\u0E48\u0E21\u0E35\u0E04\u0E33\u0E17\u0E35\u0E48 exclude',
    lblFloatButton: '\u0E41\u0E2A\u0E14\u0E07\u0E1B\u0E38\u0E48\u0E21\u0E25\u0E2D\u0E22',
    lblFloatButtonDesc: '\u0E41\u0E2A\u0E14\u0E07\u0E1B\u0E38\u0E48\u0E21\u0E25\u0E2D\u0E22\u0E1A\u0E19\u0E2B\u0E19\u0E49\u0E32\u0E08\u0E2D\u0E2A\u0E33\u0E2B\u0E23\u0E31\u0E1A\u0E41\u0E1B\u0E25\u0E07\u0E02\u0E49\u0E2D\u0E04\u0E27\u0E32\u0E21\u0E42\u0E14\u0E22\u0E44\u0E21\u0E48\u0E15\u0E49\u0E2D\u0E07\u0E43\u0E0A\u0E49\u0E04\u0E35\u0E22\u0E4C\u0E25\u0E31\u0E14',
    // Stats
    statsSummary: '\u0E2A\u0E23\u0E38\u0E1B', statsToday: '\u0E27\u0E31\u0E19\u0E19\u0E35\u0E49', statsTotal: '\u0E17\u0E31\u0E49\u0E07\u0E2B\u0E21\u0E14', statsTimes: '\u0E04\u0E23\u0E31\u0E49\u0E07',
    statsRecent: '\u0E41\u0E1B\u0E25\u0E07\u0E25\u0E48\u0E32\u0E2A\u0E38\u0E14', statsEmpty: '\u0E22\u0E31\u0E07\u0E44\u0E21\u0E48\u0E21\u0E35\u0E1B\u0E23\u0E30\u0E27\u0E31\u0E15\u0E34\u0E01\u0E32\u0E23\u0E41\u0E1B\u0E25\u0E07',
    statsClear: '\u0E25\u0E49\u0E32\u0E07\u0E1B\u0E23\u0E30\u0E27\u0E31\u0E15\u0E34', statsExport: '\u0E2A\u0E48\u0E07\u0E2D\u0E2D\u0E01 CSV',
    // Appearance
    appTheme: '\u0E18\u0E35\u0E21', appThemeAuto: '\u0E15\u0E32\u0E21\u0E23\u0E30\u0E1A\u0E1A', appThemeLight: '\u0E2A\u0E27\u0E48\u0E32\u0E07', appThemeDark: '\u0E21\u0E37\u0E14',
    appFont: '\u0E02\u0E19\u0E32\u0E14\u0E15\u0E31\u0E27\u0E2D\u0E31\u0E01\u0E29\u0E23', appFontSmall: '\u0E40\u0E25\u0E47\u0E01', appFontMedium: '\u0E01\u0E25\u0E32\u0E07',
    appFontLarge: '\u0E43\u0E2B\u0E0D\u0E48', appFontXL: '\u0E43\u0E2B\u0E0D\u0E48\u0E1E\u0E34\u0E40\u0E28\u0E29',
    btnClose: '\u0E1B\u0E34\u0E14', btnRemove: '\u0E25\u0E1A',
  },
  en: {
    title: 'PimPid',
    tabGeneral: 'General', tabAC: 'Auto-Correct', tabExclude: 'Exclude Words',
    tabStats: 'Statistics', tabAppearance: 'Appearance',
    sectionBasic: 'Basic Operation', lblEnable: 'Enable PimPid',
    lblEnableDesc: 'When enabled, PimPid runs in the background and is ready to convert text',
    lblLanguage: 'Display language', lblLangHint: 'Language changes immediately',
    lblShortcut: 'Current shortcut', btnChangeShortcut: 'Change',
    shortcutRecording: 'Press desired shortcut...', shortcutCancel: 'Cancel',
    optTh: 'Thai', optEn: 'English',
    sectionACEnable: 'Enable', lblACEnable: 'Enable Auto-Correct',
    lblACDesc: 'Automatically correct text when typing in the wrong language',
    sectionACSettings: 'Correction Settings', lblDelay: 'Delay (ms)',
    lblDelayHint: 'Wait time before auto-correcting (0-1000 ms, 0 = default 300 ms)',
    lblMinChars: 'Minimum characters', lblMinCharsHint: 'Minimum characters to type before auto-correction starts',
    sectionExAdd: 'Add Word', placeholder: 'Word to exclude from conversion', btnAdd: 'Add',
    exHint: "Enter words you don't want PimPid to convert (e.g. names, brands, jargon)",
    sectionExList: 'Exclude List', exEmpty: 'No excluded words yet',
    lblFloatButton: 'Show float button',
    lblFloatButtonDesc: 'Show a floating button on screen to convert text without using a shortcut',
    // Stats
    statsSummary: 'Summary', statsToday: 'Today', statsTotal: 'Total', statsTimes: 'times',
    statsRecent: 'Recent Conversions', statsEmpty: 'No conversion history yet',
    statsClear: 'Clear history', statsExport: 'Export CSV',
    // Appearance
    appTheme: 'Theme', appThemeAuto: 'Auto', appThemeLight: 'Light', appThemeDark: 'Dark',
    appFont: 'Font Size', appFontSmall: 'Small', appFontMedium: 'Medium',
    appFontLarge: 'Large', appFontXL: 'Extra Large',
    btnClose: 'Close', btnRemove: 'Remove',
  },
};

let lang = 'th';
let currentSettings = null;
let isRecordingShortcut = false;

function s(key) { return STRINGS[lang][key] ?? STRINGS['en'][key] ?? key; }

function applyLang() {
  // WCAG 3.1.1: Update document language
  document.documentElement.lang = lang;
  const L = s;
  document.title = L('title');
  document.getElementById('h-title').textContent = L('title');
  document.getElementById('tab-general').textContent = L('tabGeneral');
  document.getElementById('tab-autocorrect').textContent = L('tabAC');
  document.getElementById('tab-exclude').textContent = L('tabExclude');
  document.getElementById('tab-stats').textContent = L('tabStats');
  document.getElementById('tab-appearance').textContent = L('tabAppearance');
  document.getElementById('lbl-basic').textContent = L('sectionBasic');
  document.getElementById('lbl-language').textContent = L('lblLanguage');
  document.getElementById('lbl-language-hint').textContent = L('lblLangHint');
  document.getElementById('lbl-floatbutton').textContent = L('lblFloatButton');
  document.getElementById('lbl-floatbutton-desc').textContent = L('lblFloatButtonDesc');
  document.getElementById('lbl-shortcut').textContent = L('lblShortcut');
  document.getElementById('btn-change-shortcut').textContent = L('btnChangeShortcut');
  document.getElementById('opt-th').textContent = L('optTh');
  document.getElementById('opt-en').textContent = L('optEn');
  document.getElementById('lbl-ac-enable-section').textContent = L('sectionACEnable');
  document.getElementById('lbl-ac-enable').textContent = L('lblACEnable');
  document.getElementById('lbl-ac-desc').textContent = L('lblACDesc');
  document.getElementById('lbl-ac-settings-section').textContent = L('sectionACSettings');
  document.getElementById('lbl-ac-delay').textContent = L('lblDelay');
  document.getElementById('lbl-ac-delay-hint').textContent = L('lblDelayHint');
  document.getElementById('lbl-ac-minchars').textContent = L('lblMinChars');
  document.getElementById('lbl-ac-minchars-hint').textContent = L('lblMinCharsHint');
  document.getElementById('lbl-ex-add-section').textContent = L('sectionExAdd');
  document.getElementById('inp-word').placeholder = L('placeholder');
  document.getElementById('btn-add-word').textContent = L('btnAdd');
  document.getElementById('lbl-ex-hint').textContent = L('exHint');
  document.getElementById('lbl-ex-list-section').textContent = L('sectionExList');
  document.getElementById('lbl-ex-empty').textContent = L('exEmpty');
  // Stats
  document.getElementById('lbl-stats-summary').textContent = L('statsSummary');
  document.getElementById('lbl-stat-today').textContent = L('statsToday');
  document.getElementById('lbl-stat-total').textContent = L('statsTotal');
  document.getElementById('lbl-stats-recent').textContent = L('statsRecent');
  document.getElementById('lbl-stats-empty').textContent = L('statsEmpty');
  document.getElementById('btn-clear-stats').textContent = L('statsClear');
  document.getElementById('btn-export-stats').textContent = L('statsExport');
  // Appearance
  document.getElementById('lbl-app-theme-section').textContent = L('appTheme');
  document.getElementById('theme-auto').textContent = L('appThemeAuto');
  document.getElementById('theme-light').textContent = L('appThemeLight');
  document.getElementById('theme-dark').textContent = L('appThemeDark');
  document.getElementById('lbl-app-font-section').textContent = L('appFont');
  document.getElementById('font-small').textContent = L('appFontSmall');
  document.getElementById('font-medium').textContent = L('appFontMedium');
  document.getElementById('font-large').textContent = L('appFontLarge');
  document.getElementById('font-xl').textContent = L('appFontXL');
  // Footer
  document.getElementById('btn-close').textContent = L('btnClose');
}

function applySettings(settings) {
  currentSettings = settings;
  document.getElementById('chk-autocorrect').checked = settings.autoCorrectEnabled;
  document.getElementById('chk-floatbutton').checked = settings.showFloatButton || false;
  document.getElementById('sel-language').value = settings.language;
  document.getElementById('inp-delay').value = settings.autoCorrectDebounceMs;
  document.getElementById('inp-minchars').value = settings.autoCorrectMinChars;

  // Sync UI language whenever settings change
  if (settings.language && settings.language !== lang) {
    lang = settings.language;
    applyLang();
  }

  // Format shortcut display
  const shortcut = (settings.shortcut || 'CommandOrControl+Shift+L')
    .replace('CommandOrControl', 'Ctrl')
    .replace('Control', 'Ctrl')
    .replace('Command', 'Win')
    .replace(/\+/g, ' + ');
  document.getElementById('shortcut-display').textContent = shortcut;

  renderWordList(settings.excludeWords || []);

  // Apply theme
  applyTheme(settings.theme || 'auto');
  applyFontSize(settings.fontSize || 'medium');
}

// ─── Theme management ─────────────────────────────────────────────────────────
function applyTheme(theme) {
  const html = document.documentElement;
  html.classList.remove('theme-light', 'theme-dark');
  if (theme === 'light') html.classList.add('theme-light');
  else if (theme === 'dark') html.classList.add('theme-dark');
  // 'auto' = no class override, uses @media prefers-color-scheme

  // Update active state + ARIA
  document.querySelectorAll('.theme-opt').forEach(el => {
    const isActive = el.dataset.theme === theme;
    el.classList.toggle('active', isActive);
    el.setAttribute('aria-checked', String(isActive));
    el.setAttribute('tabindex', isActive ? '0' : '-1');
  });
}

function applyFontSize(size) {
  const html = document.documentElement;
  html.classList.remove('font-small', 'font-medium', 'font-large', 'font-xl');
  html.classList.add('font-' + size);

  document.querySelectorAll('.font-opt').forEach(el => {
    const isActive = el.dataset.size === size;
    el.classList.toggle('active', isActive);
    el.setAttribute('aria-checked', String(isActive));
    el.setAttribute('tabindex', isActive ? '0' : '-1');
  });
}

function renderWordList(words) {
  const list = document.getElementById('word-list');
  const emptyLabel = s('exEmpty');

  if (!words.length) {
    list.innerHTML = '';
    const emptyDiv = document.createElement('div');
    emptyDiv.className = 'word-empty';
    emptyDiv.id = 'lbl-ex-empty';
    emptyDiv.textContent = emptyLabel;
    list.appendChild(emptyDiv);
    return;
  }

  list.innerHTML = '';
  const fragment = document.createDocumentFragment();
  words.forEach((w, i) => {
    const row = document.createElement('div');
    row.className = 'word-row';

    const span = document.createElement('span');
    span.className = 'word-text';
    span.textContent = w;
    row.appendChild(span);

    const btn = document.createElement('button');
    btn.className = 'btn btn-icon';
    btn.dataset.index = String(i);
    btn.title = s('btnRemove');
    btn.innerHTML = '&#x2715;';
    btn.addEventListener('click', () => {
      const updatedWords = [...(currentSettings.excludeWords || [])];
      updatedWords.splice(i, 1);
      api.setSetting('excludeWords', updatedWords);
      currentSettings.excludeWords = updatedWords;
      renderWordList(updatedWords);
    });
    row.appendChild(btn);

    fragment.appendChild(row);
  });
  list.appendChild(fragment);
}

function escHtml(str) {
  return str.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

// ─── Stats rendering ─────────────────────────────────────────────────────────
async function loadStats() {
  try {
    const data = await api.getStats();
    const today = new Date().toISOString().slice(0, 10);
    const todayCount = (data.conversionStats.daily && data.conversionStats.daily[today]) || 0;
    document.getElementById('stat-today').textContent = String(todayCount);
    document.getElementById('stat-total').textContent = String(data.conversionStats.total || 0);
    renderRecentConversions(data.recentConversions || []);
  } catch (err) {
    console.error('Failed to load stats:', err);
  }
}

function renderRecentConversions(records) {
  const list = document.getElementById('recent-list');
  if (!records.length) {
    list.innerHTML = '';
    const emptyDiv = document.createElement('div');
    emptyDiv.className = 'word-empty';
    emptyDiv.id = 'lbl-stats-empty';
    emptyDiv.textContent = s('statsEmpty');
    list.appendChild(emptyDiv);
    return;
  }

  list.innerHTML = '';
  const fragment = document.createDocumentFragment();
  records.forEach(r => {
    const date = new Date(r.timestamp);
    const timeStr = date.toLocaleTimeString(lang === 'th' ? 'th-TH' : 'en-US', { hour: '2-digit', minute: '2-digit' });
    const dateStr = date.toLocaleDateString(lang === 'th' ? 'th-TH' : 'en-US', { month: 'short', day: 'numeric' });
    const dirLabel = r.direction === 'th_to_en' ? 'TH \u2192 EN' : 'EN \u2192 TH';

    const row = document.createElement('div');
    row.className = 'recent-row';

    const textDiv = document.createElement('div');
    textDiv.className = 'recent-text';
    textDiv.textContent = r.from + ' \u2192 ' + r.to;
    row.appendChild(textDiv);

    const metaDiv = document.createElement('div');
    metaDiv.className = 'recent-meta';

    const dirSpan = document.createElement('span');
    dirSpan.textContent = dirLabel;
    metaDiv.appendChild(dirSpan);

    const timeSpan = document.createElement('span');
    timeSpan.textContent = dateStr + ' ' + timeStr;
    metaDiv.appendChild(timeSpan);

    row.appendChild(metaDiv);
    fragment.appendChild(row);
  });
  list.appendChild(fragment);
}

// ─── Shortcut recording ──────────────────────────────────────────────────────
function startRecordingShortcut() {
  isRecordingShortcut = true;
  const editor = document.getElementById('shortcut-editor');
  editor.innerHTML = '';

  const recording = document.createElement('span');
  recording.className = 'shortcut-recording';
  recording.id = 'shortcut-recording';
  recording.textContent = s('shortcutRecording');
  editor.appendChild(recording);

  const cancelBtn = document.createElement('button');
  cancelBtn.className = 'btn btn-sm';
  cancelBtn.id = 'btn-cancel-shortcut';
  cancelBtn.textContent = s('shortcutCancel');
  cancelBtn.addEventListener('click', stopRecordingShortcut);
  editor.appendChild(cancelBtn);
}

function stopRecordingShortcut() {
  isRecordingShortcut = false;
  const editor = document.getElementById('shortcut-editor');
  const shortcut = (currentSettings.shortcut || 'CommandOrControl+Shift+L')
    .replace('CommandOrControl', 'Ctrl')
    .replace('Control', 'Ctrl')
    .replace('Command', 'Win')
    .replace(/\+/g, ' + ');

  editor.innerHTML = '';

  const chip = document.createElement('span');
  chip.className = 'shortcut-chip';
  chip.id = 'shortcut-display';
  chip.textContent = shortcut;
  editor.appendChild(chip);

  const changeBtn = document.createElement('button');
  changeBtn.className = 'btn btn-sm';
  changeBtn.id = 'btn-change-shortcut';
  changeBtn.textContent = s('btnChangeShortcut');
  changeBtn.addEventListener('click', startRecordingShortcut);
  editor.appendChild(changeBtn);
}

document.addEventListener('keydown', async (e) => {
  if (!isRecordingShortcut) return;
  e.preventDefault();
  e.stopPropagation();

  // Need at least one modifier
  if (!e.ctrlKey && !e.altKey && !e.shiftKey && !e.metaKey) return;
  // Don't accept modifier-only presses
  const modifierKeys = ['Control', 'Shift', 'Alt', 'Meta'];
  if (modifierKeys.includes(e.key)) return;

  // Build Electron accelerator string
  const parts = [];
  if (e.ctrlKey) parts.push('CommandOrControl');
  if (e.altKey) parts.push('Alt');
  if (e.shiftKey) parts.push('Shift');

  // Normalize key name
  let key = e.key;
  if (key.length === 1) key = key.toUpperCase();
  else if (key === 'ArrowUp') key = 'Up';
  else if (key === 'ArrowDown') key = 'Down';
  else if (key === 'ArrowLeft') key = 'Left';
  else if (key === 'ArrowRight') key = 'Right';
  else if (key === ' ') key = 'Space';

  parts.push(key);
  const accelerator = parts.join('+');

  // Show what user pressed
  const display = accelerator
    .replace('CommandOrControl', 'Ctrl')
    .replace(/\+/g, ' + ');
  const recording = document.getElementById('shortcut-recording');
  if (recording) recording.textContent = display;

  // Try to register
  const result = await api.changeShortcut(accelerator);
  if (result.success) {
    currentSettings.shortcut = accelerator;
  }
  stopRecordingShortcut();
});

// ─── Tab switching (WCAG 2.1.1 keyboard, 4.1.2 aria-selected) ─────────────────
function activateTab(tab) {
  const tabs = document.querySelectorAll('.tab');
  tabs.forEach(t => {
    t.classList.remove('active');
    t.setAttribute('aria-selected', 'false');
    t.setAttribute('tabindex', '-1');
  });
  document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
  tab.classList.add('active');
  tab.setAttribute('aria-selected', 'true');
  tab.setAttribute('tabindex', '0');
  tab.focus();
  document.getElementById('panel-' + tab.dataset.tab).classList.add('active');
  if (tab.dataset.tab === 'stats') loadStats();
}

document.querySelectorAll('.tab').forEach(tab => {
  tab.addEventListener('click', () => activateTab(tab));
  tab.addEventListener('keydown', (e) => {
    const tabs = Array.from(document.querySelectorAll('.tab'));
    const idx = tabs.indexOf(tab);
    if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
      e.preventDefault();
      activateTab(tabs[(idx + 1) % tabs.length]);
    } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
      e.preventDefault();
      activateTab(tabs[(idx - 1 + tabs.length) % tabs.length]);
    } else if (e.key === 'Home') {
      e.preventDefault();
      activateTab(tabs[0]);
    } else if (e.key === 'End') {
      e.preventDefault();
      activateTab(tabs[tabs.length - 1]);
    }
  });
});

// ─── Control events ───────────────────────────────────────────────────────────
document.getElementById('chk-autocorrect').addEventListener('change', e => {
  api.setSetting('autoCorrectEnabled', e.target.checked);
});

document.getElementById('sel-language').addEventListener('change', e => {
  lang = e.target.value;
  api.setSetting('language', e.target.value);
  applyLang();
});

document.getElementById('chk-floatbutton').addEventListener('change', e => {
  api.setSetting('showFloatButton', e.target.checked);
});

document.getElementById('inp-delay').addEventListener('change', e => {
  const v = Math.max(0, Math.min(1000, parseInt(e.target.value, 10) || 0));
  e.target.value = v;
  api.setSetting('autoCorrectDebounceMs', v);
});

document.getElementById('inp-minchars').addEventListener('change', e => {
  const v = Math.max(1, Math.min(10, parseInt(e.target.value, 10) || 3));
  e.target.value = v;
  api.setSetting('autoCorrectMinChars', v);
});

// ─── Shortcut change button ─────────────────────────────────────────────────
document.getElementById('btn-change-shortcut').addEventListener('click', startRecordingShortcut);

// ─── Theme picker (WCAG keyboard + ARIA) ─────────────────────────────────────
document.querySelectorAll('.theme-opt').forEach(opt => {
  opt.addEventListener('click', () => {
    const theme = opt.dataset.theme;
    applyTheme(theme);
    api.setSetting('theme', theme);
    opt.focus();
  });
  opt.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      opt.click();
    }
    const opts = Array.from(document.querySelectorAll('.theme-opt'));
    const idx = opts.indexOf(opt);
    if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
      e.preventDefault();
      const next = opts[(idx + 1) % opts.length];
      next.click();
    } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
      e.preventDefault();
      const prev = opts[(idx - 1 + opts.length) % opts.length];
      prev.click();
    }
  });
});

// ─── Font size picker (WCAG keyboard + ARIA) ─────────────────────────────────
document.querySelectorAll('.font-opt').forEach(opt => {
  opt.addEventListener('click', () => {
    const size = opt.dataset.size;
    applyFontSize(size);
    api.setSetting('fontSize', size);
    opt.focus();
  });
  opt.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      opt.click();
    }
    const opts = Array.from(document.querySelectorAll('.font-opt'));
    const idx = opts.indexOf(opt);
    if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
      e.preventDefault();
      const next = opts[(idx + 1) % opts.length];
      next.click();
    } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
      e.preventDefault();
      const prev = opts[(idx - 1 + opts.length) % opts.length];
      prev.click();
    }
  });
});

// ─── Clear stats ──────────────────────────────────────────────────────────────
document.getElementById('btn-clear-stats').addEventListener('click', async () => {
  await api.clearStats();
  document.getElementById('stat-today').textContent = '0';
  document.getElementById('stat-total').textContent = '0';
  renderRecentConversions([]);
});

// ─── Export stats CSV ──────────────────────────────────────────────────────────
document.getElementById('btn-export-stats').addEventListener('click', async () => {
  const result = await api.exportStats();
  // No alert needed — save dialog is shown by main process
  if (result && !result.success && result.error === 'empty') {
    // Brief visual feedback — change button text momentarily
    const btn = document.getElementById('btn-export-stats');
    const original = btn.textContent;
    btn.textContent = s('statsEmpty') || 'No data';
    btn.disabled = true;
    setTimeout(() => {
      btn.textContent = original;
      btn.disabled = false;
    }, 1500);
  }
});

// ─── Exclude word add ─────────────────────────────────────────────────────────
function addWord() {
  const inp = document.getElementById('inp-word');
  const word = inp.value.trim();
  if (!word) return;
  const words = [...(currentSettings.excludeWords || [])];
  if (!words.includes(word)) {
    words.push(word);
    api.setSetting('excludeWords', words);
    currentSettings.excludeWords = words;
    renderWordList(words);
  }
  inp.value = '';
  inp.focus();
}

document.getElementById('btn-add-word').addEventListener('click', addWord);
document.getElementById('inp-word').addEventListener('keydown', e => {
  if (e.key === 'Enter') addWord();
});

// ─── Footer ───────────────────────────────────────────────────────────────────
document.getElementById('btn-close').addEventListener('click', () => {
  window.close();
});

// ─── Init ─────────────────────────────────────────────────────────────────────
async function init() {
  const [settings, langFromMain] = await Promise.all([
    api.getSettings(),
    api.getLang(),
  ]);
  lang = settings.language || langFromMain || 'th';
  applyLang();
  applySettings(settings);

  // Listen for live updates from main (e.g. tray menu toggle)
  api.onSettingsChanged(updated => {
    applySettings(updated);
  });
}

init().catch(console.error);

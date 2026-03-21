# PimPid -- Security Review (macOS + Windows)

**Date**: 2026-03-21
**Reviewer**: Application Security Engineer
**Scope**: All source files for macOS (Swift) and Windows (Electron/TypeScript)

## Summary

- **Risk Level**: Medium
- **Issues Found**: 12 (0 Critical, 2 High, 6 Medium, 4 Low)
- **Passed Checks**: 18

PimPid is a desktop keyboard layout converter (Thai / English). It is NOT a web application and does NOT handle passwords, API keys, payment data, or network communication. The attack surface is local-only. The primary security concerns are: (1) Electron IPC and renderer security, (2) PowerShell command execution, (3) clipboard data handling, and (4) global keylogging via keyboard hooks.

---

## Findings

### [HIGH-1] Missing `sandbox: true` on all BrowserWindow webPreferences (Windows/Electron)

- **Location**: `windows/src/main.ts:65-68`, `windows/src/main.ts:358-361`, `windows/src/main.ts:402-405`, `windows/src/main.ts:444-447`
- **Description**: All four BrowserWindow instances (toast, onboarding, float, settings) have `contextIsolation: true` and `nodeIntegration: false` (good), but none explicitly set `sandbox: true`. In Electron 33+, sandbox defaults to `false` when a preload script is specified. Without sandboxing, a compromised renderer has broader access to system resources.
- **Impact**: If an attacker can somehow inject code into the renderer (e.g., via a future feature loading external content), the lack of sandbox gives the renderer more capabilities than necessary.
- **Recommendation**: Add `sandbox: true` to all BrowserWindow webPreferences. Preload scripts work normally with sandbox enabled since Electron 20.

```typescript
// before
webPreferences: {
  preload: path.join(__dirname, "toast-preload.js"),
  contextIsolation: true,
  nodeIntegration: false,
}

// after
webPreferences: {
  preload: path.join(__dirname, "toast-preload.js"),
  contextIsolation: true,
  nodeIntegration: false,
  sandbox: true,
}
```

### [HIGH-2] `unsafe-inline` in Content-Security-Policy on all HTML files (Windows/Electron)

- **Location**: `windows/src/settings.html:5-6`, `windows/src/onboarding.html:5-6`, `windows/src/toast.html:5-6`, `windows/src/float-button.html:5-6`
- **Description**: All HTML files use `script-src 'self' 'unsafe-inline'` and `style-src 'self' 'unsafe-inline'`. The `unsafe-inline` for scripts significantly weakens CSP because it allows inline `<script>` tags to execute. While all four HTML files currently use inline scripts, this is an Electron local file app with no external content loading, so the practical risk is moderate. However, `unsafe-inline` defeats the purpose of having CSP for script injection defense.
- **Impact**: If a DOM-based XSS vulnerability were introduced (currently none found), `unsafe-inline` would allow injected scripts to execute.
- **Recommendation**: Move all inline `<script>` blocks into separate `.js` files and remove `'unsafe-inline'` from `script-src`. For styles, `'unsafe-inline'` is acceptable since inline styles pose minimal security risk.

```html
<!-- before -->
<meta http-equiv="Content-Security-Policy"
  content="default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'" />

<!-- after -->
<meta http-equiv="Content-Security-Policy"
  content="default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'" />
<!-- + move <script> contents to settings-renderer.js, onboarding-renderer.js, etc. -->
```

### [MEDIUM-1] No input validation on `autoCorrectDebounceMs` and `autoCorrectMinChars` in IPC handler (Windows)

- **Location**: `windows/src/main.ts:504-511`
- **Description**: When `settings:set` receives `autoCorrectDebounceMs` or `autoCorrectMinChars`, the value is cast with `as number` and passed directly to the store and engine without validating it is actually a number, or within a reasonable range. A renderer could send a string, negative number, NaN, or extremely large value.
- **Impact**: Could cause unexpected behavior: extremely high debounce (app appears frozen), zero/negative minChars (excessive corrections), or NaN crashing downstream logic.
- **Recommendation**: Validate type and range before accepting.

```typescript
// before
case "autoCorrectDebounceMs":
  store.set("autoCorrectDebounceMs", value as number);
  updateAutoCorrectConfig({ debounceMs: value as number });
  break;

// after
case "autoCorrectDebounceMs": {
  const n = Number(value);
  if (!Number.isFinite(n)) break;
  const clamped = Math.max(0, Math.min(1000, Math.round(n)));
  store.set("autoCorrectDebounceMs", clamped);
  updateAutoCorrectConfig({ debounceMs: clamped });
  break;
}

case "autoCorrectMinChars": {
  const n = Number(value);
  if (!Number.isFinite(n)) break;
  const clamped = Math.max(1, Math.min(10, Math.round(n)));
  store.set("autoCorrectMinChars", clamped);
  updateAutoCorrectConfig({ minBufferLength: clamped });
  break;
}
```

### [MEDIUM-2] No validation on `excludeWords` array contents in IPC handler (Windows)

- **Location**: `windows/src/main.ts:514-516`
- **Description**: The `excludeWords` value is accepted as `string[]` without verifying that it is actually an array of strings. A malicious renderer could send an array containing objects, numbers, or extremely long strings, which would be persisted to disk and could cause issues.
- **Impact**: Corrupted settings file, potential memory issues with very large arrays, unexpected behavior in downstream comparisons.
- **Recommendation**: Validate the array and its contents.

```typescript
// after
case "excludeWords": {
  if (!Array.isArray(value)) break;
  const words = value
    .filter((w): w is string => typeof w === "string")
    .map(w => w.trim().slice(0, 100))  // limit word length
    .filter(w => w.length > 0)
    .slice(0, 500);  // limit total count
  store.set("excludeWords", words);
  setExcludeWords(words);
  break;
}
```

### [MEDIUM-3] No validation on `shortcut` in `shortcut:change` IPC handler (Windows)

- **Location**: `windows/src/main.ts:550-571`
- **Description**: The `shortcut:change` handler validates that the shortcut is a non-empty string with at least one `+` separator, but does not validate the individual parts are valid Electron accelerator components. Invalid or dangerous shortcuts (e.g., system-reserved keys) could be registered.
- **Impact**: Could register shortcuts that conflict with system shortcuts, or cause `globalShortcut.register` to throw unexpected errors.
- **Recommendation**: Add a whitelist of valid modifier keys and validate the key component.

```typescript
// after
ipcMain.handle("shortcut:change", (_event, newShortcut: string) => {
  if (typeof newShortcut !== "string" || newShortcut.length === 0 || newShortcut.length > 50) {
    return { success: false, error: "Invalid shortcut" };
  }

  const parts = newShortcut.split("+");
  if (parts.length < 2 || parts.length > 4) {
    return { success: false, error: "Shortcut must include a modifier key" };
  }

  const validModifiers = new Set(["CommandOrControl", "Control", "Alt", "Shift", "Command", "Super"]);
  const modifiers = parts.slice(0, -1);
  const key = parts[parts.length - 1];

  if (!modifiers.every(m => validModifiers.has(m))) {
    return { success: false, error: "Invalid modifier key" };
  }
  if (!key || key.length === 0 || key.length > 20) {
    return { success: false, error: "Invalid key" };
  }

  // ... rest of registration logic
});
```

### [MEDIUM-4] Clipboard race condition window in `convertSelectedText` (Windows)

- **Location**: `windows/src/main.ts:240-290`
- **Description**: The function saves the clipboard, clears it, simulates Ctrl+C, waits 200ms, reads the clipboard, then later simulates Ctrl+V and waits 400ms before restoring. During this ~600ms+ window, any other application writing to the clipboard can cause data loss. The same issue exists in `auto-correction.ts:562-582` with a 600ms restore delay.
- **Impact**: User clipboard data can be lost if another app writes to clipboard during the conversion window. This is a known limitation of clipboard-based text manipulation and is inherent to the design.
- **Recommendation**: This is a design limitation rather than a vulnerability. The current approach (save/restore) is the standard pattern. Consider documenting this behavior for users. The macOS version (`TextManipulator.swift`) uses a custom `NSPasteboard` (named pasteboard) for backup which is slightly more robust -- consider a similar approach for Windows if Electron supports it.

### [MEDIUM-5] Store file written as plain JSON without file permissions restriction (Windows)

- **Location**: `windows/src/store.ts:68-76`
- **Description**: Settings are saved to `userData/pimpid-settings.json` using `fs.writeFileSync` with default permissions. On Windows, files in `%APPDATA%` are generally protected by user-level ACLs, but the file is readable by any process running as the same user. The file contains conversion history (`recentConversions`) which includes the text the user typed.
- **Impact**: Another local application running as the same user can read the user's recent conversion history (typed text). This is a low-risk privacy concern since local access is already assumed compromised in most threat models.
- **Recommendation**: For defense in depth, consider using Electron's `safeStorage` API to encrypt sensitive fields, or at minimum document that conversion history is stored in plain text.

### [MEDIUM-6] Global keyboard hook captures all keystrokes (both platforms)

- **Location**: `windows/src/auto-correction.ts:132-138` (uiohook-napi), `macos/PimPid/Core/Services/AutoCorrectionEngine.swift:90-101` (CGEventTap)
- **Description**: When auto-correction is enabled, the app installs a global keyboard hook that captures ALL keystrokes system-wide. The captured keystrokes are buffered in `wordBuffer` (up to 50 chars on Windows, 64 on macOS). While the buffer is cleared frequently and only processes word-length segments, this is fundamentally a keylogger capability.
- **Impact**: If the app were compromised (supply chain attack on dependencies, or malicious code injection), the keylogger infrastructure is already in place. Additionally, the buffer transiently holds whatever the user types, including passwords in terminal windows.
- **Recommendation**: This is inherent to the app's design and purpose. Current mitigations are adequate:
  - Buffer is bounded (50/64 chars) and cleared on word boundaries
  - Buffer content is not logged or persisted (only converted output is logged/persisted)
  - Processing lock and rate limiting prevent abuse
  - macOS requires explicit Accessibility permission from the user
  - **Additional**: Consider adding a note in the app's privacy policy / README that the app captures keystrokes when auto-correct is enabled. Consider excluding password fields if detectable.

### [LOW-1] `innerHTML` usage in settings.html with user data (Windows)

- **Location**: `windows/src/settings.html:788,792,832,836,857,873`
- **Description**: Multiple places use `innerHTML` to render dynamic content. However, the code properly uses the `escHtml()` function (line 811-813) to escape user-provided data (`r.from`, `r.to`, word text). The `emptyLabel` from `s('exEmpty')` and other i18n strings come from hardcoded STRINGS objects, not user input. The `dirLabel` in `renderRecentConversions` uses a hardcoded HTML entity, not user data.
- **Impact**: Currently safe because `escHtml()` is consistently used for user data. However, `innerHTML` is a fragile pattern -- future changes could introduce XSS if escaping is missed.
- **Recommendation**: Consider using DOM APIs (`createElement`, `textContent`) instead of `innerHTML` for a more robust approach. This is defense-in-depth rather than fixing a current vulnerability.

### [LOW-2] PowerShell execution uses hardcoded scripts only (Windows)

- **Location**: `windows/src/main.ts:293-311`, `windows/src/auto-correction.ts:572-596`, `windows/src/auto-correction.ts:649-687`
- **Description**: Three locations execute PowerShell commands. All use `-EncodedCommand` with base64-encoded scripts. The scripts are entirely hardcoded strings -- no user input is interpolated into the PowerShell scripts. The `sendKeysArg` in `auto-correction.ts:570` uses `deleteCount` which is derived from `Math.min(word.length, MAX_DELETE_COUNT)`, and the `newText` is placed into clipboard (not into the PS script).
- **Impact**: No command injection risk in current code. The `{BS N}^v` format in SendKeys is safe because N is a bounded integer.
- **Recommendation**: Current implementation is secure. Maintain the practice of never interpolating user input into PowerShell scripts. Add a code comment marking these sections as security-sensitive.

### [LOW-3] No rate limiting on IPC handlers (Windows)

- **Location**: `windows/src/main.ts:472-655`
- **Description**: IPC handlers like `settings:set`, `stats:clear`, `stats:export` have no rate limiting. A compromised renderer could call these rapidly.
- **Impact**: Minimal practical impact since renderers are local and trusted. Rapid `settings:set` calls could cause excessive disk writes. Rapid `stats:export` could open many save dialogs.
- **Recommendation**: Low priority. Consider adding a simple debounce on `settings:set` to batch disk writes.

### [LOW-4] macOS: UserDefaults stores conversion history as plain data

- **Location**: `macos/PimPid/Core/Services/ConversionStats.swift:169-180`
- **Description**: Conversion records (original text, converted text, timestamps) are stored in UserDefaults as JSON-encoded data. UserDefaults on macOS is stored as a plist file in `~/Library/Preferences/` readable by the same user.
- **Impact**: Same as MEDIUM-5 -- another process running as the same user can read conversion history. On macOS, UserDefaults is somewhat more accessible than Windows AppData because various tools can easily read plists.
- **Recommendation**: Consider using Keychain for sensitive data, or at minimum limit the `maxRecentCount` (currently 10, which is reasonable) and truncate long text in records.

---

## Passed Checks

| # | Check | Status | Notes |
|---|-------|--------|-------|
| 1 | `nodeIntegration: false` | PASS | All 4 BrowserWindows correctly set `nodeIntegration: false` |
| 2 | `contextIsolation: true` | PASS | All 4 BrowserWindows correctly set `contextIsolation: true` |
| 3 | Preload scripts use `contextBridge` | PASS | All 4 preload scripts correctly use `contextBridge.exposeInMainWorld()` |
| 4 | No `remote` module usage | PASS | No usage of deprecated `@electron/remote` |
| 5 | IPC key whitelist (prototype pollution) | PASS | `settings:set` uses `VALID_KEYS` Set to whitelist allowed keys |
| 6 | XSS in toast.html | PASS | Uses `.textContent` for all user data (lines 147-149) |
| 7 | XSS in onboarding.html | PASS | Uses `.textContent` for all strings; no user data displayed |
| 8 | XSS in settings.html | PASS | Uses `escHtml()` for user data in `innerHTML` contexts |
| 9 | XSS in float-button.html | PASS | No dynamic content rendered |
| 10 | No external URL loading | PASS | All windows load local files only (`loadFile`) |
| 11 | No `shell.openExternal` with user input | PASS | No usage of `shell.openExternal` |
| 12 | `float:drag-move` input validation | PASS | Validates `dx`/`dy` are finite numbers (main.ts:610-611) |
| 13 | CSV export uses save dialog | PASS | `dialog.showSaveDialog` lets user choose path; no path traversal possible |
| 14 | CSV export escapes values | PASS | `csvEscape()` properly handles commas, quotes, newlines |
| 15 | Buffer overflow protection | PASS | Both platforms limit word buffer (Win: 50, macOS: 64) |
| 16 | macOS Accessibility permission check | PASS | Checks `AXIsProcessTrustedWithOptions` before creating event tap |
| 17 | macOS thread safety | PASS | `AutoCorrectionEngine` uses `os_unfair_lock` for all shared state |
| 18 | No hardcoded secrets | PASS | No API keys, tokens, or credentials in source code |

---

## Threat Model

### Assets
1. **User keystrokes** -- captured in buffer when auto-correct is on
2. **Clipboard contents** -- temporarily read/modified during conversion
3. **Conversion history** -- stored on disk (recent conversions, daily stats)
4. **Settings** -- stored on disk (preferences, exclude words)

### Threats
1. **Local attacker (same user)** -- can read settings/history files, intercept clipboard
2. **Supply chain attack** -- compromised npm dependency (especially `uiohook-napi`) could exfiltrate keystrokes
3. **Malicious Electron renderer** -- if renderer is compromised, IPC handlers are the attack surface

### Mitigations in Place
- Context isolation and no node integration in renderers
- IPC key whitelist preventing prototype pollution
- PowerShell scripts are hardcoded, not interpolated
- Buffer is bounded and cleared frequently
- macOS requires explicit Accessibility permission

### Recommendations Priority

| Priority | Action | Effort |
|----------|--------|--------|
| 1 | Add `sandbox: true` to all BrowserWindow webPreferences | 5 min |
| 2 | Add input validation for numeric/array IPC values | 15 min |
| 3 | Move inline scripts to separate files, remove `'unsafe-inline'` from CSP | 30 min |
| 4 | Add shortcut format validation | 10 min |
| 5 | Document privacy implications of keystroke capture | 10 min |
| 6 | Consider encrypting conversion history on disk | 1 hr |

---

## Checklist

- [x] No `nodeIntegration: true` -- all windows use `false`
- [x] `contextIsolation: true` -- all windows use `true`
- [x] No prototype pollution -- IPC key whitelist in place
- [x] No command injection -- PowerShell scripts are hardcoded
- [x] No XSS -- `textContent` and `escHtml()` used consistently
- [x] No external content loading -- all files are local
- [ ] `sandbox: true` -- NOT set, should be added
- [ ] CSP without `unsafe-inline` -- inline scripts should be extracted
- [ ] Input validation on all IPC numeric values -- missing for debounce/minChars
- [ ] Input validation on IPC array values -- missing for excludeWords
- [x] Buffer overflow protection -- bounded buffers on both platforms
- [x] Thread safety -- proper locking on macOS
- [x] Rate limiting on auto-correction -- 500ms cooldown in place
- [x] Clipboard restore -- implemented on both platforms
- [x] No sensitive data hardcoded -- no secrets in code
- [x] No network requests -- fully offline app

---

## NSSpellChecker Privacy Note (macOS)

- **Location**: `macos/PimPid/Core/Services/ConversionValidator.swift:174-188`
- **Description**: The app uses `NSSpellChecker.shared.checkSpelling(of:)` to validate English words. NSSpellChecker performs spell checking locally on macOS using the built-in dictionary. It does NOT send data to Apple servers unless the user has explicitly enabled "Check spelling while typing" with cloud-based suggestions in System Settings. The app uses `checkSpelling(of:)` directly (not `requestChecking(of:completionHandler:)`) which is the synchronous local-only API.
- **Conclusion**: No privacy concern with current usage.

import Foundation
import CoreGraphics
import AppKit
import os

/// เครื่องมือแก้ไขอัตโนมัติแบบ real-time ใช้ CGEventTap ตรวจจับการพิมพ์และแปลงทันที
/// แก้คำอัตโนมัติเมื่อหยุดพิมพ์ โดยใช้ debounce ตามค่า delay ที่ตั้งไว้ (default 200ms)
final class AutoCorrectionEngine {
    static let shared = AutoCorrectionEngine()

    // MARK: - Properties

    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private var _lock = os_unfair_lock()
    private var _wordBuffer: String = ""
    private var _isProcessing: Bool = false
    private var _isRunning: Bool = false
    private var _debounceWorkItem: DispatchWorkItem?

    private let replacementQueue = DispatchQueue(label: "com.pimpid.autocorrect.replacement")

    /// จำนวนตัวอักษรขั้นต่ำก่อนจะเริ่มตรวจ
    private let minBufferLength = 3

    /// Default debounce ถ้า user ไม่ได้ตั้ง delay (200ms)
    private let defaultDebounce: TimeInterval = 0.2

    var isRunning: Bool {
        os_unfair_lock_lock(&_lock)
        defer { os_unfair_lock_unlock(&_lock) }
        return _isRunning
    }

    /// อ่านค่า delay จาก settings — ถ้า 0 ใช้ default debounce
    private var currentDebounce: TimeInterval {
        let userDelay = UserDefaults.standard.double(forKey: PimPidKeys.autoCorrectDelay)
        // userDelay is in ms from settings, convert to seconds
        let delaySec = userDelay / 1000.0
        return max(defaultDebounce, delaySec)
    }

    // Whitespace = word boundary
    private let wordBreakers: Set<Character> = [" ", "\n", "\r", "\t"]

    // Navigation keycodes that clear the buffer
    private let navigationKeyCodes: Set<UInt16> = [
        0x7B, 0x7C, 0x7D, 0x7E, // arrow keys
        0x35,                     // escape
        0x24,                     // return
        0x4C,                     // enter (numpad)
        0x30,                     // tab
        0x73, 0x77,              // home, end
        0x74, 0x79,              // page up, page down
    ]

    private init() {}

    // MARK: - Start / Stop

    func start() {
        os_unfair_lock_lock(&_lock)
        if _isRunning {
            os_unfair_lock_unlock(&_lock)
            return
        }
        os_unfair_lock_unlock(&_lock)

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            print("[AutoCorrect] Accessibility permission not granted")
            return
        }

        let eventMask = (1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: autoCorrectionCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("[AutoCorrect] Failed to create event tap")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        os_unfair_lock_lock(&_lock)
        _isRunning = true
        os_unfair_lock_unlock(&_lock)

        print("[AutoCorrect] Started (minChars=\(minBufferLength))")
    }

    func stop() {
        os_unfair_lock_lock(&_lock)
        guard _isRunning else {
            os_unfair_lock_unlock(&_lock)
            return
        }
        _isRunning = false
        _wordBuffer = ""
        _isProcessing = false
        _debounceWorkItem?.cancel()
        _debounceWorkItem = nil
        os_unfair_lock_unlock(&_lock)

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
        }

        print("[AutoCorrect] Stopped")
    }

    // MARK: - Event Handling

    func handleKeyEvent(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        os_unfair_lock_lock(&_lock)
        if _isProcessing {
            os_unfair_lock_unlock(&_lock)
            return Unmanaged.passUnretained(event)
        }
        os_unfair_lock_unlock(&_lock)

        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        // Modifier keys → clear
        if flags.contains(.maskCommand) || flags.contains(.maskControl) || flags.contains(.maskAlternate) {
            cancelAndClear()
            return Unmanaged.passUnretained(event)
        }

        // Navigation keys → clear
        if navigationKeyCodes.contains(keyCode) {
            cancelAndClear()
            return Unmanaged.passUnretained(event)
        }

        // Get character
        var length = 0
        event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &length, unicodeString: nil)
        guard length > 0 else { return Unmanaged.passUnretained(event) }

        var chars = [UniChar](repeating: 0, count: length)
        event.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: &chars)
        guard let character = String(utf16CodeUnits: chars, count: length).first else {
            return Unmanaged.passUnretained(event)
        }

        // Backspace → shrink buffer, cancel debounce
        if keyCode == 0x33 {
            os_unfair_lock_lock(&_lock)
            if !_wordBuffer.isEmpty { _wordBuffer.removeLast() }
            _debounceWorkItem?.cancel()
            _debounceWorkItem = nil
            os_unfair_lock_unlock(&_lock)
            return Unmanaged.passUnretained(event)
        }

        // Word breaker (space etc.) → clear
        if wordBreakers.contains(character) {
            cancelAndClear()
            return Unmanaged.passUnretained(event)
        }

        // Regular character → append + schedule debounce
        os_unfair_lock_lock(&_lock)
        _wordBuffer.append(character)
        let buf = _wordBuffer
        os_unfair_lock_unlock(&_lock)

        scheduleDebounce(buf)
        return Unmanaged.passUnretained(event)
    }

    // MARK: - Debounce

    private func cancelAndClear() {
        os_unfair_lock_lock(&_lock)
        _wordBuffer = ""
        _debounceWorkItem?.cancel()
        _debounceWorkItem = nil
        os_unfair_lock_unlock(&_lock)
    }

    private func scheduleDebounce(_ buffer: String) {
        os_unfair_lock_lock(&_lock)
        _debounceWorkItem?.cancel()

        guard buffer.unicodeScalars.count >= minBufferLength else {
            _debounceWorkItem = nil
            os_unfair_lock_unlock(&_lock)
            return
        }

        let item = DispatchWorkItem { [weak self] in
            self?.onDebounce()
        }
        _debounceWorkItem = item
        os_unfair_lock_unlock(&_lock)

        replacementQueue.asyncAfter(deadline: .now() + currentDebounce, execute: item)
    }

    private func onDebounce() {
        os_unfair_lock_lock(&_lock)
        if _isProcessing || _wordBuffer.isEmpty {
            os_unfair_lock_unlock(&_lock)
            return
        }
        let word = _wordBuffer
        os_unfair_lock_unlock(&_lock)

        // Check if replacement needed
        guard let info = checkReplacement(word) else { return }

        // Lock, verify buffer unchanged, set processing
        os_unfair_lock_lock(&_lock)
        if _wordBuffer != word {
            os_unfair_lock_unlock(&_lock)
            return
        }
        _wordBuffer = ""
        _isProcessing = true
        os_unfair_lock_unlock(&_lock)

        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let deleteCount = trimmed.unicodeScalars.count

        print("[AutoCorrect] \"\(trimmed)\" → \"\(info.converted)\"")

        // Perform replacement (still on replacementQueue)
        TextManipulator.replaceWithClipboard(deleteCount: deleteCount, text: info.converted)

        // Wait for paste to complete (ลดจาก 50ms เพื่อไม่ให้รู้สึกค้าง)
        usleep(25000) // 25ms

        // Switch keyboard + stats on main thread (Carbon API requires main thread)
        let direction = info.direction
        let converted = info.converted
        let playSound = UserDefaults.standard.bool(forKey: PimPidKeys.autoCorrectSoundEnabled)
        let statsDir: ConversionDirection = direction == .thaiToEnglish ? .thaiToEnglish : .englishToThai

        DispatchQueue.main.async { [weak self] in
            // Switch keyboard layout (must be on main thread)
            switch direction {
            case .thaiToEnglish:
                InputSourceSwitcher.switchTo(.english)
            case .englishToThai:
                InputSourceSwitcher.switchTo(.thai)
            case .none:
                break
            }

            ConversionStats.shared.recordConversion(from: trimmed, to: converted, direction: statsDir)
            if playSound {
                NSSound.beep()
            }

            // Clear processing flag AFTER main thread work is done
            guard let self = self else { return }
            os_unfair_lock_lock(&self._lock)
            self._isProcessing = false
            os_unfair_lock_unlock(&self._lock)
        }
    }

    // MARK: - Helpers

    private struct ReplacementInfo {
        let converted: String
        let direction: KeyboardLayoutConverter.ConversionDirection
    }

    private func checkReplacement(_ word: String) -> ReplacementInfo? {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let excludeWords = Set(
            (UserDefaults.standard.stringArray(forKey: PimPidKeys.excludeWords) ?? [])
                .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        )
        if excludeWords.contains(trimmed.lowercased()) { return nil }
        if isCurrentAppExcluded() { return nil }

        let direction = KeyboardLayoutConverter.dominantLanguage(trimmed)
        guard direction != .none else { return nil }

        let converted = KeyboardLayoutConverter.convertAuto(trimmed)
        guard converted != trimmed else { return nil }

        var shouldReplace = false
        DispatchQueue.main.sync {
            shouldReplace = ConversionValidator.shouldReplace(converted: converted, direction: direction, original: trimmed)
        }
        guard shouldReplace else { return nil }

        return ReplacementInfo(converted: converted, direction: direction)
    }

    private func isCurrentAppExcluded() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let bundleID = frontApp.bundleIdentifier else { return false }
        let excludedApps = Set(UserDefaults.standard.stringArray(forKey: PimPidKeys.autoCorrectExcludedApps) ?? [])
        return excludedApps.contains(bundleID)
    }
}

// MARK: - CGEventTap Callback

private func autoCorrectionCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else { return Unmanaged.passUnretained(event) }

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        let engine = Unmanaged<AutoCorrectionEngine>.fromOpaque(refcon).takeUnretainedValue()
        if let tap = engine.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        print("[AutoCorrect] Event tap re-enabled")
        return Unmanaged.passUnretained(event)
    }

    guard type == .keyDown else { return Unmanaged.passUnretained(event) }

    let engine = Unmanaged<AutoCorrectionEngine>.fromOpaque(refcon).takeUnretainedValue()
    return engine.handleKeyEvent(event)
}

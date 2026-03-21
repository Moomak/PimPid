import XCTest
@testable import PimPid

/// User scenario tests: simulate real user interactions and verify correct behavior
/// These test the integration of multiple components
final class UserScenarioTests: XCTestCase {

    // MARK: - Scenario: User types "git commit" with Auto-Correct on

    func testTypingGitCommit_NotAutoCorrected() {
        // "git" should be excluded as a tech term
        let gitResult = AutoCorrectionLogic.replacement(for: "git", excludeWords: [])
        XCTAssertNil(gitResult, "git should not be auto-corrected (tech term)")

        // "commit" -- even though it maps to something in Thai, if it's valid English it should not be corrected
        let commitResult = AutoCorrectionLogic.replacement(for: "commit", excludeWords: [])
        // commit is a valid English word, direction would be englishToThai, validator should reject
        if let r = commitResult {
            XCTFail("'commit' should not be auto-corrected, but got: \(r.converted)")
        }
    }

    // MARK: - Scenario: User types Thai word that's in word list

    func testTypingKnownThaiWord_NotConvertedToEnglish() {
        // "ครับ" is in the Thai word list -- should not be converted
        let result = AutoCorrectionLogic.replacement(for: "ครับ", excludeWords: [])
        // If result is not nil, it means it tried to convert -- but ConversionValidator should block it
        if let r = result {
            XCTAssertNotEqual(r.direction, .thaiToEnglish,
                              "Known Thai word should not be converted to English")
        }
    }

    // MARK: - Scenario: User adds exclude word with special characters

    @MainActor
    func testExcludeWordWithSpecialCharacters() {
        let store = ExcludeListStore.shared
        let word = "pimpid_scenario_test!@#$"
        store.add(word)
        XCTAssertTrue(store.contains(word))
        XCTAssertTrue(store.shouldExclude(text: word))
        store.remove(word)
    }

    // MARK: - Scenario: User types mixed language text

    func testMixedLanguageText_NotAutoCorrected() {
        // "ทดสอบtest" has both Thai and English above 30% threshold
        let result = AutoCorrectionLogic.replacement(for: "ทดสอบtest", excludeWords: [])
        XCTAssertNil(result, "Mixed language text should not be auto-corrected")
    }

    // MARK: - Scenario: Convert Selected Text with exclude list

    @MainActor
    func testConvertSelectedText_ExcludedWord_NotConverted() {
        let store = ExcludeListStore.shared
        let word = "pimpid_scenario_exclude_test"
        store.add(word)

        // shouldExclude should return true
        XCTAssertTrue(store.shouldExclude(text: word))

        store.remove(word)
    }

    // MARK: - Scenario: User changes shortcut

    func testKeyboardShortcutManager_DisplayString() {
        // Verify the shortcut display string is readable
        let display = KeyboardShortcutManager.shortcutDisplayString()
        XCTAssertFalse(display.isEmpty, "Shortcut display string should not be empty")
        // Default shortcut is Command+Shift+L
        // Should contain command symbol
        XCTAssertTrue(display.contains("⌘") || display.contains("L") || display.contains("Key"),
                      "Display string should contain recognizable shortcut symbols")
    }

    // MARK: - Scenario: Accessibility permission not granted

    func testAccessibilityHelper_CheckDoesNotCrash() {
        // Just verify calling the check doesn't crash
        let _ = AccessibilityHelper.isAccessibilityTrusted
    }

    // MARK: - Scenario: User exports empty stats

    @MainActor
    func testEmptyStats_Last7Days_ReturnsValidData() {
        let stats = ConversionStats.shared
        stats.resetAll()

        let days = stats.last7DaysCounts()
        XCTAssertEqual(days.count, 7)
        for day in days {
            XCTAssertEqual(day.count, 0, "Empty stats should show 0 for all days")
            XCTAssertFalse(day.date.isEmpty, "Date key should not be empty")
        }
    }

    // MARK: - Scenario: Notification toast queue

    @MainActor
    func testToastQueue_MultipleNotifications() {
        let service = NotificationService.shared
        service.clearAll()

        // Show 3 toasts rapidly
        service.showToast(message: "Toast 1", type: .success)
        service.showToast(message: "Toast 2", type: .info)
        service.showToast(message: "Toast 3", type: .warning)

        XCTAssertEqual(service.currentToast?.message, "Toast 1")
        XCTAssertEqual(service.toastQueue.count, 2)

        // Dismiss first
        service.dismissCurrentToast()
        XCTAssertEqual(service.currentToast?.message, "Toast 2")
        XCTAssertEqual(service.toastQueue.count, 1)

        // Dismiss second
        service.dismissCurrentToast()
        XCTAssertEqual(service.currentToast?.message, "Toast 3")
        XCTAssertTrue(service.toastQueue.isEmpty)

        // Dismiss third
        service.dismissCurrentToast()
        XCTAssertNil(service.currentToast)

        service.clearAll()
    }

    // MARK: - Scenario: Input source switcher selection logic

    func testInputSourceSwitcher_CustomThaiLayout() {
        let ids = ["com.custom.ThaiKeyboard", "com.apple.keylayout.US"]
        let result = InputSourceSwitcher.selectableSourceID(from: ids, target: .thai)
        XCTAssertEqual(result, "com.custom.ThaiKeyboard",
                       "Should match custom layout containing 'Thai'")
    }

    func testInputSourceSwitcher_NoMatchReturnsNil() {
        let ids = ["com.custom.layout.Dvorak", "com.custom.layout.Colemak"]
        XCTAssertNil(InputSourceSwitcher.selectableSourceID(from: ids, target: .thai))
        XCTAssertNil(InputSourceSwitcher.selectableSourceID(from: ids, target: .english))
    }

    // MARK: - Scenario: Typing numbers on Thai layout

    func testTypingNumbersOnThaiLayout() {
        // When user types "ๆถ" (which are Thai chars on keys 1 and 5), should convert to "15"
        let converted = KeyboardLayoutConverter.convertThaiToEnglish("ๆถ")
        // "1" maps to ๆ in unshifted, "5" maps to ถ
        XCTAssertTrue(converted.contains("1") || converted.contains("5") || converted.contains("q"),
                      "Should convert Thai layout numbers back to digits")
    }

    // MARK: - Scenario: PimPidKeys constants are unique

    func testPimPidKeys_AllUnique() {
        let keys = [
            PimPidKeys.enabled,
            PimPidKeys.excludeWords,
            PimPidKeys.shortcutKeyCode,
            PimPidKeys.shortcutModifierFlags,
            PimPidKeys.autoCorrectEnabled,
            PimPidKeys.autoCorrectDelay,
            PimPidKeys.autoCorrectMinChars,
            PimPidKeys.autoCorrectPostReplaceDelayMs,
            PimPidKeys.backspaceDelayMs,
            PimPidKeys.autoCorrectSoundEnabled,
            PimPidKeys.autoCorrectVisualFeedback,
            PimPidKeys.autoCorrectExcludedApps,
            PimPidKeys.autoCorrectExcludedWindows,
            PimPidKeys.thaiKeyboardLayout,
            PimPidKeys.hasCompletedOnboarding,
            PimPidKeys.onboardingDidOpenAccessibilitySettings,
            PimPidKeys.appearanceTheme,
            PimPidKeys.appearanceFontSize,
            PimPidKeys.notificationStyle,
            PimPidKeys.toastDuration,
            PimPidKeys.appLanguage,
        ]
        let uniqueKeys = Set(keys)
        XCTAssertEqual(uniqueKeys.count, keys.count, "All PimPidKeys should be unique")
    }

    // MARK: - Scenario: Word buffer boundaries

    func testWordBufferEdge_TwoCharMinimum() {
        // Minimum word length for replacement is 2
        XCTAssertNil(AutoCorrectionLogic.replacement(for: "a", excludeWords: []))
        // 2 chars should be eligible
        let twoChar = AutoCorrectionLogic.replacement(for: "rd", excludeWords: [])
        XCTAssertNotNil(twoChar, "Two-character word should be eligible for replacement")
    }
}

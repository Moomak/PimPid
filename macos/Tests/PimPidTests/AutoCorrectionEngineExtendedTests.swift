import XCTest
import CoreGraphics
@testable import PimPid

/// Extended tests for AutoCorrectionEngine buffer/clear logic
final class AutoCorrectionEngineExtendedTests: XCTestCase {

    // MARK: - shouldClearBuffer: all navigation keys

    func testShouldClearBuffer_Enter_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x4C, flags: []))
    }

    func testShouldClearBuffer_Home_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x73, flags: []))
    }

    func testShouldClearBuffer_End_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x77, flags: []))
    }

    func testShouldClearBuffer_PageUp_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x74, flags: []))
    }

    func testShouldClearBuffer_PageDown_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x79, flags: []))
    }

    // MARK: - Multiple modifier combinations

    func testShouldClearBuffer_CommandShift_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0, flags: [.maskCommand, .maskShift]))
    }

    func testShouldClearBuffer_ControlAlternate_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0, flags: [.maskControl, .maskAlternate]))
    }

    func testShouldClearBuffer_ShiftOnly_ReturnsFalse() {
        // Shift alone should not clear buffer (it's for typing uppercase)
        XCTAssertFalse(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0, flags: .maskShift))
    }

    // MARK: - Various non-navigation keys

    func testShouldClearBuffer_SpaceKey_ReturnsFalse() {
        // Space key code is 0x31 -- not in navigation set, no modifier
        XCTAssertFalse(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x31, flags: []))
    }

    func testShouldClearBuffer_BackspaceKey_ReturnsFalse() {
        // Backspace (0x33) is not in the navigation set (handled separately in handleKeyEvent)
        XCTAssertFalse(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x33, flags: []))
    }

    func testShouldClearBuffer_NumberKeys_ReturnFalse() {
        // Number keys should not clear buffer
        for keyCode: UInt16 in [18, 19, 20, 21, 22, 23, 24, 25, 26, 28, 29] {
            XCTAssertFalse(AutoCorrectionEngine.shouldClearBuffer(keyCode: keyCode, flags: []),
                           "Number key \(keyCode) should not clear buffer")
        }
    }

    // MARK: - Fn key combinations

    func testShouldClearBuffer_CommandWithArrow_ReturnsTrue() {
        // Cmd+Arrow should clear (Command modifier)
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x7B, flags: .maskCommand))
    }
}

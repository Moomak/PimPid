import XCTest
import CoreGraphics
@testable import PimPid

/// Task 2: ทดสอบ logic การ clear buffer (modifier / navigation) โดยไม่ต้องเปิด CGEventTap
final class AutoCorrectionEngineTests: XCTestCase {

    func testShouldClearBuffer_ModifierCommand_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0, flags: .maskCommand))
    }

    func testShouldClearBuffer_ModifierControl_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0, flags: .maskControl))
    }

    func testShouldClearBuffer_ModifierAlternate_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0, flags: .maskAlternate))
    }

    func testShouldClearBuffer_ArrowLeft_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x7B, flags: []))
    }

    func testShouldClearBuffer_ArrowRight_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x7C, flags: []))
    }

    func testShouldClearBuffer_ArrowDown_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x7D, flags: []))
    }

    func testShouldClearBuffer_ArrowUp_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x7E, flags: []))
    }

    func testShouldClearBuffer_Escape_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x35, flags: []))
    }

    func testShouldClearBuffer_Return_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x24, flags: []))
    }

    func testShouldClearBuffer_Tab_ReturnsTrue() {
        XCTAssertTrue(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0x30, flags: []))
    }

    func testShouldClearBuffer_NormalLetterKey_ReturnsFalse() {
        // keyCode 0 = 'a' on many layouts
        XCTAssertFalse(AutoCorrectionEngine.shouldClearBuffer(keyCode: 0, flags: []))
    }

    func testShouldClearBuffer_LetterWithNoModifier_ReturnsFalse() {
        XCTAssertFalse(AutoCorrectionEngine.shouldClearBuffer(keyCode: 8, flags: [])) // 'c' = 8
    }
}

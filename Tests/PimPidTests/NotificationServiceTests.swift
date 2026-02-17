import XCTest
@testable import PimPid

/// Task 82: Unit test NotificationService — showToast, queue, dismiss
@MainActor
final class NotificationServiceTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        NotificationService.shared.clearAll()
    }

    func testShowToast_SetsCurrentToast() {
        let service = NotificationService.shared
        service.clearAll()
        service.showToast(message: "Test message", type: .success)
        XCTAssertNotNil(service.currentToast)
        XCTAssertEqual(service.currentToast?.message, "Test message")
        XCTAssertEqual(service.currentToast?.type, .success)
    }

    func testDismissCurrentToast_ClearsCurrent() {
        let service = NotificationService.shared
        service.clearAll()
        service.showToast(message: "Dismiss me", type: .info)
        XCTAssertNotNil(service.currentToast)
        service.dismissCurrentToast()
        XCTAssertNil(service.currentToast)
    }

    func testShowToastWhileShowing_QueuesNext() {
        let service = NotificationService.shared
        service.clearAll()
        service.showToast(message: "First", type: .success)
        service.showToast(message: "Second", type: .warning)
        XCTAssertEqual(service.currentToast?.message, "First")
        XCTAssertEqual(service.toastQueue.count, 1)
        XCTAssertEqual(service.toastQueue.first?.message, "Second")
    }

    func testDismissCurrentToast_ShowsNextInQueue() {
        let service = NotificationService.shared
        service.clearAll()
        service.showToast(message: "First", type: .success)
        service.showToast(message: "Second", type: .info)
        service.dismissCurrentToast()
        XCTAssertEqual(service.currentToast?.message, "Second")
        XCTAssertTrue(service.toastQueue.isEmpty)
    }

    func testClearAll_RemovesAll() {
        let service = NotificationService.shared
        service.clearAll()
        service.showToast(message: "A", type: .success)
        service.showToast(message: "B", type: .error)
        service.clearAll()
        XCTAssertNil(service.currentToast)
        XCTAssertTrue(service.toastQueue.isEmpty)
    }
}

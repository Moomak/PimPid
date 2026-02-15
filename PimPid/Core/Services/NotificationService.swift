import Foundation
import SwiftUI
import AppKit

/// จัดการแสดง toast notification และ visual feedback
@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var currentToast: ToastMessage?
    @Published var toastQueue: [ToastMessage] = []

    private var isShowingToast = false
    private let toastDuration: TimeInterval = 2.0

    private init() {}

    /// แสดง toast notification
    func showToast(message: String, type: ToastType = .success) {
        let toast = ToastMessage(message: message, type: type)

        if isShowingToast {
            // Add to queue if already showing
            toastQueue.append(toast)
        } else {
            // Show immediately
            displayToast(toast)
        }
    }

    /// แสดง toast ทันที
    private func displayToast(_ toast: ToastMessage) {
        isShowingToast = true
        currentToast = toast

        // Auto-dismiss after duration
        Task {
            try? await Task.sleep(nanoseconds: UInt64(toastDuration * 1_000_000_000))
            await dismissCurrentToast()
        }
    }

    /// ปิด toast ปัจจุบันและแสดงอันถัดไป (ถ้ามี)
    private func dismissCurrentToast() {
        currentToast = nil
        isShowingToast = false

        // Show next toast in queue
        if !toastQueue.isEmpty {
            let next = toastQueue.removeFirst()
            displayToast(next)
        }
    }

    /// ล้าง toast ทั้งหมด
    func clearAll() {
        currentToast = nil
        toastQueue.removeAll()
        isShowingToast = false
    }
}

// MARK: - ToastMessage

struct ToastMessage: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
}

// MARK: - ToastType

enum ToastType {
    case success
    case info
    case warning
    case error

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .green
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

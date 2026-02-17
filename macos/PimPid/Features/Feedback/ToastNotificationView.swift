import SwiftUI
import AppKit

/// Toast notification overlay แสดงผลการแปลงแบบสวยงาม (รองรับขนาดตัวอักษรและสไตล์จาก Settings)
struct ToastNotificationView: View {
    let toast: ToastMessage

    @State private var isVisible = false

    private static var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    private static var fontSizeScale: CGFloat {
        let key = UserDefaults.standard.string(forKey: PimPidKeys.appearanceFontSize) ?? "medium"
        switch key {
        case "small": return 0.9
        case "large": return 1.15
        default: return 1.0
        }
    }

    private static var isMinimalStyle: Bool {
        UserDefaults.standard.string(forKey: PimPidKeys.notificationStyle) == "minimal"
    }

    var body: some View {
        let scale = Self.fontSizeScale
        let minimal = Self.isMinimalStyle

        HStack(spacing: minimal ? 8 : 12) {
            if !minimal {
                Image(systemName: toast.type.icon)
                    .font(.system(size: 16 * scale, weight: .semibold))
                    .foregroundColor(toast.type.color)
            }

            Text(toast.message)
                .font(.system(size: (minimal ? 12 : 13) * scale, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(minimal ? 1 : 2)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, minimal ? 12 : 16)
        .padding(.vertical, minimal ? 8 : 12)
        .background(
            RoundedRectangle(cornerRadius: minimal ? 6 : 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(minimal ? 0.15 : 0.2), radius: minimal ? 4 : 8, x: 0, y: minimal ? 2 : 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: minimal ? 6 : 10)
                .strokeBorder(toast.type.color.opacity(minimal ? 0.2 : 0.3), lineWidth: 1)
        )
        .frame(maxWidth: minimal ? 260 : 300)
        .offset(y: isVisible ? 0 : -50)
        .opacity(isVisible ? 1 : 0)
        .animation(Self.reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
        .onAppear {
            withAnimation(Self.reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            NotificationService.shared.dismissCurrentToast()
        }
    }
}

/// Container สำหรับแสดง toast notification overlay
struct ToastOverlayView: View {
    @ObservedObject var notificationService = NotificationService.shared

    var body: some View {
        GeometryReader { geometry in
            VStack {
                if let toast = notificationService.currentToast {
                    ToastNotificationView(toast: toast)
                        .padding(.top, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()
            }
            .frame(width: geometry.size.width)
        }
        .allowsHitTesting(false) // Allow clicks to pass through
    }
}

#Preview {
    VStack(spacing: 20) {
        ToastNotificationView(toast: ToastMessage(message: "สเไก → hello", type: .success))
        ToastNotificationView(toast: ToastMessage(message: "แก้ไขสำเร็จ", type: .info))
        ToastNotificationView(toast: ToastMessage(message: "ไม่สามารถแปลงได้", type: .warning))
        ToastNotificationView(toast: ToastMessage(message: "เกิดข้อผิดพลาด", type: .error))
    }
    .padding()
    .frame(width: 400, height: 400)
}

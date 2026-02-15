import SwiftUI

/// Toast notification overlay แสดงผลการแปลงแบบสวยงาม
struct ToastNotificationView: View {
    let toast: ToastMessage

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: toast.type.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(toast.type.color)

            // Message
            Text(toast.message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(toast.type.color.opacity(0.3), lineWidth: 1)
        )
        .frame(maxWidth: 300)
        .offset(y: isVisible ? 0 : -50)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
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

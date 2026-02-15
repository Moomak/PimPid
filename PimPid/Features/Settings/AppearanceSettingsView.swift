import SwiftUI

/// Appearance settings view
struct AppearanceSettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section {
                Text("การตั้งค่ารูปลักษณ์จะมีให้ในเวอร์ชันถัดไป")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 16) {
                    FeaturePreview(
                        icon: "paintpalette.fill",
                        title: "ธีมสี",
                        description: "เลือกธีมสีที่ชอบ (Light, Dark, Auto)",
                        available: false
                    )

                    FeaturePreview(
                        icon: "textformat.size",
                        title: "ขนาดตัวอักษร",
                        description: "ปรับขนาดตัวอักษรใน menu bar และ settings",
                        available: false
                    )

                    FeaturePreview(
                        icon: "bell.badge.fill",
                        title: "สไตล์การแจ้งเตือน",
                        description: "เลือกรูปแบบ toast notification",
                        available: false
                    )
                }
                .padding(.vertical, 8)
            } header: {
                Text("รูปลักษณ์")
                    .font(.headline)
            }

            Section {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("ฟีเจอร์เหล่านี้จะพร้อมใช้งานในเวอร์ชัน 1.1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("รูปลักษณ์")
    }
}

/// Feature preview component
struct FeaturePreview: View {
    let icon: String
    let title: String
    let description: String
    let available: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(
                    LinearGradient(
                        colors: available ? [.blue, .purple] : [.gray, .gray],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))

                    if !available {
                        Text("เร็วๆ นี้")
                            .font(.system(size: 9, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .opacity(available ? 1.0 : 0.6)
    }
}

#Preview {
    AppearanceSettingsView()
        .environmentObject(AppState())
}

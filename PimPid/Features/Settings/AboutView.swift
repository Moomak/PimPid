import SwiftUI

/// About view with app information and quick start guide
struct AboutView: View {
    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    // App icon
                    Image(systemName: "character.bubble.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // App name and version
                    VStack(spacing: 4) {
                        Text("PimPid")
                            .font(.system(size: 24, weight: .bold))

                        Text("เวอร์ชัน \(Bundle.main.appVersion)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }

                    // Description
                    Text("แปลงข้อความไทย ⇄ อังกฤษ ตามตำแหน่งปุ่มคีย์บอร์ด (Kedmanee / QWERTY)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text("รองรับ Auto-Correct ขณะพิมพ์ และรายการคำ exclude")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            Section {
                VStack(alignment: .leading, spacing: 16) {
                    QuickStartStep(
                        number: 1,
                        title: "เปิดใช้งาน PimPid",
                        description: "คลิก menu bar icon และเปิด toggle 'PimPid เปิดใช้งาน'"
                    )

                    QuickStartStep(
                        number: 2,
                        title: "ให้สิทธิ์ Accessibility",
                        description: "อนุญาตให้ PimPid เข้าถึงคีย์บอร์ดใน System Settings"
                    )

                    QuickStartStep(
                        number: 3,
                        title: "เปิด Auto-Correct",
                        description: "เปิดใช้ Auto-Correct เพื่อแก้ไขอัตโนมัติขณะพิมพ์เมื่อตรวจพบการพิมพ์ผิดภาษา"
                    )
                }
            } header: {
                Text("Quick Start Guide")
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Link(destination: URL(string: "https://github.com/Moomak/PimPid")!) {
                        HStack {
                            Image(systemName: "link")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            Text("GitHub")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("github.com/Moomak/PimPid")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(width: 20)
                        Text("License")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("MIT License")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("ข้อมูลเพิ่มเติม")
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("© 2025 PimPid · MIT License")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Made with ❤️ for Thai and English keyboard switchers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("เกี่ยวกับ")
    }
}

/// Quick start step component
struct QuickStartStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Number badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// About link component
struct AboutLink: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 12, weight: .medium))

            Spacer()

            Text(value)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    AboutView()
}

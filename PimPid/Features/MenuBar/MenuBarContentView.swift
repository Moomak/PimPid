import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("PimPid เปิดใช้งาน", isOn: $appState.isEnabled)
                .toggleStyle(.switch)
                .accessibilityLabel("PimPid เปิดใช้งาน")
                .accessibilityHint("สลับการทำงานของการแปลงภาษาอัตโนมัติ")

            Text("สลับภาษาที่เลือก: ⌘⇧L")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Shortcut สลับภาษาที่เลือก: Command Shift L")

            Divider()

            Button("ตั้งค่า (Exclude คำ)…") {
                openSettings()
            }
            .accessibilityLabel("ตั้งค่า")
            .accessibilityHint("เปิดหน้าต่างตั้งค่าและรายการคำที่ไม่ให้แปลง")

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .accessibilityLabel("Quit")
            .accessibilityHint("ปิดแอป PimPid")
        }
        .padding(12)
        .frame(minWidth: 220)
    }
}

extension EnvironmentValues {
    var openSettings: OpenSettingsAction {
        get { self[OpenSettingsKey.self] }
        set { self[OpenSettingsKey.self] = newValue }
    }
}

struct OpenSettingsKey: EnvironmentKey {
    static let defaultValue: OpenSettingsAction = {}
}

typealias OpenSettingsAction = () -> Void

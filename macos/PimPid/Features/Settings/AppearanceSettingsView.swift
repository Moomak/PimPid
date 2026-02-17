import SwiftUI

/// Appearance settings: theme, font size
struct AppearanceSettingsView: View {
    @EnvironmentObject var appState: AppState

    private static let themeOptions: [(id: String, label: String)] = [
        ("auto", "ตามระบบ"),
        ("light", "สว่าง"),
        ("dark", "มืด"),
    ]
    private static let fontSizeOptions: [(id: String, label: String)] = [
        ("small", "เล็ก"),
        ("medium", "ปกติ"),
        ("large", "ใหญ่"),
    ]
    private static let notificationStyleOptions: [(id: String, label: String)] = [
        ("toast", "Toast"),
        ("minimal", "แบบย่อ"),
        ("off", "ปิด"),
    ]
    private static let toastDurationOptions: [(id: Double, label: String)] = [
        (1.5, "1.5 วินาที"),
        (2.0, "2 วินาที"),
        (3.0, "3 วินาที"),
    ]
    var body: some View {
        Form {
            Section {
                Picker("ธีมสี", selection: $appState.appearanceTheme) {
                    ForEach(Self.themeOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .pickerStyle(.menu)

                Text("เลือกโทนสีของแอป (ตั้งค่า → เกี่ยวกับ และเมนู)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("ธีมสี")
                    .font(.headline)
            }

            Section {
                Picker("ขนาดตัวอักษร", selection: $appState.appearanceFontSize) {
                    ForEach(Self.fontSizeOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .pickerStyle(.menu)

                Text("ใช้กับเมนูและหน้าตั้งค่า")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("ขนาดตัวอักษร")
                    .font(.headline)
            }

            Section {
                Picker("สไตล์การแจ้งเตือน", selection: $appState.notificationStyle) {
                    ForEach(Self.notificationStyleOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .pickerStyle(.menu)

                Text("Toast = แสดงข้อความหลังแปลง, แบบย่อ = สั้นลง, ปิด = ไม่แสดง")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("การแจ้งเตือน")
                    .font(.headline)
            }

            Section {
                Button("ใช้ค่าเริ่มต้น") {
                    appState.appearanceTheme = "auto"
                    appState.appearanceFontSize = "medium"
                    appState.notificationStyle = "toast"
                    UserDefaults.standard.set(2.0, forKey: PimPidKeys.toastDuration)
                }
                .buttonStyle(.bordered)
            } header: {
                Text("รีเซ็ต")
                    .font(.headline)
            }

            Section {
                Picker("ระยะเวลาแสดง Toast", selection: Binding(
                    get: {
                        let d = UserDefaults.standard.double(forKey: PimPidKeys.toastDuration)
                        return d > 0 ? d : 2.0
                    },
                    set: { UserDefaults.standard.set($0, forKey: PimPidKeys.toastDuration) }
                )) {
                    ForEach(Self.toastDurationOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("ระยะเวลา Toast")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("รูปลักษณ์")
    }
}

#Preview {
    AppearanceSettingsView()
        .environmentObject(AppState())
}

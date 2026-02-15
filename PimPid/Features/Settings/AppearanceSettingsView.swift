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
        }
        .formStyle(.grouped)
        .navigationTitle("รูปลักษณ์")
    }
}

#Preview {
    AppearanceSettingsView()
        .environmentObject(AppState())
}

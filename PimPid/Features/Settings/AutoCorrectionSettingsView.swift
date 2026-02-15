import SwiftUI

/// Auto-correction settings view
struct AutoCorrectionSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var newAppBundleID = ""

    var body: some View {
        Form {
            Section {
                Toggle("เปิดใช้งาน Auto-Correct", isOn: $appState.autoCorrectEnabled)
                    .toggleStyle(.switch)
                    .disabled(!KeyboardShortcutManager.isAccessibilityTrusted)

                Text("แก้ไขข้อความอัตโนมัติทันทีที่พิมพ์ผิดภาษา โดยไม่ต้องกด shortcut")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !KeyboardShortcutManager.isAccessibilityTrusted {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("ต้องการสิทธิ์ Accessibility")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 4)
                }
            } header: {
                Text("การเปิดใช้งาน")
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("ความล่าช้า:")
                            .font(.system(size: 13))
                        Spacer()
                        Text("\(Int(appState.autoCorrectDelay))ms")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $appState.autoCorrectDelay, in: 0...500, step: 50)
                        .disabled(!appState.autoCorrectEnabled)

                    Text("เวลารอก่อนแก้ไขอัตโนมัติ (0ms = ทันที)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("ตั้งค่าการแก้ไข")
                    .font(.headline)
            }

            Section {
                Toggle("เสียงแจ้งเตือน", isOn: $appState.autoCorrectSoundEnabled)
                    .toggleStyle(.switch)
                    .disabled(!appState.autoCorrectEnabled)

                Toggle("แสดงการแจ้งเตือนบนหน้าจอ", isOn: $appState.autoCorrectVisualFeedback)
                    .toggleStyle(.switch)
                    .disabled(!appState.autoCorrectEnabled)

                Text("แสดง toast notification เมื่อแก้ไขข้อความสำเร็จ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Visual & Sound Feedback")
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField("Bundle ID (เช่น com.apple.Safari)", text: $newAppBundleID)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                addExcludedApp()
                            }

                        Button("เพิ่ม") {
                            addExcludedApp()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newAppBundleID.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    Text("เพิ่ม Bundle ID ของแอปที่ไม่ต้องการให้ auto-correct ทำงาน")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // List of excluded apps
                    if appState.excludedApps.isEmpty {
                        Text("ยังไม่มีแอปที่ถูก exclude")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(appState.excludedApps).sorted(), id: \.self) { bundleID in
                                HStack {
                                    Text(bundleID)
                                        .font(.system(size: 12, weight: .medium))

                                    Spacer()

                                    Button(action: {
                                        appState.excludedApps.remove(bundleID)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .font(.system(size: 12))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            } header: {
                Text("Excluded Apps (\(appState.excludedApps.count))")
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(
                        icon: "lightbulb.fill",
                        color: .yellow,
                        title: "วิธีใช้งาน",
                        description: "Auto-correct จะทำงานทันทีเมื่อคุณพิมพ์คำและกด Space หรือ Enter"
                    )

                    InfoRow(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        title: "ประโยชน์",
                        description: "ไม่ต้องเลือกข้อความและกด shortcut อีกต่อไป แค่พิมพ์ไปเรื่อยๆ"
                    )

                    InfoRow(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        title: "หมายเหตุ",
                        description: "Auto-correct อาจทำให้การพิมพ์ช้าลงเล็กน้อยในบางแอป"
                    )
                }
            } header: {
                Text("ข้อมูล")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Auto-Correct")
    }

    private func addExcludedApp() {
        let trimmed = newAppBundleID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        appState.excludedApps.insert(trimmed)
        newAppBundleID = ""
    }
}

/// Info row component
struct InfoRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)

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

#Preview {
    AutoCorrectionSettingsView()
        .environmentObject(AppState())
}

import SwiftUI

/// Auto-correction settings view
struct AutoCorrectionSettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var newAppBundleID = ""
    @State private var showRunningAppPicker = false

    var body: some View {
        Form {
            Section {
                Toggle("เปิดใช้งาน Auto-Correct", isOn: $appState.autoCorrectEnabled)
                    .toggleStyle(.switch)
                    .disabled(!AccessibilityHelper.isAccessibilityTrusted)

                Text("แก้ไขข้อความอัตโนมัติทันทีที่พิมพ์ผิดภาษา")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !AccessibilityHelper.isAccessibilityTrusted {
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

                    Slider(value: $appState.autoCorrectDelay, in: 0...1000, step: 50)
                        .disabled(!appState.autoCorrectEnabled)

                    Text("เวลารอก่อนแก้ไขอัตโนมัติ (0–1000 ms, 0 = ใช้ค่าเริ่มต้น 200 ms)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("จำนวนตัวอักษรขั้นต่ำ:")
                            .font(.system(size: 13))
                        Spacer()
                        Picker("", selection: Binding(
                            get: {
                                let n = UserDefaults.standard.object(forKey: PimPidKeys.autoCorrectMinChars).flatMap { $0 as? NSNumber }.map(\.intValue)
                                return n.flatMap(Int.init) ?? 3
                            },
                            set: { UserDefaults.standard.set($0, forKey: PimPidKeys.autoCorrectMinChars) }
                        )) {
                            Text("2 ตัว").tag(2)
                            Text("3 ตัว").tag(3)
                            Text("4 ตัว").tag(4)
                            Text("5 ตัว").tag(5)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                        .disabled(!appState.autoCorrectEnabled)
                    }
                    Text("ต้องพิมพ์อย่างน้อยกี่ตัวอักษรก่อนจะเริ่มแก้ไขอัตโนมัติ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("ตั้งค่าการแก้ไข")
                    .font(.headline)
            }

            Section {
                Picker("Layout คีย์บอร์ดไทย", selection: Binding(
                    get: { UserDefaults.standard.string(forKey: PimPidKeys.thaiKeyboardLayout) ?? "kedmanee" },
                    set: { UserDefaults.standard.set($0, forKey: PimPidKeys.thaiKeyboardLayout) }
                )) {
                    Text("Kedmanee").tag("kedmanee")
                    Text("Patta Choti").tag("pattachoti")
                }
                .pickerStyle(.menu)
                Text("ใช้ mapping ตาม layout ที่เลือก (Patta Choti ต้องมีไฟล์ KeyboardLayout-PattaChoti.plist ในแอป)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Layout ไทย")
                    .font(.headline)
            }

            Section {
                Toggle("เสียงแจ้งเตือน", isOn: $appState.autoCorrectSoundEnabled)
                    .toggleStyle(.switch)
                    .disabled(!appState.autoCorrectEnabled)

                Toggle("แสดงการแจ้งเตือนเมื่อแก้ไขอัตโนมัติ", isOn: $appState.autoCorrectVisualFeedback)
                    .toggleStyle(.switch)
                    .disabled(!appState.autoCorrectEnabled)
            } header: {
                Text("เสียง และการแจ้งเตือน")
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

                        Button("เพิ่มจากแอปที่เปิดอยู่…") {
                            showRunningAppPicker = true
                        }
                        .buttonStyle(.bordered)
                    }

                    Text("เพิ่ม Bundle ID ของแอปที่ไม่ต้องการให้ auto-correct ทำงาน")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // List of excluded apps (แสดงชื่อแอปถ้าได้ — task 44)
                    if appState.excludedApps.isEmpty {
                        Text("ยังไม่มีแอปที่ถูก exclude")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(appState.excludedApps).sorted(), id: \.self) { bundleID in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(appDisplayName(for: bundleID))
                                            .font(.system(size: 12, weight: .medium))
                                        if appDisplayName(for: bundleID) != bundleID {
                                            Text(bundleID)
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                        }
                                    }

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
                Button("Exclude หน้าต่างนี้") {
                    if let key = FrontmostWindowHelper.frontmostWindowKey() {
                        appState.excludedWindows.insert(key)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!appState.autoCorrectEnabled)

                Text("เพิ่มเฉพาะหน้าต่างที่โฟกัสอยู่ (ไม่ใช่ทั้งแอป)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if appState.excludedWindows.isEmpty {
                    Text("ยังไม่มีหน้าต่างที่ exclude")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(appState.excludedWindows).sorted(), id: \.self) { key in
                            HStack {
                                Text(excludedWindowDisplay(key))
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button(action: { appState.excludedWindows.remove(key) }) {
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
            } header: {
                Text("Excluded Windows (\(appState.excludedWindows.count))")
                    .font(.headline)
            }

            Section {
                Button("ใช้ค่าเริ่มต้น") {
                    appState.autoCorrectDelay = 0
                    UserDefaults.standard.set(3, forKey: PimPidKeys.autoCorrectMinChars)
                    appState.autoCorrectSoundEnabled = false
                    appState.autoCorrectVisualFeedback = true
                    appState.excludedApps = []
                    appState.excludedWindows = []
                }
                .buttonStyle(.bordered)
            } header: {
                Text("รีเซ็ต")
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
                        description: "แค่พิมพ์ไปเรื่อยๆ PimPid จะแก้ไขอัตโนมัติเมื่อตรวจพบการพิมพ์ผิดภาษา"
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
        .sheet(isPresented: $showRunningAppPicker) {
            RunningAppPickerView(excludedApps: $appState.excludedApps, onDismiss: { showRunningAppPicker = false })
        }
    }

    private func addExcludedApp() {
        let trimmed = newAppBundleID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        appState.excludedApps.insert(trimmed)
        newAppBundleID = ""
    }

    /// Task 8: แสดงข้อความสำหรับ excluded window key "bundleID:windowNumber"
    private func excludedWindowDisplay(_ key: String) -> String {
        if let colon = key.firstIndex(of: ":") {
            let bundleID = String(key[..<colon])
            let windowPart = String(key[key.index(after: colon)...])
            let name = appDisplayName(for: bundleID)
            return "\(name) (window \(windowPart))"
        }
        return key
    }

    /// แสดงชื่อแอปจาก Bundle ID (จาก running apps หรือ bundle)
    private func appDisplayName(for bundleID: String) -> String {
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }),
           let name = app.localizedName, !name.isEmpty {
            return name
        }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
           let bundle = Bundle(url: url) {
            return (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                ?? (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                ?? bundleID
        }
        return bundleID
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

// MARK: - Running App Picker (Task 45)

struct RunningAppPickerView: View {
    @Binding var excludedApps: Set<String>
    var onDismiss: () -> Void

    private static let pimpidBundleID = Bundle.main.bundleIdentifier ?? ""

    private var runningApps: [(bundleID: String, name: String)] {
        NSWorkspace.shared.runningApplications
            .compactMap { app -> (String, String)? in
                guard let bid = app.bundleIdentifier, !bid.isEmpty,
                      bid != Self.pimpidBundleID,
                      app.activationPolicy == .regular,
                      let name = app.localizedName, !name.isEmpty
                else { return nil }
                return (bid, name)
            }
            .sorted { $0.1.localizedCaseInsensitiveCompare($1.1) == .orderedAscending }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("เลือกแอปเพื่อเพิ่มเข้า Excluded Apps")
                .font(.headline)
                .padding()

            List(runningApps, id: \.bundleID) { item in
                Button(action: {
                    excludedApps.insert(item.bundleID)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 13, weight: .medium))
                            Text(item.bundleID)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if excludedApps.contains(item.bundleID) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(excludedApps.contains(item.bundleID))
            }

            HStack {
                Spacer()
                Button("ปิด") { onDismiss() }
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
        }
        .frame(minWidth: 400, minHeight: 350)
    }
}

#Preview {
    AutoCorrectionSettingsView()
        .environmentObject(AppState())
}

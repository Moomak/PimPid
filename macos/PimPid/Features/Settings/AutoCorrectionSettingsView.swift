import SwiftUI

/// Auto-correction settings view
struct AutoCorrectionSettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage(PimPidKeys.autoCorrectMinChars) private var autoCorrectMinChars = 3
    @State private var newAppBundleID = ""
    @State private var showRunningAppPicker = false

    private var minCharsSelection: Binding<Int> {
        Binding(
            get: { min(max(autoCorrectMinChars, 2), 5) },
            set: { autoCorrectMinChars = min(max($0, 2), 5) }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle(String(localized: "autocorrect.toggle", bundle: appState.localizedBundle), isOn: $appState.autoCorrectEnabled)
                    .toggleStyle(.switch)
                    .disabled(!AccessibilityHelper.isAccessibilityTrusted)

                Text(String(localized: "autocorrect.description", bundle: appState.localizedBundle))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !AccessibilityHelper.isAccessibilityTrusted {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(String(localized: "accessibility.warning", bundle: appState.localizedBundle))
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 4)
                }
            } header: {
                Text(String(localized: "autocorrect.section.enable", bundle: appState.localizedBundle))
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(String(localized: "autocorrect.delay", bundle: appState.localizedBundle))
                            .font(.system(size: 13))
                        Spacer()
                        Text("\(Int(appState.autoCorrectDelay))ms")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $appState.autoCorrectDelay, in: 0...1000, step: 50)
                        .disabled(!appState.autoCorrectEnabled)

                    Text(String(localized: "autocorrect.delay_hint", bundle: appState.localizedBundle))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text(String(localized: "autocorrect.min_chars", bundle: appState.localizedBundle))
                            .font(.system(size: 13))
                        Spacer()
                        Picker("", selection: minCharsSelection) {
                            Text(String(format: String(localized: "autocorrect.chars_unit", bundle: appState.localizedBundle), 2)).tag(2)
                            Text(String(format: String(localized: "autocorrect.chars_unit", bundle: appState.localizedBundle), 3)).tag(3)
                            Text(String(format: String(localized: "autocorrect.chars_unit", bundle: appState.localizedBundle), 4)).tag(4)
                            Text(String(format: String(localized: "autocorrect.chars_unit", bundle: appState.localizedBundle), 5)).tag(5)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                        .disabled(!appState.autoCorrectEnabled)
                    }
                    Text(String(localized: "autocorrect.min_chars_hint", bundle: appState.localizedBundle))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(String(localized: "autocorrect.section.settings", bundle: appState.localizedBundle))
                    .font(.headline)
            }

            Section {
                Picker(String(localized: "autocorrect.layout_picker", bundle: appState.localizedBundle), selection: Binding(
                    get: { UserDefaults.standard.string(forKey: PimPidKeys.thaiKeyboardLayout) ?? "kedmanee" },
                    set: { UserDefaults.standard.set($0, forKey: PimPidKeys.thaiKeyboardLayout) }
                )) {
                    Text("Kedmanee").tag("kedmanee")
                    Text("Patta Choti").tag("pattachoti")
                }
                .pickerStyle(.menu)
                Text(String(localized: "autocorrect.layout_hint", bundle: appState.localizedBundle))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(String(localized: "autocorrect.section.layout", bundle: appState.localizedBundle))
                    .font(.headline)
            }

            Section {
                Toggle(String(localized: "autocorrect.sound", bundle: appState.localizedBundle), isOn: $appState.autoCorrectSoundEnabled)
                    .toggleStyle(.switch)
                    .disabled(!appState.autoCorrectEnabled)

                Toggle(String(localized: "autocorrect.visual_feedback", bundle: appState.localizedBundle), isOn: $appState.autoCorrectVisualFeedback)
                    .toggleStyle(.switch)
                    .disabled(!appState.autoCorrectEnabled)
            } header: {
                Text(String(localized: "autocorrect.section.notification", bundle: appState.localizedBundle))
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        TextField(String(localized: "autocorrect.bundle_placeholder", bundle: appState.localizedBundle), text: $newAppBundleID)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                addExcludedApp()
                            }

                        Button(String(localized: "button.add", bundle: appState.localizedBundle)) {
                            addExcludedApp()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newAppBundleID.trimmingCharacters(in: .whitespaces).isEmpty)

                        Button(String(localized: "autocorrect.add_from_running", bundle: appState.localizedBundle)) {
                            showRunningAppPicker = true
                        }
                        .buttonStyle(.bordered)
                    }

                    Text(String(localized: "autocorrect.exclude_hint", bundle: appState.localizedBundle))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // List of excluded apps (แสดงชื่อแอปถ้าได้ — task 44)
                    if appState.excludedApps.isEmpty {
                        Text(String(localized: "autocorrect.no_excluded_apps", bundle: appState.localizedBundle))
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
                Button(String(localized: "autocorrect.exclude_window", bundle: appState.localizedBundle)) {
                    if let key = FrontmostWindowHelper.frontmostWindowKey() {
                        appState.excludedWindows.insert(key)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(!appState.autoCorrectEnabled)

                Text(String(localized: "autocorrect.exclude_window_hint", bundle: appState.localizedBundle))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if appState.excludedWindows.isEmpty {
                    Text(String(localized: "autocorrect.no_excluded_windows", bundle: appState.localizedBundle))
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
                Button(String(localized: "button.use_defaults", bundle: appState.localizedBundle)) {
                    appState.autoCorrectDelay = 0
                    autoCorrectMinChars = 3
                    appState.autoCorrectSoundEnabled = false
                    appState.autoCorrectVisualFeedback = true
                    appState.excludedApps = []
                    appState.excludedWindows = []
                }
                .buttonStyle(.bordered)
            } header: {
                Text(String(localized: "section.reset", bundle: appState.localizedBundle))
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(
                        icon: "lightbulb.fill",
                        color: .yellow,
                        title: String(localized: "info.howto.title", bundle: appState.localizedBundle),
                        description: String(localized: "info.howto.desc", bundle: appState.localizedBundle)
                    )

                    InfoRow(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        title: String(localized: "info.benefit.title", bundle: appState.localizedBundle),
                        description: String(localized: "info.benefit.desc", bundle: appState.localizedBundle)
                    )

                    InfoRow(
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        title: String(localized: "info.note.title", bundle: appState.localizedBundle),
                        description: String(localized: "info.note.desc", bundle: appState.localizedBundle)
                    )
                }
            } header: {
                Text(String(localized: "section.info", bundle: appState.localizedBundle))
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
    @EnvironmentObject var appState: AppState
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
            Text(String(localized: "autocorrect.pick_app_title", bundle: appState.localizedBundle))
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
                Button(String(localized: "button.close", bundle: appState.localizedBundle)) { onDismiss() }
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

import SwiftUI

/// ค่าขนาดตัวอักษรสำหรับ Settings (task 47)
private struct SettingsFontScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}
extension EnvironmentValues {
    var settingsFontScale: CGFloat {
        get { self[SettingsFontScaleKey.self] }
        set { self[SettingsFontScaleKey.self] = newValue }
    }
}

/// Settings view with modern sidebar navigation
struct SettingsNavigationView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedSection: SettingsSection = .general

    private var fontScale: CGFloat {
        switch appState.appearanceFontSize {
        case "small": return 0.9
        case "large": return 1.15
        default: return 1.0
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    Label {
                        Text(section.title)
                            .font(.system(size: 13 * fontScale, weight: .medium))
                    } icon: {
                        Image(systemName: section.icon)
                            .font(.system(size: 14 * fontScale))
                            .foregroundStyle(section.color)
                    }
                }
            }
            .navigationTitle("PimPid")
            .frame(minWidth: 180)
        } detail: {
            // Detail view — ส่ง font scale ให้ทุก section (task 47)
            Group {
                switch selectedSection {
                case .general:
                    GeneralSettingsView()
                case .shortcut:
                    ShortcutSettingsView()
                case .autoCorrect:
                    AutoCorrectionSettingsView()
                case .exclude:
                    ExcludeSettingsView()
                case .appearance:
                    AppearanceSettingsView()
                case .about:
                    AboutView()
                }
            }
            .environment(\.settingsFontScale, fontScale)
            .frame(minWidth: 500, minHeight: 400)
        }
        .frame(width: 750, height: 550)
    }
}

// MARK: - SettingsSection

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case shortcut
    case autoCorrect
    case exclude
    case appearance
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "ทั่วไป"
        case .shortcut: return "Shortcut"
        case .autoCorrect: return "Auto-Correct"
        case .exclude: return "Exclude คำ"
        case .appearance: return "รูปลักษณ์"
        case .about: return "เกี่ยวกับ"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .shortcut: return "command"
        case .autoCorrect: return "bolt.fill"
        case .exclude: return "minus.circle.fill"
        case .appearance: return "paintbrush.fill"
        case .about: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .general: return .blue
        case .shortcut: return .indigo
        case .autoCorrect: return .orange
        case .exclude: return .red
        case .appearance: return .pink
        case .about: return .green
        }
    }
}

// MARK: - Section Views

/// General settings section
struct GeneralSettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.settingsFontScale) private var fontScale

    var body: some View {
        Form {
            Section {
                Toggle("เปิดใช้งาน PimPid", isOn: $appState.isEnabled)
                    .toggleStyle(.switch)

                Text("เมื่อเปิดใช้งาน PimPid จะทำงานในเบื้องหลังและพร้อมแปลงข้อความ")
                    .font(.system(size: 12 * fontScale))
                    .foregroundStyle(.secondary)
            } header: {
                Text("การทำงานพื้นฐาน")
                    .font(.system(size: 13 * fontScale, weight: .semibold))
            }

            Section {
                LabeledContent("เวอร์ชัน", value: Bundle.main.appVersion)
                LabeledContent("สถานะ", value: appState.isEnabled ? "✅ ใช้งาน" : "⏸️ หยุดชั่วคราว")
            } header: {
                Text("ข้อมูล")
                    .font(.system(size: 13 * fontScale, weight: .semibold))
            }

            Section {
                Button("ใช้ค่าเริ่มต้น") {
                    appState.isEnabled = true
                }
                .buttonStyle(.bordered)
            } header: {
                Text("รีเซ็ต")
                    .font(.system(size: 13 * fontScale, weight: .semibold))
            }
        }
        .formStyle(.grouped)
        .navigationTitle("ทั่วไป")
    }
}

/// Shortcut settings section — แสดง shortcut ปัจจุบันและปุ่มใช้ค่าเริ่มต้น (⌘⇧L)
struct ShortcutSettingsView: View {
    @Environment(\.settingsFontScale) private var fontScale
    @State private var displayShortcut = KeyboardShortcutManager.shortcutDisplayString()
    @State private var currentLayoutName: String? = InputSourceSwitcher.currentLayoutName()

    var body: some View {
        Form {
            Section {
                LabeledContent("Shortcut ปัจจุบัน", value: displayShortcut)
                    .font(.system(size: 13 * fontScale, weight: .medium))

                if let name = currentLayoutName {
                    LabeledContent("Keyboard layout", value: name)
                        .font(.system(size: 13 * fontScale, weight: .medium))
                }

                if InputSourceSwitcher.hasPreviousLayout {
                    Button("กลับไป layout เดิม") {
                        InputSourceSwitcher.switchBackToPrevious()
                        currentLayoutName = InputSourceSwitcher.currentLayoutName()
                    }
                    .buttonStyle(.bordered)
                }

                Button("ใช้ค่าเริ่มต้น (⌘⇧L)") {
                    UserDefaults.standard.set(Int(PimPidKeys.defaultShortcutKeyCode), forKey: PimPidKeys.shortcutKeyCode)
                    UserDefaults.standard.set(Int(PimPidKeys.defaultShortcutModifierFlags), forKey: PimPidKeys.shortcutModifierFlags)
                    KeyboardShortcutManager.shared.update()
                    displayShortcut = KeyboardShortcutManager.shortcutDisplayString()
                }
                .buttonStyle(.borderedProminent)
            } header: {
                Text("Convert Selected Text")
                    .font(.system(size: 13 * fontScale, weight: .semibold))
            } footer: {
                Text("เลือกข้อความที่พิมพ์ผิดภาษาแล้วกด shortcut เพื่อแปลงตามตำแหน่งปุ่ม (Kedmanee ↔ QWERTY). ถ้า shortcut ชนกับแอปอื่น ให้เปลี่ยน key ใน Settings นี้")
                    .font(.system(size: 12 * fontScale))
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Shortcut")
        .onAppear {
            displayShortcut = KeyboardShortcutManager.shortcutDisplayString()
            currentLayoutName = InputSourceSwitcher.currentLayoutName()
        }
    }
}

/// Exclude list settings section
struct ExcludeSettingsView: View {
    @Environment(\.settingsFontScale) private var fontScale
    @StateObject private var store = ExcludeListStore.shared
    @State private var newWord = ""
    @State private var searchText = ""
    @State private var duplicateMessage: String? = nil
    @State private var sortAscending = true

    private var filteredWords: [String] {
        var list = Array(store.words)
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            list = list.filter { $0.localizedCaseInsensitiveContains(searchText.trimmingCharacters(in: .whitespaces)) }
        }
        return sortAscending ? list.sorted() : list.sorted(by: >)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("คำที่ไม่ต้องการให้แปลง", text: $newWord)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            addWord()
                        }

                    Button("เพิ่ม") {
                        addWord()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Button("Paste & Add") {
                    pasteAndAddWords()
                }
                .buttonStyle(.bordered)
                .disabled(NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

                if let msg = duplicateMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Text("ป้อนคำที่ไม่ต้องการให้ PimPid แปลง เช่น ชื่อ, แบรนด์, คำศัพท์เฉพาะ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("เพิ่มคำ")
                    .font(.headline)
            }

            Section {
                if !store.words.isEmpty {
                    TextField("ค้นหาในรายการ", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    Picker("เรียง", selection: $sortAscending) {
                        Text("A → Z").tag(true)
                        Text("Z → A").tag(false)
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Button("Export") { exportExcludeList() }
                        Button("Import…") { importExcludeList() }
                    }
                    .buttonStyle(.bordered)
                }
                if store.words.isEmpty {
                    Text("ยังไม่มีคำที่ exclude")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else if filteredWords.isEmpty {
                    Text("ไม่มีคำที่ตรงกับ \"\(searchText)\"")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    List {
                        ForEach(filteredWords, id: \.self) { word in
                            HStack {
                                Text(word)
                                Spacer()
                                Button(action: {
                                    store.remove(word)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            } header: {
                Text("รายการ Exclude (\(store.words.count) คำ)")
                    .font(.system(size: 13 * fontScale, weight: .semibold))
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Exclude คำ")
    }

    private func addWord() {
        duplicateMessage = nil
        let trimmed = newWord.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return }
        if store.contains(trimmed) {
            duplicateMessage = "คำนี้มีอยู่แล้วในรายการ"
            return
        }
        store.add(trimmed)
        newWord = ""
    }

    private func pasteAndAddWords() {
        duplicateMessage = nil
        guard let raw = NSPasteboard.general.string(forType: .string) else { return }
        let lines = raw.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty }
        var added = 0
        for line in lines {
            if !store.contains(line) {
                store.add(line)
                added += 1
            }
        }
        if added < lines.count && lines.count > 0 {
            duplicateMessage = "เพิ่ม \(added) คำ (ข้ามคำซ้ำ \(lines.count - added) คำ)"
        }
    }

    private func exportExcludeList() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "pimpid-exclude.txt"
        panel.message = "บันทึกรายการ exclude (บรรทัดละคำ)"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let text = Array(store.words).sorted().joined(separator: "\n")
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func importExcludeList() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.plainText]
        panel.begin { response in
            guard response == .OK, let url = panel.url,
                  let text = try? String(contentsOf: url, encoding: .utf8) else { return }
            let lines = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty }
            var added = 0
            for line in lines {
                if !store.contains(line) {
                    store.add(line)
                    added += 1
                }
            }
            duplicateMessage = "นำเข้า \(added) คำ"
        }
    }
}

#Preview {
    SettingsNavigationView()
        .environmentObject(AppState())
}

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
        case .general: return String(localized: "settings.general.title", bundle: .module)
        case .shortcut: return "Shortcut"
        case .autoCorrect: return "Auto-Correct"
        case .exclude: return String(localized: "settings.exclude.title", bundle: .module)
        case .appearance: return String(localized: "settings.appearance.title", bundle: .module)
        case .about: return String(localized: "settings.about.title", bundle: .module)
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
                Toggle(String(localized: "general.toggle", bundle: .module), isOn: $appState.isEnabled)
                    .toggleStyle(.switch)

                Text(String(localized: "general.description", bundle: .module))
                    .font(.system(size: 12 * fontScale))
                    .foregroundStyle(.secondary)
            } header: {
                Text(String(localized: "general.section.basic", bundle: .module))
                    .font(.system(size: 13 * fontScale, weight: .semibold))
            }

            Section {
                LabeledContent(String(localized: "general.version", bundle: .module), value: Bundle.main.appVersion)
                LabeledContent(String(localized: "general.status", bundle: .module), value: appState.isEnabled ? String(localized: "general.status.active", bundle: .module) : String(localized: "general.status.paused", bundle: .module))
            } header: {
                Text(String(localized: "section.info", bundle: .module))
                    .font(.system(size: 13 * fontScale, weight: .semibold))
            }

            Section {
                Button(String(localized: "button.use_defaults", bundle: .module)) {
                    appState.isEnabled = true
                }
                .buttonStyle(.bordered)
            } header: {
                Text(String(localized: "section.reset", bundle: .module))
                    .font(.system(size: 13 * fontScale, weight: .semibold))
            }
        }
        .formStyle(.grouped)
        .navigationTitle(String(localized: "general.nav_title", bundle: .module))
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
                LabeledContent(String(localized: "shortcut.current", bundle: .module), value: displayShortcut)
                    .font(.system(size: 13 * fontScale, weight: .medium))

                if let name = currentLayoutName {
                    LabeledContent("Keyboard layout", value: name)
                        .font(.system(size: 13 * fontScale, weight: .medium))
                }

                if InputSourceSwitcher.hasPreviousLayout {
                    Button(String(localized: "shortcut.switch_back", bundle: .module)) {
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
                Text(String(localized: "shortcut.footer", bundle: .module))
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
                    TextField(String(localized: "exclude.placeholder", bundle: .module), text: $newWord)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            addWord()
                        }

                    Button(String(localized: "button.add", bundle: .module)) {
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

                Text(String(localized: "exclude.hint", bundle: .module))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(String(localized: "exclude.section.add", bundle: .module))
                    .font(.headline)
            }

            Section {
                if !store.words.isEmpty {
                    TextField(String(localized: "exclude.search", bundle: .module), text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    Picker(String(localized: "exclude.sort", bundle: .module), selection: $sortAscending) {
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
                    Text(String(localized: "exclude.no_words", bundle: .module))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else if filteredWords.isEmpty {
                    Text(String(format: String(localized: "exclude.no_match", bundle: .module), searchText))
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
                Text(String(format: String(localized: "exclude.section.list", bundle: .module), store.words.count))
                    .font(.system(size: 13 * fontScale, weight: .semibold))
            }
        }
        .formStyle(.grouped)
        .navigationTitle(String(localized: "exclude.nav_title", bundle: .module))
    }

    private func addWord() {
        duplicateMessage = nil
        let trimmed = newWord.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return }
        if store.contains(trimmed) {
            duplicateMessage = String(localized: "exclude.duplicate", bundle: .module)
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
            duplicateMessage = String(format: String(localized: "exclude.paste_result", bundle: .module), added, lines.count - added)
        }
    }

    private func exportExcludeList() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "pimpid-exclude.txt"
        panel.message = String(localized: "exclude.export_message", bundle: .module)
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
            duplicateMessage = String(format: String(localized: "exclude.import_result", bundle: .module), added)
        }
    }
}

#Preview {
    SettingsNavigationView()
        .environmentObject(AppState())
}

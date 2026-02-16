import SwiftUI

/// Settings view with modern sidebar navigation
struct SettingsNavigationView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedSection: SettingsSection = .general

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                NavigationLink(value: section) {
                    Label {
                        Text(section.title)
                            .font(.system(size: 13, weight: .medium))
                    } icon: {
                        Image(systemName: section.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(section.color)
                    }
                }
            }
            .navigationTitle("PimPid")
            .frame(minWidth: 180)
        } detail: {
            // Detail view
            Group {
                switch selectedSection {
                case .general:
                    GeneralSettingsView()
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
            .frame(minWidth: 500, minHeight: 400)
        }
        .frame(width: 750, height: 550)
    }
}

// MARK: - SettingsSection

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case autoCorrect
    case exclude
    case appearance
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "ทั่วไป"
        case .autoCorrect: return "Auto-Correct"
        case .exclude: return "Exclude คำ"
        case .appearance: return "รูปลักษณ์"
        case .about: return "เกี่ยวกับ"
        }
    }

    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .autoCorrect: return "bolt.fill"
        case .exclude: return "minus.circle.fill"
        case .appearance: return "paintbrush.fill"
        case .about: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .general: return .blue
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

    var body: some View {
        Form {
            Section {
                Toggle("เปิดใช้งาน PimPid", isOn: $appState.isEnabled)
                    .toggleStyle(.switch)

                Text("เมื่อเปิดใช้งาน PimPid จะทำงานในเบื้องหลังและพร้อมแปลงข้อความ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("การทำงานพื้นฐาน")
                    .font(.headline)
            }

            Section {
                LabeledContent("เวอร์ชัน", value: Bundle.main.appVersion)
                LabeledContent("สถานะ", value: appState.isEnabled ? "✅ ใช้งาน" : "⏸️ หยุดชั่วคราว")
            } header: {
                Text("ข้อมูล")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("ทั่วไป")
    }
}

/// Exclude list settings section
struct ExcludeSettingsView: View {
    @StateObject private var store = ExcludeListStore.shared
    @State private var newWord = ""

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

                Text("ป้อนคำที่ไม่ต้องการให้ PimPid แปลง เช่น ชื่อ, แบรนด์, คำศัพท์เฉพาะ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("เพิ่มคำ")
                    .font(.headline)
            }

            Section {
                if store.words.isEmpty {
                    Text("ยังไม่มีคำที่ exclude")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                } else {
                    List {
                        ForEach(Array(store.words).sorted(), id: \.self) { word in
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
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Exclude คำ")
    }

    private func addWord() {
        let trimmed = newWord.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.add(trimmed)
        newWord = ""
    }
}

#Preview {
    SettingsNavigationView()
        .environmentObject(AppState())
}

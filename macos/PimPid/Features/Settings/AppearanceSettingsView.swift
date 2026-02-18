import SwiftUI

/// Appearance settings: theme, font size
struct AppearanceSettingsView: View {
    @EnvironmentObject var appState: AppState

    private var themeOptions: [(id: String, label: String)] {[
        ("auto", String(localized: "appearance.theme_auto", bundle: .module)),
        ("light", String(localized: "appearance.theme_light", bundle: .module)),
        ("dark", String(localized: "appearance.theme_dark", bundle: .module)),
    ]}
    private var fontSizeOptions: [(id: String, label: String)] {[
        ("small", String(localized: "appearance.font_small", bundle: .module)),
        ("medium", String(localized: "appearance.font_medium", bundle: .module)),
        ("large", String(localized: "appearance.font_large", bundle: .module)),
    ]}
    private var notificationStyleOptions: [(id: String, label: String)] {[
        ("toast", "Toast"),
        ("minimal", String(localized: "appearance.notify_minimal", bundle: .module)),
        ("off", String(localized: "appearance.notify_off", bundle: .module)),
    ]}
    private var toastDurationOptions: [(id: Double, label: String)] {[
        (1.5, String(format: String(localized: "appearance.toast_sec", bundle: .module), "1.5")),
        (2.0, String(format: String(localized: "appearance.toast_sec", bundle: .module), "2")),
        (3.0, String(format: String(localized: "appearance.toast_sec", bundle: .module), "3")),
    ]}
    var body: some View {
        Form {
            Section {
                Picker(String(localized: "appearance.theme_picker", bundle: .module), selection: $appState.appearanceTheme) {
                    ForEach(themeOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .pickerStyle(.menu)

                Text(String(localized: "appearance.theme_hint", bundle: .module))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(String(localized: "appearance.section.theme", bundle: .module))
                    .font(.headline)
            }

            Section {
                Picker(String(localized: "appearance.font_picker", bundle: .module), selection: $appState.appearanceFontSize) {
                    ForEach(fontSizeOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .pickerStyle(.menu)

                Text(String(localized: "appearance.font_hint", bundle: .module))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(String(localized: "appearance.section.font", bundle: .module))
                    .font(.headline)
            }

            Section {
                Picker(String(localized: "appearance.notify_picker", bundle: .module), selection: $appState.notificationStyle) {
                    ForEach(notificationStyleOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .pickerStyle(.menu)

                Text(String(localized: "appearance.notify_hint", bundle: .module))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(String(localized: "appearance.section.notify", bundle: .module))
                    .font(.headline)
            }

            Section {
                Button(String(localized: "button.use_defaults", bundle: .module)) {
                    appState.appearanceTheme = "auto"
                    appState.appearanceFontSize = "medium"
                    appState.notificationStyle = "toast"
                    UserDefaults.standard.set(2.0, forKey: PimPidKeys.toastDuration)
                }
                .buttonStyle(.bordered)
            } header: {
                Text(String(localized: "section.reset", bundle: .module))
                    .font(.headline)
            }

            Section {
                Picker(String(localized: "appearance.toast_picker", bundle: .module), selection: Binding(
                    get: {
                        let d = UserDefaults.standard.double(forKey: PimPidKeys.toastDuration)
                        return d > 0 ? d : 2.0
                    },
                    set: { UserDefaults.standard.set($0, forKey: PimPidKeys.toastDuration) }
                )) {
                    ForEach(toastDurationOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text(String(localized: "appearance.section.toast", bundle: .module))
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(String(localized: "appearance.nav_title", bundle: .module))
    }
}

#Preview {
    AppearanceSettingsView()
        .environmentObject(AppState())
}

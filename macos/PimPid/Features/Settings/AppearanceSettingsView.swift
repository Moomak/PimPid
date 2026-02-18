import SwiftUI

/// Appearance settings: theme, font size, language
struct AppearanceSettingsView: View {
    @EnvironmentObject var appState: AppState

    private var languageOptions: [(id: String, label: String)] {[
        ("th", String(localized: "appearance.language_thai", bundle: appState.localizedBundle)),
        ("en", String(localized: "appearance.language_english", bundle: appState.localizedBundle)),
        ("system", String(localized: "appearance.language_system", bundle: appState.localizedBundle)),
    ]}
    private var themeOptions: [(id: String, label: String)] {[
        ("auto", String(localized: "appearance.theme_auto", bundle: appState.localizedBundle)),
        ("light", String(localized: "appearance.theme_light", bundle: appState.localizedBundle)),
        ("dark", String(localized: "appearance.theme_dark", bundle: appState.localizedBundle)),
    ]}
    private var fontSizeOptions: [(id: String, label: String)] {[
        ("small", String(localized: "appearance.font_small", bundle: appState.localizedBundle)),
        ("medium", String(localized: "appearance.font_medium", bundle: appState.localizedBundle)),
        ("large", String(localized: "appearance.font_large", bundle: appState.localizedBundle)),
    ]}
    private var notificationStyleOptions: [(id: String, label: String)] {[
        ("toast", "Toast"),
        ("minimal", String(localized: "appearance.notify_minimal", bundle: appState.localizedBundle)),
        ("off", String(localized: "appearance.notify_off", bundle: appState.localizedBundle)),
    ]}
    private var toastDurationOptions: [(id: Double, label: String)] {[
        (1.5, String(format: String(localized: "appearance.toast_sec", bundle: appState.localizedBundle), "1.5")),
        (2.0, String(format: String(localized: "appearance.toast_sec", bundle: appState.localizedBundle), "2")),
        (3.0, String(format: String(localized: "appearance.toast_sec", bundle: appState.localizedBundle), "3")),
    ]}
    var body: some View {
        Form {
            Section {
                Picker(String(localized: "appearance.language_picker", bundle: appState.localizedBundle), selection: $appState.appLanguage) {
                    ForEach(languageOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text(String(localized: "appearance.section.language", bundle: appState.localizedBundle))
                    .font(.headline)
            }

            Section {
                Picker(String(localized: "appearance.theme_picker", bundle: appState.localizedBundle), selection: $appState.appearanceTheme) {
                    ForEach(themeOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .pickerStyle(.menu)

                Text(String(localized: "appearance.theme_hint", bundle: appState.localizedBundle))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(String(localized: "appearance.section.theme", bundle: appState.localizedBundle))
                    .font(.headline)
            }

            Section {
                Picker(String(localized: "appearance.font_picker", bundle: appState.localizedBundle), selection: $appState.appearanceFontSize) {
                    ForEach(fontSizeOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .pickerStyle(.menu)

                Text(String(localized: "appearance.font_hint", bundle: appState.localizedBundle))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(String(localized: "appearance.section.font", bundle: appState.localizedBundle))
                    .font(.headline)
            }

            Section {
                Picker(String(localized: "appearance.notify_picker", bundle: appState.localizedBundle), selection: $appState.notificationStyle) {
                    ForEach(notificationStyleOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .pickerStyle(.menu)

                Text(String(localized: "appearance.notify_hint", bundle: appState.localizedBundle))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text(String(localized: "appearance.section.notify", bundle: appState.localizedBundle))
                    .font(.headline)
            }

            Section {
                Button(String(localized: "button.use_defaults", bundle: appState.localizedBundle)) {
                    appState.appearanceTheme = "auto"
                    appState.appearanceFontSize = "medium"
                    appState.notificationStyle = "toast"
                    UserDefaults.standard.set(2.0, forKey: PimPidKeys.toastDuration)
                }
                .buttonStyle(.bordered)
            } header: {
                Text(String(localized: "section.reset", bundle: appState.localizedBundle))
                    .font(.headline)
            }

            Section {
                Picker(String(localized: "appearance.toast_picker", bundle: appState.localizedBundle), selection: Binding(
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
                Text(String(localized: "appearance.section.toast", bundle: appState.localizedBundle))
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(String(localized: "appearance.nav_title", bundle: appState.localizedBundle))
    }
}

#Preview {
    AppearanceSettingsView()
        .environmentObject(AppState())
}

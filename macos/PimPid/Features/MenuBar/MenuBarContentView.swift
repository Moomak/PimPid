import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openSettings) private var openSettings

    private var fontScale: CGFloat {
        switch appState.appearanceFontSize {
        case "small": return 0.9
        case "large": return 1.15
        default: return 1.0
        }
    }

    private var colorScheme: ColorScheme? {
        switch appState.appearanceTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        menuContent
        .preferredColorScheme(colorScheme)
    }

    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with gradient
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "character.bubble.fill")
                        .font(.system(size: 20 * fontScale, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("PimPid")
                        .font(.system(size: 16 * fontScale, weight: .bold))
                    Spacer()
                    Circle()
                        .fill(appState.isEnabled ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                }

                Text(String(localized: "app.tagline", bundle: appState.localizedBundle))
                    .font(.system(size: 11 * fontScale))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 4)

            Divider()

            // Quick toggles
            VStack(spacing: 10) {
                Toggle(isOn: $appState.isEnabled) {
                    HStack {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                            .foregroundColor(appState.isEnabled ? .green : .gray)
                        Text(String(localized: "toggle.enable", bundle: appState.localizedBundle))
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .toggleStyle(.switch)
                .accessibilityLabel(String(localized: "a11y.toggle_enable", bundle: appState.localizedBundle))
                .accessibilityHint(String(localized: "a11y.toggle_hint", bundle: appState.localizedBundle))

                Toggle(isOn: $appState.autoCorrectEnabled) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundColor(appState.autoCorrectEnabled ? .orange : .gray)
                        Text("Auto-Correct")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .toggleStyle(.switch)
                .disabled(!AccessibilityHelper.isAccessibilityTrusted)
                .accessibilityLabel(String(localized: "a11y.autocorrect_label", bundle: appState.localizedBundle))
                .accessibilityHint(String(localized: "a11y.autocorrect_hint", bundle: appState.localizedBundle))
            }

            // Accessibility warning
            if !AccessibilityHelper.isAccessibilityTrusted {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text(String(localized: "accessibility.warning", bundle: appState.localizedBundle))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.orange)
                    }

                    Button(String(localized: "accessibility.open_settings", bundle: appState.localizedBundle)) {
                        AccessibilityHelper.openAccessibilitySettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .font(.system(size: 11))
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }

            Divider()

            // Convert Selected Text
            Button(action: {
                TextReplacementService.convertSelectedText(
                    excludeStore: ExcludeListStore.shared,
                    enabled: appState.isEnabled,
                    direction: nil
                )
            }) {
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 12))
                    Text("Convert Selected Text")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text(KeyboardShortcutManager.shortcutDisplayString())
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
            .disabled(!appState.isEnabled)
            .accessibilityLabel("Convert Selected Text, \(KeyboardShortcutManager.shortcutDisplayString())")

            Divider()

            // Statistics
            ConversionStatsView()

            // Recent conversions
            RecentConversionsView()

            Divider()

            // Action buttons
            VStack(spacing: 8) {
                Button(action: { openSettings() }) {
                    HStack {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 12))
                        Text(String(localized: "menu.settings", bundle: appState.localizedBundle))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)

                Button(action: { NSApplication.shared.terminate(nil) }) {
                    HStack {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                        Text("Quit PimPid")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
            }
        }
        .padding(14)
        .frame(minWidth: menuWidth, maxWidth: menuWidth)
    }

    private var menuWidth: CGFloat {
        let base: CGFloat = 320
        switch appState.appearanceFontSize {
        case "small": return base * 0.95
        case "large": return base * 1.1
        default: return base
        }
    }
}
